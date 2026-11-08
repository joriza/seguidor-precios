import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/enriquecimiento.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/escaner/escaner_screen.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';

/// v0.3.11 (backlog #3): botón «Completar desde OFF» en la ficha de
/// producto en modo EDICIÓN. S1: visible sólo en edición con código no
/// interno `S-*`; S2: completa SOLO los campos vacíos y NUNCA guarda solo;
/// S3: servicio de enriquecimiento inyectable (el escáner pasa el suyo al
/// abrir «Editar datos»); S4: el flujo de guardar queda idéntico. Sin red
/// real: fakes del puerto [ServicioEnriquecimiento].

/// Servicio falso que cuenta consultas y devuelve datos fijos (null =
/// «no está en OFF», el caso más frecuente en pruebas).
class ServicioFalso implements ServicioEnriquecimiento {
  ServicioFalso(this.datos);

  final DatosEnriquecidos? datos;
  int consultas = 0;

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async {
    consultas++;
    return datos == null
        ? const ResultadoNoEncontrado()
        : ResultadoDatos(datos!);
  }
}

/// Servicio falso que deja la consulta pendiente (estado de carga).
class ServicioDeCola implements ServicioEnriquecimiento {
  int consultas = 0;
  final Completer<DatosEnriquecidos?> completer =
      Completer<DatosEnriquecidos?>();

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async {
    consultas++;
    final DatosEnriquecidos? datos = await completer.future;
    return datos == null
        ? const ResultadoNoEncontrado()
        : ResultadoDatos(datos);
  }
}

/// Servicio falso que devuelve un resultado fijo del puerto (v0.3.15 T3:
/// el formulario distingue errorServidor de errorConectividad).
class ServicioFalsoDeResultado implements ServicioEnriquecimiento {
  ServicioFalsoDeResultado(this.resultado);

  final ResultadoEnriquecimiento resultado;
  int consultas = 0;

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async {
    consultas++;
    return resultado;
  }
}

/// Servicio falso que simula OFF caído / timeout.
class ServicioQueLanza implements ServicioEnriquecimiento {
  int consultas = 0;

