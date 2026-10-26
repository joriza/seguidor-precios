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
    await tester.pumpWidget(envolver(ProductoFormScreen(baseDeDatos: db)));

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
