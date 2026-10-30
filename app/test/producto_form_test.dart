import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  // El formulario es más alto que el surface por defecto (800x600):
  // ampliamos la superficie para que todos los campos y el botón sean
  // alcanzables por tap().
  void superficieGrande(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget envolver(ProductoFormScreen pantalla) => MaterialApp(
        // Clave única: cada pumpWidget construye un Navigator nuevo (la
        // segunda alta del test de secuencial re-usa el tester tras el pop).
        key: UniqueKey(),
        home: Scaffold(body: pantalla),
      );

  Future<void> insertarProductoExistente() {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p1',
            codigoBarras: const Value('7790001001001'),
            nombre: 'Ya existe',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  testWidgets('alta: guarda producto y genera id uuid', (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(baseDeDatos: db)));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Mayonesa Marca A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de barras (opcional)'),
      '7790001001001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contenido neto (opcional)'),
      '500',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final filas = await db.select(db.productos).get();
    expect(filas, hasLength(1));
    expect(filas.single.nombre, 'Mayonesa Marca A');
    expect(filas.single.codigoBarras, '7790001001001');
    expect(filas.single.contenidoNeto, 500);
    expect(filas.single.unidad, 'unidad');
    expect(filas.single.id, hasLength(36));
  });

  Future<void> insertarProductoConCodigo(String? codigo) {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p-seed',
            codigoBarras: Value(codigo),
            nombre: 'Precargado',
            unidad: 'g',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  // S1 (v0.3.5, diseño v2): alta sin EAN — el formulario asigna el próximo
  // código interno S-<TOK>-<NNNN> de esta instalación y lo entrega al
  // llamador para que sea visible (S6: semántica genérica, "código interno").
  testWidgets('alta sin código: asigna el próximo código interno S-QT-0001',
      (tester) async {
    superficieGrande(tester);
    Producto? entregado;
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      tokInterno: () async => 'QT',
      alGuardar: (Producto p) => entregado = p,
    )));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Tomate',
    );
    // El código se deja vacío: vacío = código interno asignado.
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final filas = await db.select(db.productos).get();
    expect(filas, hasLength(1));
    expect(filas.single.nombre, 'Tomate');
    expect(filas.single.codigoBarras, 'S-QT-0001');
    // El código asignado viaja con el producto guardado (ficha/búsqueda).
    expect(entregado?.codigoBarras, 'S-QT-0001');
  });

  testWidgets('segunda alta sin código: asigna S-QT-0002', (tester) async {
    superficieGrande(tester);
    Future<String> tokDePrueba() async => 'QT';
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      tokInterno: tokDePrueba,
    )));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Lechuga',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      tokInterno: tokDePrueba,
    )));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Cebolla',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final codigos = (await db.select(db.productos).get())
        .map((Producto p) => p.codigoBarras)
        .toSet();
    expect(codigos, <String>{'S-QT-0001', 'S-QT-0002'});
  });

  // Guardia S3 (v0.3.5): el flujo CON EAN real no cambia — el EAN escrito
  // queda intacto, sin código interno, aunque ya existan códigos S-*.
  testWidgets('alta con EAN escrito a mano: el EAN queda intacto',
      (tester) async {
    superficieGrande(tester);
    await insertarProductoConCodigo('S-QT-0001');
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      tokInterno: () async => 'QT',
    )));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de barras (opcional)'),
      '7790001001001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Arroz Gallo',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final filas = await db.select(db.productos).get();
    expect(filas, hasLength(2));
    final nuevo = filas.firstWhere((Producto p) => p.nombre == 'Arroz Gallo');
    expect(nuevo.codigoBarras, '7790001001001');
  });

  // Guardia: la edición mantiene su contrato de siempre con el código.
  testWidgets('edición: el código existente se mantiene al guardar',
      (tester) async {
    superficieGrande(tester);
    await insertarProductoExistente();
    final producto = await (db.select(db.productos)
          ..where((t) => t.id.equals('p1')))
        .getSingle();
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
    )));

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final fila = await (db.select(db.productos)
          ..where((t) => t.id.equals('p1')))
        .getSingle();
    expect(fila.codigoBarras, '7790001001001');
  });

  testWidgets('alta: exige nombre y no inserta si falta', (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(baseDeDatos: db)));

    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá el nombre'), findsOneWidget);
    expect(await db.select(db.productos).get(), isEmpty);
  });

  testWidgets('alta: EAN duplicado muestra error y no inserta', (tester) async {
    superficieGrande(tester);
    await insertarProductoExistente();
    await tester.pumpWidget(envolver(ProductoFormScreen(baseDeDatos: db)));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de barras (opcional)'),
      '7790001001001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Duplicado',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo guardar'), findsOneWidget);
    expect(await db.select(db.productos).get(), hasLength(1));
  });

  testWidgets('edición: cambia el nombre del producto', (tester) async {
    superficieGrande(tester);
    final producto = await db.into(db.productos).insertReturning(
          ProductosCompanion.insert(
            id: 'p1',
            nombre: 'Nombre viejo',
            unidad: 'unidad',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
    )));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Nombre nuevo',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final fila = await (db.select(db.productos)
          ..where((t) => t.id.equals('p1')))
        .getSingle();
    expect(fila.nombre, 'Nombre nuevo');
  });

  testWidgets('elegir unidad de venta en el dropdown', (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      tokInterno: () async => 'QT',
    )));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Producto con unidad',
    );
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Unidad de venta *'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('g').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final filas = await db.select(db.productos).get();
    expect(filas.single.unidad, 'g');
  });
}
