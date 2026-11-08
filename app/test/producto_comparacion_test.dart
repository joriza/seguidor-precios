import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/historial/historial_producto_screen.dart';
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
    String fechaToma = '2026-01-02',
  }) async {
    // Los tests de v0.3.16 agregan varias tomas del mismo comercio:
    // ignorar el comercio ya insertado (los precios son los que varían).
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: comercioId,
            nombre: nombre,
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
          onConflict: DoNothing(),
        );
    await db.into(db.precios).insert(
          PreciosCompanion.insert(
            id: 'pr-$comercioId-$fechaToma-${precio.toStringAsFixed(0)}',
            productoId: 'p1',
            comercioId: comercioId,
            precio: precio,
            fechaToma: fechaToma,
            cargadoPor: 'u1',
            cargadoEn: '$fechaToma T10:00:00',
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

  testWidgets(
      'v0.3.16: encabezado con el último precio por comercio (mínimo destacado) '
      '+ tendencia + filas densas (S3/S4/S5)', (tester) async {
    await insertarPrecio(comercioId: 'c1', nombre: 'Almacén', precio: 1500);
    await insertarPrecio(
        comercioId: 'c2', nombre: 'Kiosco', precio: 1200,
        fechaToma: '2026-01-03');
    await insertarPrecio(
        comercioId: 'c1', nombre: 'Almacén', precio: 1800,
        fechaToma: '2026-01-05');

    // Superficie alta para ver encabezado + filas sin scroll.
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envolver(
      ProductoComparacionScreen(baseDeDatos: db, producto: producto),
    ));
    await tester.pumpAndSettle();

    // Encabezado por comercio: el ÚLTIMO precio de cada uno (S5).
    expect(find.text('Almacén'), findsOneWidget);
    expect(find.text('Kiosco'), findsOneWidget);
    expect(find.text(r'$1800.00'), findsOneWidget); // último de Almacén
    expect(find.text(r'$1200.00'), findsOneWidget); // último de Kiosco

    // Mínimo destacado como hoy (S5): trofeo + MÍNIMO.
    expect(find.text('MÍNIMO'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);

    // Encabezado de tendencia (S4): 500 g → 1200/0.5 = 2400, 3000, 3600 / kg.
    expect(find.text('2400.00 / kg'), findsOneWidget); // Mínimo
    expect(find.text('3000.00 / kg'), findsOneWidget); // Promedio
    expect(find.text('3600.00 / kg'), findsOneWidget); // Máximo
    // Δ%: última toma global (1800, 01-05) vs la anterior (1200, 01-03).
    expect(find.text('+50.0% vs toma anterior'), findsOneWidget);
    // Sparkline en línea (S4).
    expect(
      find.descendant(
        of: find.byType(SparklineTendencia),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    // Filas densas debajo (S3): una por toma, no por comercio.
    final filas = tester.widgetList(find.byType(ListTile)).toList();
    expect(filas, hasLength(3));
    final titulos = filas
        .map((w) => ((w as ListTile).title as Text).data!)
        .toList();
    expect(titulos[0], contains('1200.00'));
    expect(titulos[0], contains('Kiosco'));
    expect(titulos[1], contains('1500.00'));
    expect(titulos[1], contains('Almacén'));
    expect(titulos[2], contains('1800.00'));
    // Variación % al final: 1500 → 1800 en Almacén.
    expect(find.textContaining('+20.0%'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'el historial completo sigue accesible: tap en la fila expande la toma (S3/S5)',
      (tester) async {
    await insertarPrecio(comercioId: 'c1', nombre: 'Almacén', precio: 1500);
    await insertarPrecio(
        comercioId: 'c1', nombre: 'Almacén', precio: 1800,
        fechaToma: '2026-01-05');

    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envolver(
      ProductoComparacionScreen(baseDeDatos: db, producto: producto),
    ));
    await tester.pumpAndSettle();

    // La toma vieja (1500) sigue listada debajo del encabezado (S5).
    expect(find.textContaining('\$1500.00 · Almacén'), findsOneWidget);

    await tester.tap(find.textContaining('\$1500.00 · Almacén'));
    await tester.pumpAndSettle();

    // Detalle completo de la toma a un tap: fecha cruda y unitario (S3).
    expect(find.textContaining('Fecha completa: 2026-01-02'), findsOneWidget);
    expect(find.textContaining('Precio por unidad: 3000.00 / kg'),
        findsOneWidget);
  });

  testWidgets(
      'una sola toma: sin Δ% ni variación, MÍNIMO intacto (S4 degrada)',
      (tester) async {
    await insertarPrecio(comercioId: 'c1', nombre: 'Almacén', precio: 1500);

    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envolver(
      ProductoComparacionScreen(baseDeDatos: db, producto: producto),
    ));
    await tester.pumpAndSettle();

    expect(find.text('MÍNIMO'), findsOneWidget);
    expect(find.text(r'$1500.00'), findsOneWidget);
    expect(find.textContaining('vs toma anterior'), findsNothing);
    expect(tester.takeException(), isNull);
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