  @override
  Future<ResultadoEnriquecimiento> consultarConResultado(String ean) async {
    consultas++;
    throw TimeoutException('OFF no responde');
  }
}

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  // El formulario es más alto que el surface por defecto (800x600): igual
  // que producto_form_test, ampliamos para que el botón sea alcanzable.
  void superficieGrande(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget envolver(Widget pantalla) => MaterialApp(
        key: UniqueKey(),
        home: Scaffold(body: pantalla),
      );

  Future<Producto> insertarProducto({
    required String id,
    String? codigoBarras,
    String nombre = 'Precargado',
    String? marca,
    double? contenidoNeto,
    String unidad = 'unidad',
    String? categoria,
    int pack = 1,
  }) {
    return db.into(db.productos).insertReturning(
          ProductosCompanion.insert(
            id: id,
            codigoBarras: Value(codigoBarras),
            nombre: nombre,
            marca: Value(marca),
            unidad: unidad,
            contenidoNeto: Value(contenidoNeto),
            categoria: Value(categoria),
            pack: Value(pack),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  Future<Producto> productoGuardado(String id) =>
      (db.select(db.productos)..where((t) => t.id.equals(id))).getSingle();

  Future<int> cantidadProductos() async =>
      (await db.select(db.productos).get()).length;

  DatosEnriquecidos datosOFF({
    String nombre = 'Nombre OFF',
    String? marca = 'Marca OFF',
    double? contenidoNeto = 400,
    String? unidad = 'g',
    String? categorias = 'Snacks, Dulces',
    int? pack,
  }) =>
      DatosEnriquecidos(
        nombre: nombre,
        marca: marca,
        contenidoNeto: contenidoNeto,
        unidad: unidad,
        categorias: categorias,
        pack: pack,
      );

  Finder botonOFF() => find.byKey(const ValueKey('btn-completar-off'));

  testWidgets('S1: edición con EAN muestra el botón Completar desde OFF',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(null),
    )));

    expect(botonOFF(), findsOneWidget);
    expect(find.text('Completar desde OFF'), findsOneWidget);
  });

  testWidgets('S1: el alta nunca muestra el botón (ni con código precargado)',
      (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      codigoBarrasInicial: '7790001001001',
      enriquecimiento: ServicioFalso(null),
    )));
    expect(botonOFF(), findsNothing);

    // Alta sin código: tampoco.
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      enriquecimiento: ServicioFalso(null),
    )));
    expect(botonOFF(), findsNothing);
  });

  testWidgets('S1/S4: edición con código interno S-* no muestra el botón',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: 'S-QT-0001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF()),
    )));

    expect(botonOFF(), findsNothing);
  });

  testWidgets(
      'S1: edición con código vacío no muestra el botón; al tipear un EAN aparece',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: null);
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(null),
    )));

    expect(botonOFF(), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('campo-codigo')),
      '7790001001001',
    );
    await tester.pumpAndSettle();

    expect(botonOFF(), findsOneWidget);
  });

  testWidgets(
      'S2: completa SOLO los vacíos — nombre vacío se completa, contenido '
      'vacío se completa, marca y categoría vacías se completan, unidad '
      'aceptada se aplica al dropdown', (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF()),
    )));

    // El nombre viene cargado del producto; lo vacío el usuario para
    // probar «nombre vacío se completa».
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      '',
    );
    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(find.text('Nombre OFF'), findsOneWidget);
    expect(find.text('Marca OFF'), findsOneWidget);
    expect(find.text('400.0'), findsOneWidget);
    expect(find.text('Snacks, Dulces'), findsOneWidget);
    // Unidad aceptada de OFF, aplicada al dropdown (visual y estado).
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'g'),
      findsOneWidget,
    );
  });

  testWidgets(
      'S2: nunca pisa datos cargados — nombre, marca, contenido, unidad '
      'no-default, categoría y pack quedan intactos', (tester) async {
    superficieGrande(tester);
    await insertarProducto(
      id: 'p1',
      codigoBarras: '7790001001001',
      nombre: 'Fideos guisados',
      marca: 'Marca propia',
      contenidoNeto: 250,
      unidad: 'kg',
      categoria: 'Fideos',
    );
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF()),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(find.text('Nombre OFF'), findsNothing);
    expect(find.text('Fideos guisados'), findsOneWidget);
    expect(find.text('Marca OFF'), findsNothing);
    expect(find.text('Marca propia'), findsOneWidget);
    expect(find.text('250.0'), findsOneWidget);
    expect(find.text('400.0'), findsNothing);
    expect(find.text('Fideos'), findsOneWidget); // categoría intacta
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'kg'),
      findsOneWidget,
    );
    // El pack jamás se toca (OFF no informa pack).
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
      'S2: unidad de OFF no aceptada (no es unidad de venta) no se aplica',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF(unidad: 'parcela')),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'unidad'),
      findsOneWidget,
    );
  });

  testWidgets(
      'S2: nunca guarda solo — la base no cambia con el tap; recién '
      '«Guardar cambios» persiste lo completado', (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF()),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    // El tap NO escribe: la fila sigue como estaba.
    expect(await cantidadProductos(), 1);
    final filaSinGuardar = await productoGuardado('p1');
    expect(filaSinGuardar.marca, isNull);
    expect(filaSinGuardar.contenidoNeto, isNull);
    expect(filaSinGuardar.categoria, isNull);
    expect(filaSinGuardar.unidad, 'unidad');

    // El usuario confirma: recién ahí se persiste lo completado.
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final fila = await productoGuardado('p1');
    expect(fila.nombre, 'Precargado');
    expect(fila.marca, 'Marca OFF');
    expect(fila.contenidoNeto, 400);
    expect(fila.unidad, 'g');
    expect(fila.categoria, 'Snacks, Dulces');
    expect(fila.pack, 1);
  });

  testWidgets(
      'S2: sin datos en OFF muestra mensaje en español y deja reintentar',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    final ServicioFalso servicio = ServicioFalso(null);
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: servicio,
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(
      find.text('Open Food Facts no trajo datos para este código.'),
      findsOneWidget,
    );
    expect(await cantidadProductos(), 1);
    final fila = await productoGuardado('p1');
    expect(fila.marca, isNull);

    // El botón queda disponible para reintentar.
    await tester.tap(botonOFF());
    await tester.pumpAndSettle();
    expect(servicio.consultas, 2);
  });

  testWidgets(
      'S2: error de OFF (sin conexión) muestra mensaje sin bloquear el formulario',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioQueLanza(),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión: no se pudo consultar Open Food Facts.'),
      findsOneWidget,
    );
    // Sin bloqueo: el resto del formulario (y Guardar) sigue disponible.
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(await cantidadProductos(), 1);
  });

  // v0.3.15 (T1/S7): el pack de OFF (multipack) precarga el campo sólo
  // si está en su default 1 — regla fill-only-empty v0.3.11 intacta.
  testWidgets(
      'S7: pack de OFF (multipack) precarga el campo cuando está en el '
      'default 1', (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF(pack: 6)),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget);
  });

  testWidgets(
      'S7: pack de OFF no pisa un pack ya cargado (campo ≠ default 1)',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001', pack: 3);
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF(pack: 6)),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('6'), findsNothing);
  });

  testWidgets(
      'S7: alta con datosIniciales de multipack precarga el pack (el campo '
      'arranca en su default 1)', (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      codigoBarrasInicial: '7790001001999',
      datosIniciales: datosOFF(pack: 2),
      enriquecimiento: ServicioFalso(null),
    )));

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets(
      'S7: alta sin pack en OFF deja el campo en el default 1',
      (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      codigoBarrasInicial: '7790001001999',
      datosIniciales: datosOFF(), // sin pack
      enriquecimiento: ServicioFalso(null),
    )));

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
      'S7: el pack precargado desde OFF persiste sólo al guardar (nada '
      'guarda solo)', (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: ServicioFalso(datosOFF(pack: 6)),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    // El tap NO escribe: la fila conserva pack 1.
    expect((await productoGuardado('p1')).pack, 1);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect((await productoGuardado('p1')).pack, 6);
  });

  // v0.3.15 (T3/S6): el error de servidor de OFF se distingue de la falta
  // de conexión en el formulario.
  testWidgets(
      'S6: errorServidor muestra «Open Food no respondió. Reintentá más '
      'tarde.» sin bloquear el formulario', (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento:
          ServicioFalsoDeResultado(const ResultadoErrorServidor()),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(
      find.text('Open Food no respondió. Reintentá más tarde.'),
      findsOneWidget,
    );
    expect(
      find.text('Sin conexión: no se pudo consultar Open Food Facts.'),
      findsNothing,
    );
    // Sin bloqueo: el resto del formulario (y Guardar) sigue disponible.
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(await cantidadProductos(), 1);
  });

  testWidgets(
      'S6: errorConectividad mantiene «Sin conexión: no se pudo consultar '
      'Open Food Facts.»', (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento:
          ServicioFalsoDeResultado(const ResultadoErrorConectividad()),
    )));

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión: no se pudo consultar Open Food Facts.'),
      findsOneWidget,
    );
    expect(
      find.text('Open Food no respondió. Reintentá más tarde.'),
      findsNothing,
    );
  });

  testWidgets(
      'S2: durante la consulta el botón se deshabilita («Consultando Open '
      'Food Facts…»), no repite el llamado y al terminar restaura el botón',
      (tester) async {
    superficieGrande(tester);
    await insertarProducto(id: 'p1', codigoBarras: '7790001001001');
    final producto = await productoGuardado('p1');
    final ServicioDeCola servicio = ServicioDeCola();
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
      enriquecimiento: servicio,
    )));

    await tester.tap(botonOFF());
    await tester.pump();

    expect(find.text('Consultando Open Food Facts…'), findsOneWidget);

    // Deshabilitado: un segundo tap no dispara otra consulta.
    await tester.tap(botonOFF(), warnIfMissed: false);
    await tester.pump();
    expect(servicio.consultas, 1);

    servicio.completer.complete(datosOFF());
    await tester.pumpAndSettle();

    expect(find.text('Consultando Open Food Facts…'), findsNothing);
    expect(find.text('Marca OFF'), findsOneWidget);
    expect(find.text('Completar desde OFF'), findsOneWidget);
  });

  testWidgets(
      'S3: el escáner pasa SU servicio al abrir «Editar datos» — el mismo '
      'fake consulta y completa', (tester) async {
    superficieGrande(tester);
    await insertarProducto(
      id: 'p1',
      codigoBarras: '7790001001001',
      nombre: 'Fideos flojos',
    );
    final ServicioFalso servicio = ServicioFalso(datosOFF());
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

    await tester.tap(find.text('Editar datos'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductoFormScreen), findsOneWidget);
    expect(botonOFF(), findsOneWidget);

    await tester.tap(botonOFF());
    await tester.pumpAndSettle();

    // El servicio del escáner fue el que consultó.
    expect(servicio.consultas, 1);
    expect(find.text('Marca OFF'), findsOneWidget);
    // Y nunca guarda solo.
    expect(await cantidadProductos(), 1);
  });
}
