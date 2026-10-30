import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seguidor_precios/data/enriquecimiento.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/escaner/escaner_screen.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';

/// T5 (S3): flujo del escáner con enriquecimiento OFF — precarga en el
/// formulario para confirmación del usuario; NUNCA guarda solo. Sin red:
/// servicios falsos o cliente http mockeado.
/// Servicio falso que cuenta consultas y devuelve datos fijos.
class ServicioFalso implements ServicioEnriquecimiento {
  ServicioFalso(this.datos);

  final DatosEnriquecidos? datos;
  int consultas = 0;

  @override
  Future<DatosEnriquecidos?> consultar(String ean) async {
    consultas++;
    return datos;
  }
}

/// Servicio falso que simula un timeout de OFF.
class ServicioQueLanza implements ServicioEnriquecimiento {
  @override
  Future<DatosEnriquecidos?> consultar(String ean) async {
    throw TimeoutException('OFF no responde');
  }
}

void main() {
  const String eanDesconocido = '7790001001999';

  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Widget envolver(EscanerScreen pantalla) => MaterialApp(
        home: Scaffold(body: pantalla),
      );

  DatosEnriquecidos datosDulce() => const DatosEnriquecidos(
        nombre: 'Dulce de leche',
        marca: 'La Salteña',
        contenidoNeto: 500,
        unidad: 'g',
      );

  /// Servicio OFF real con cliente http mockeado y conectividad fija.
  ServicioEnriquecimientoOFF servicioReal({
    required bool hayConexion,
    required int statusCode,
    required String cuerpo,
  }) {
    final http.Client cliente = MockClient((http.Request request) async {
      return http.Response(cuerpo, statusCode);
    });
    return ServicioEnriquecimientoOFF(
      cliente: cliente,
      hayConexion: () async => hayConexion,
    );
  }

  String cuerpoDulce() =>
      '{"status": 1, "code": "$eanDesconocido", "product": {'
      '"product_name": "Dulce de leche", "brands": "La Salteña", '
      '"quantity": "500 g"}}';

  Future<int> cantidadProductos() async {
    final filas = await db.select(db.productos).get();
    return filas.length;
  }

  Future<void> buscarEan(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), eanDesconocido);
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();
  }

  // S3 (v0.3.5): los códigos internos S-* (productos sin EAN) NUNCA
  // consultan Open Food Facts, ni con el servicio disponible.
  testWidgets('S3 v0.3.5: código interno S-* no consulta enriquecimiento',
      (tester) async {
    final ServicioFalso servicio = ServicioFalso(datosDulce());
    await tester.pumpWidget(envolver(
      EscanerScreen(
        baseDeDatos: db,
        mostrarCamara: false,
        enriquecimiento: servicio,
      ),
    ));

    await tester.enterText(find.byType(TextField), 'S-QT-0001');
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No existe'), findsOneWidget);
    expect(servicio.consultas, 0);
    expect(find.textContaining('Open Food Facts'), findsNothing);
  });

  testWidgets(
      'S3: precarga nombre/marca/contenido en el formulario y nunca guarda sin confirmación',
      (tester) async {
    // El formulario es más alto que el surface: igual que escaner_test.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ServicioFalso servicio = ServicioFalso(datosDulce());
    await tester.pumpWidget(envolver(
      EscanerScreen(
        baseDeDatos: db,
        mostrarCamara: false,
        enriquecimiento: servicio,
      ),
    ));

    await buscarEan(tester);

    // Aviso de la precarga disponible en el escáner.
    expect(find.textContaining('Open Food Facts'), findsOneWidget);
    // NUNCA guarda solo: la tabla sigue vacía tras la precarga.
    expect(await cantidadProductos(), 0);

    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    // El formulario llega precargado para CONFIRMACIÓN del usuario.
    expect(find.byType(ProductoFormScreen), findsOneWidget);
    expect(find.text('Dulce de leche'), findsOneWidget);
    expect(find.text('La Salteña'), findsOneWidget);
    expect(find.text('500.0'), findsOneWidget);
    expect(find.textContaining('Open Food Facts'), findsWidgets);
    final DropdownButtonFormField<String> unidad =
        tester.widget(find.byType(DropdownButtonFormField<String>).first);
    expect(unidad.initialValue, 'g');
    expect(await cantidadProductos(), 0); // sigue sin guardar solo

    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    // Recién el guardado del usuario crea la fila.
    expect(find.byType(ProductoFormScreen), findsNothing);
    final filas = await db.select(db.productos).get();
    expect(filas, hasLength(1));
    expect(filas.single.nombre, 'Dulce de leche');
    expect(filas.single.marca, 'La Salteña');
    expect(filas.single.contenidoNeto, 500);
    expect(filas.single.unidad, 'g');
    expect(filas.single.codigoBarras, eanDesconocido);
  });

  testWidgets('S3: sin resultado en OFF deja el formulario vacío como hoy',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ServicioFalso servicio = ServicioFalso(null);
    await tester.pumpWidget(envolver(
      EscanerScreen(
        baseDeDatos: db,
        mostrarCamara: false,
        enriquecimiento: servicio,
      ),
    ));

    await buscarEan(tester);

    expect(servicio.consultas, 1); // consultó…
    expect(find.textContaining('Open Food Facts'), findsNothing); // …sin datos
    expect(await cantidadProductos(), 0);

    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    // Formulario vacío (solo el código, como hoy).
    expect(find.byType(ProductoFormScreen), findsOneWidget);
    expect(find.text('Dulce de leche'), findsNothing);
    expect(find.text(eanDesconocido), findsOneWidget);
    expect(await cantidadProductos(), 0);
  });

  testWidgets('S3: timeout de OFF deja el formulario vacío (no rompe el flujo)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envolver(
      EscanerScreen(
        baseDeDatos: db,
        mostrarCamara: false,
        enriquecimiento: ServicioQueLanza(),
      ),
    ));

    await buscarEan(tester);

    expect(find.textContaining('Open Food Facts'), findsNothing);
    expect(find.textContaining('No existe un producto con ese código'),
        findsOneWidget);

    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductoFormScreen), findsOneWidget);
    expect(find.text('Dulce de leche'), findsNothing);
    expect(await cantidadProductos(), 0);
  });

  testWidgets(
      'S3: sin conectividad (heurística de red.dart) no consulta y deja el formulario vacío',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envolver(
      EscanerScreen(
        baseDeDatos: db,
        mostrarCamara: false,
        enriquecimiento: servicioReal(
          hayConexion: false,
          statusCode: 200,
          cuerpo: cuerpoDulce(),
        ),
      ),
    ));

    await buscarEan(tester);

    // Con el gate de conectividad en false no hay precarga (y el mock
    // asegura que ningún request salió del dispositivo en el examen).
    expect(find.textContaining('Open Food Facts'), findsNothing);
    expect(find.textContaining('No existe un producto con ese código'),
        findsOneWidget);

    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    expect(find.text('Dulce de leche'), findsNothing);
    expect(await cantidadProductos(), 0);
  });

  testWidgets(
      'S3: con conectividad el servicio real precarga extremo a extremo (sin red real)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envolver(
      EscanerScreen(
        baseDeDatos: db,
        mostrarCamara: false,
        enriquecimiento: servicioReal(
          hayConexion: true,
          statusCode: 200,
          cuerpo: cuerpoDulce(),
        ),
      ),
    ));

    await buscarEan(tester);

    expect(find.textContaining('Open Food Facts'), findsOneWidget);

    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    expect(find.text('Dulce de leche'), findsOneWidget);
    expect(find.text('La Salteña'), findsOneWidget);
    expect(find.text('500.0'), findsOneWidget);
  });

  testWidgets('S3: la búsqueda de producto existente no consulta OFF',
      (tester) async {
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p1',
            codigoBarras: const Value('7790001001001'),
            nombre: 'Mayonesa Marca A',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );

    final ServicioFalso servicio = ServicioFalso(datosDulce());
    await tester.pumpWidget(envolver(
      EscanerScreen(
        baseDeDatos: db,
        mostrarCamara: false,
        enriquecimiento: servicio,
      ),
    ));

    await tester.enterText(find.byType(TextField), '7790001001001');
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Producto encontrado: Mayonesa Marca A'),
        findsOneWidget);
    expect(servicio.consultas, 0);
    expect(find.textContaining('Open Food Facts'), findsNothing);
  });
}
