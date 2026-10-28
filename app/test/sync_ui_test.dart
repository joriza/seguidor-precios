import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';
import 'package:seguidor_precios/data/articulos.dart';
import 'package:seguidor_precios/data/comercios.dart';
import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/productos.dart';
import 'package:seguidor_precios/data/sync/cola_saliente.dart';
import 'package:seguidor_precios/features/comercios/comercios_screen.dart';
import 'package:seguidor_precios/features/sync/gestor_sync.dart';
import 'package:seguidor_precios/features/sync/red.dart';

import 'cliente_remoto_falso.dart';
import 'sync_arranque_test.dart';

/// UX de red de T4: aviso R15 al iniciar, indicador de estado con sync
/// manual y pull-to-refresh. Todo con cliente falso, sin red.
void main() {
  testWidgets(
      'R15: con WiFi y cambios pendientes, al iniciar pregunta y sincroniza '
      'si el usuario confirma', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: configDePrueba,
      conexion: () async => TipoConexion.wifi,
    );

    // Usuario ya creado (sin diálogo de etiqueta) + un alta pendiente.
    await crearUsuarioConEtiqueta(db, 'Vale');
    await altaProducto(db, nombre: 'Dulce de leche', unidad: 'g');
    expect(await cambiosPendientes(db), 2); // usuario + producto

    await tester.pumpWidget(SeguidorPreciosApp(
      baseDeDatos: db,
      gestorSync: gestor,
    ));
    await tester.pumpAndSettle();

    // El aviso aparece y espera confirmación: nada se sincronizó aún.
    expect(find.byKey(const ValueKey('dialogo-aviso-sync')), findsOneWidget);
    expect(find.text('¿Sincronizar con la nube?'), findsOneWidget);
    expect((cliente.remoto['producto'] ?? const []), isEmpty);

    await tester.tap(find.byKey(const ValueKey('btn-sync-ahora')));
    await tester.pump(); // cierra el diálogo y arranca la sync
    await tester.pump(const Duration(milliseconds: 300));

    // El snackbar se ve antes de que se auto-descarte.
    expect(find.textContaining('Sincronización completa'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dialogo-aviso-sync')), findsNothing);
    expect(await cambiosPendientes(db), 0);
    expect((cliente.remoto['producto'] ?? const []), isNotEmpty);
    expect(await ultimoSyncExitoso(db), isNotNull);
  });

  testWidgets('R15: "Más tarde" no sincroniza nada', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: configDePrueba,
      conexion: () async => TipoConexion.wifi,
    );

    await crearUsuarioConEtiqueta(db, 'Vale');
    await altaProducto(db, nombre: 'Dulce de leche', unidad: 'g');

    await tester.pumpWidget(SeguidorPreciosApp(
      baseDeDatos: db,
      gestorSync: gestor,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('btn-sync-mas-tarde')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dialogo-aviso-sync')), findsNothing);
    expect(await cambiosPendientes(db), 2);
    expect(await ultimoSyncExitoso(db), isNull);
    expect((cliente.remoto['producto'] ?? const []), isEmpty);
  });

  testWidgets(
      'R15: con WiFi, sin pendientes y sin sync previa, el arranque no '
      'muestra ningún aviso', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: ClienteRemotoFalso(),
      config: configDePrueba,
      conexion: () async => TipoConexion.wifi,
    );

    // Usuario ya creado; se limpia su entrada del outbox para simular que
    // la instalación ya sincronizó y hoy no hay cambios pendientes.
    await crearUsuarioConEtiqueta(db, 'Vale');
    await db.delete(db.outbox).go();
    expect(await cambiosPendientes(db), 0);

    await tester.pumpWidget(SeguidorPreciosApp(
      baseDeDatos: db,
      gestorSync: gestor,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dialogo-aviso-sync')), findsNothing);
    // Indicador: todo al día.
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
  });

  testWidgets(
      'indicador de sync: muestra los pendientes y sincroniza desde su '
      'diálogo', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: configDePrueba,
      conexion: () async => TipoConexion.wifi,
    );

    await crearUsuarioConEtiqueta(db, 'Vale');
    await altaProducto(db, nombre: 'Fideos', unidad: 'g');

    await tester.pumpWidget(SeguidorPreciosApp(
      baseDeDatos: db,
      gestorSync: gestor,
    ));
    await tester.pumpAndSettle();

    // Primero aparece el aviso R15 (hay pendientes y WiFi): se pospone.
    await tester.tap(find.byKey(const ValueKey('btn-sync-mas-tarde')));
    await tester.pumpAndSettle();

    // Con outbox pendiente el ícono lo muestra.
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('indicador-sync')));
    await tester.pumpAndSettle();
    expect(find.text('Cambios pendientes de subir: 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('btn-sync-dialogo')));
    await tester.pumpAndSettle();

    expect(await cambiosPendientes(db), 0);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
  });

  testWidgets('indicador de sync: sin backend configurado ofrece solo local',
      (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);

    // Sin gestor: la app crea el suyo con la configuración real (placeholders)
    // y la app se usa igual (R3).
    await crearUsuarioConEtiqueta(db, 'Vale');

    await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('indicador-sync')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin nube configurada'), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-sync-dialogo')), findsNothing);
  });

  testWidgets('pull-to-refresh en Comercios sincroniza el outbox',
      (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: configDePrueba,
      conexion: () async => TipoConexion.wifi,
    );

    await crearUsuarioConEtiqueta(db, 'Vale');
    await altaComercio(db, nombre: 'El Almacén de Vale');
    expect((cliente.remoto['comercio'] ?? const []), isEmpty);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ComerciosScreen(baseDeDatos: db, gestorSync: gestor)),
    ));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1200);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect((cliente.remoto['comercio'] ?? const []), isNotEmpty);
  });

  testWidgets('el artículo creado desde la UI viaja en la próxima sync',
      (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: configDePrueba,
      conexion: () async => TipoConexion.wifi,
    );

    await crearUsuarioConEtiqueta(db, 'Vale');
    await altaArticulo(db, nombre: 'Lácteos', unidadBase: 'L');
    expect(await cambiosPendientes(db), 2); // usuario + artículo

    await gestor.sincronizar();

    expect(
      (cliente.remoto['articulo'] ?? const []).map((f) => f['nombre']),
      contains('Lácteos'),
    );
  });
}
