import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';
import 'package:seguidor_precios/features/precios/producto_comparacion_screen.dart';

void main() {
  late BaseDeDatos db;
  late Producto producto;

  setUp(() async {
    db = BaseDeDatos.memoria();
    producto = await db.into(db.productos).insertReturning(
          ProductosCompanion.insert(
            id: 'p1',
            nombre: 'Mayonesa Marca A',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertarPrecio({
    required String comercioId,
    required String nombre,
    required double precio,
  }) async {
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: comercioId,
            nombre: nombre,
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.precios).insert(
          PreciosCompanion.insert(
            id: 'pr-$comercioId',
            productoId: 'p1',
            comercioId: comercioId,
            precio: precio,
            fechaToma: '2026-01-02',
            cargadoPor: 'u1',
            cargadoEn: '2026-01-02T10:00:00',
          ),
        );
  }

  Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  testWidgets('lista precios de menor a mayor con MÍNIMO primero', (tester) async {
    await insertarPrecio(comercioId: 'c1', nombre: 'Almacén', precio: 1500);
    await insertarPrecio(comercioId: 'c2', nombre: 'Kiosco', precio: 1200);

    await tester.pumpWidget(envolver(
      ProductoComparacionScreen(baseDeDatos: db, producto: producto),
    ));
    await tester.pumpAndSettle();

    final titulos = tester
        .widgetList(find.byType(ListTile))
        .map((w) => ((w as ListTile).title as Text).data!)
        .toList();

    expect(titulos, hasLength(2));
    expect(titulos[0], contains('1200.00'));
    expect(titulos[1], contains('1500.00'));
    expect(find.text('MÍNIMO'), findsOneWidget);
    expect(find.text('Kiosco'), findsOneWidget);
    expect(find.text('Almacén'), findsOneWidget);
  });

  testWidgets('sin precios muestra estado vacío', (tester) async {
    await tester.pumpWidget(envolver(
      ProductoComparacionScreen(baseDeDatos: db, producto: producto),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin precios'), findsOneWidget);
  });

  testWidgets('v0.1.4: editar datos desde la comparación actualiza el producto',
      (tester) async {
    await insertarPrecio(comercioId: 'c1', nombre: 'Almacén', precio: 1500);

    await tester.pumpWidget(envolver(
      ProductoComparacionScreen(baseDeDatos: db, producto: producto),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Nombre cerca del tope del formulario: escribirlo antes de scrollear.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Mayonesa Marca A 500g',
    );

    // El ListView del formulario es lazy y la pantalla de comparación tiene
    // el suyo debajo de la ruta: acotar al ListView del formulario, que es
    // lazy ('Guardar cambios' bajo el pliegue desde v0.1.5 no existe hasta
    // arrastrar).
    final Finder scrollable = find
        .descendant(
            of: find.byType(ProductoFormScreen),
            matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Guardar cambios'), 200,
        scrollable: scrollable);
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    // Formulario precargado con los datos actuales.
    expect(find.text('Guardar cambios'), findsOneWidget);
    // El botón queda bajo el pliegue en el formulario largo: llevarlo a vista.
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    // Vuelve a la comparación con el nombre actualizado.
    expect(find.text('Mayonesa Marca A 500g'), findsOneWidget);
    final filas = await db.select(db.productos).get();
    expect(filas.single.nombre, 'Mayonesa Marca A 500g');
  });
}
