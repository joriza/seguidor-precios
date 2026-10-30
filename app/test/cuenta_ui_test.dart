import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';
import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/sync/gestor_sync.dart';
import 'package:seguidor_precios/features/sync/red.dart';

import 'cliente_remoto_falso.dart';
import 'sync_arranque_test.dart';

/// S3 (R17/AD-003): entrada opcional de cuenta por email en Inicio. La
/// entrada nunca bloquea el uso offline: sin nube configurada no aparece y
/// el resto de la pantalla funciona igual; con error de red muestra un
/// mensaje en español y se puede cerrar.

/// S5 (v0.3.5): la app abre en la pestaña Escanear; los botones de Inicio
/// quedan offstage (IndexedStack) y los finders los omiten por defecto —
/// navegar a Inicio antes de buscar sus entradas.
Future<void> irAInicio(WidgetTester tester) async {
  await tester.tap(find.text('Inicio'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'con nube configurada, la entrada aparece y vincula con el código del '
      'email', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    cliente.uidCuentaEmail = 'uid-email-9';
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: configDePrueba,
      // Sin conectividad el arranque no muestra el aviso R15: el foco acá
      // es el flujo de cuenta, no el de sync.
      conexion: () async => TipoConexion.ninguna,
    );
    await crearUsuarioConEtiqueta(db, 'Nadia');

    await tester.pumpWidget(SeguidorPreciosApp(
      baseDeDatos: db,
      gestorSync: gestor,
    ));
    await tester.pumpAndSettle();
    await irAInicio(tester);

    // Entrada opcional visible en Inicio, aún sin cuenta vinculada.
    expect(find.byKey(const ValueKey('btn-cuenta')), findsOneWidget);
    expect(find.text('Cuenta por email'), findsOneWidget);

    // Flujo: email → enviar enlace → código → vincular.
    await tester.tap(find.byKey(const ValueKey('btn-cuenta')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dialogo-cuenta')), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('campo-email-cuenta')), 'Nadia@Example.COM');
    await tester.tap(find.byKey(const ValueKey('btn-enviar-enlace')));
    await tester.pumpAndSettle();

    // El enlace se pidió una sola vez con el email normalizado.
    expect(cliente.enlacesPedidos, ['nadia@example.com']);

    await tester.enterText(
        find.byKey(const ValueKey('campo-codigo-cuenta')), '123456');
    await tester.tap(find.byKey(const ValueKey('btn-vincular-cuenta')));
    await tester.pumpAndSettle();

    // Confirmación en español y diálogo cerrado.
    expect(find.textContaining('Cuenta vinculada'), findsOneWidget);
    expect(find.byKey(const ValueKey('dialogo-cuenta')), findsNothing);

    // La identidad local quedó vinculada a la cuenta, sin duplicarse.
    final usuario = await leerUsuario(db);
    expect(usuario!.authUid, 'uid-email-9');
    expect(cliente.codigosVerificados, hasLength(1));
  });

  testWidgets(
      'sin nube configurada la entrada no aparece y la pantalla funciona '
      'igual', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: ClienteRemotoFalso(),
      config: sinConfigurar,
      conexion: () async => TipoConexion.ninguna,
    );
    await crearUsuarioConEtiqueta(db, 'Nadia');

    await tester.pumpWidget(SeguidorPreciosApp(
      baseDeDatos: db,
      gestorSync: gestor,
    ));
    await tester.pumpAndSettle();
    await irAInicio(tester);

    // La cuenta es opcional (R17): sin nube no hay entrada, pero el resto
    // de la pantalla está intacto (la app nunca se bloquea).
    expect(find.byKey(const ValueKey('btn-cuenta')), findsNothing);
    expect(find.byKey(const ValueKey('btn-etiqueta')), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-exportar-json')), findsOneWidget);
  });

  testWidgets(
      'con error de red, el diálogo muestra el mensaje en español y se '
      'puede cerrar sin bloquear la app', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    cliente.errorAlPedirEnlace = const SocketException('red caída');
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: configDePrueba,
      // Sin conectividad el arranque no muestra el aviso R15: el foco acá
      // es el mensaje de error de la cuenta, no el de sync.
      conexion: () async => TipoConexion.ninguna,
    );
    await crearUsuarioConEtiqueta(db, 'Nadia');

    await tester.pumpWidget(SeguidorPreciosApp(
      baseDeDatos: db,
      gestorSync: gestor,
    ));
    await tester.pumpAndSettle();
    await irAInicio(tester);

    await tester.tap(find.byKey(const ValueKey('btn-cuenta')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('campo-email-cuenta')), 'nadia@example.com');
    await tester.tap(find.byKey(const ValueKey('btn-enviar-enlace')));
    await tester.pumpAndSettle();

    // Mensaje humano en español, dentro del diálogo.
    expect(find.byKey(const ValueKey('error-cuenta')), findsOneWidget);
    expect(find.textContaining('Sin conexión'), findsOneWidget);

    // Cancelar cierra el diálogo y la app sigue usable.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dialogo-cuenta')), findsNothing);
    expect(find.byKey(const ValueKey('btn-etiqueta')), findsOneWidget);
  });
}
