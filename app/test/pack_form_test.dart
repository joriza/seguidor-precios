import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';

/// S5 (v0.3.8): el formulario de producto muestra el campo pack —
/// default 1, editable, validado entero ≥ 1 — con texto de ayuda
/// (AD-007) que explica la normalización ÷ (pack × contenido).
void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  void superficieGrande(WidgetTester tester) {
    // El campo pack (S5) y su texto de ayuda suman altura: una superficie
    // mayor que la de producto_form_test para que el botón Guardar quede
    // construido y alcanzable por tap().
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget envolver(ProductoFormScreen pantalla) => MaterialApp(
        key: UniqueKey(),
        home: Scaffold(body: pantalla),
      );

  TextField campoPack(WidgetTester tester) => tester.widget<TextField>(
      find.widgetWithText(TextField, 'Unidades por pack'));

  testWidgets('alta: el campo pack viene en 1 por defecto y guarda lo '
      'ingresado', (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      tokInterno: () async => 'QT',
    )));

    // Default 1 (S5).
    expect(campoPack(tester).controller!.text, '1');

    // El texto de ayuda explica la normalización (AD-007).
    expect(campoPack(tester).decoration?.helperText,
        contains('pack × contenido por unidad'));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Fideos Marca',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contenido neto (opcional)'),
      '500',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unidades por pack'),
      '10',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final filas = await db.select(db.productos).get();
    expect(filas, hasLength(1));
    expect(filas.single.pack, 10);
    expect(filas.single.contenidoNeto, 500);
  });

  testWidgets('alta sin tocar el pack guarda 1', (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      tokInterno: () async => 'QT',
    )));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Unitario',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    final filas = await db.select(db.productos).get();
    expect(filas.single.pack, 1);
  });

  testWidgets('validación: 0 y no-entero se rechazan sin guardar',
      (tester) async {
    superficieGrande(tester);
    await tester.pumpWidget(envolver(ProductoFormScreen(baseDeDatos: db)));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Fideos Marca',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unidades por pack'),
      '0',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();
    expect(find.text('Debe ser 1 o más'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unidades por pack'),
      '2.5',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresá un número entero'), findsOneWidget);

    // Nada se guardó en ninguno de los dos intentos.
    expect(await db.select(db.productos).get(), isEmpty);
  });

  testWidgets('edición: precarga el pack del producto y permite cambiarlo',
      (tester) async {
    superficieGrande(tester);
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p1',
            nombre: 'Galletitas',
            unidad: 'g',
            contenidoNeto: const Value(300),
            pack: const Value(5),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    final producto = await (db.select(db.productos)
          ..where((p) => p.id.equals('p1')))
        .getSingle();

    await tester.pumpWidget(
        envolver(ProductoFormScreen(baseDeDatos: db, producto: producto)));

    // Precarga el valor existente.
    expect(campoPack(tester).controller!.text, '5');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unidades por pack'),
      '3',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final editado =
        await (db.select(db.productos)..where((p) => p.id.equals('p1')))
            .getSingle();
    expect(editado.pack, 3);
  });
}
