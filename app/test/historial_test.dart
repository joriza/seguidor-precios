import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/local/normalizacion.dart';
import 'package:seguidor_precios/features/historial/historial_producto_screen.dart';
import 'package:seguidor_precios/features/historial/historial_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertarProducto({
    required String id,
    required String nombre,
    String? marca,
    String? borradoEn,
  }) async =>
      db.into(db.productos).insertReturning(
            ProductosCompanion.insert(
              id: id,
              nombre: nombre,
              marca: Value(marca),
              unidad: 'unidad',
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
              borradoEn: Value(borradoEn),
            ),
          );

  Future<void> insertarComercio({
    required String id,
    required String nombre,
  }) async =>
      db.into(db.comercios).insert(
            ComerciosCompanion.insert(
              id: id,
              nombre: nombre,
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );

  Future<void> insertarPrecio({
    required String id,
    required String productoId,
    required String comercioId,
    required double precio,
    required String fechaToma,
  }) async =>
      db.into(db.precios).insert(
            PreciosCompanion.insert(
              id: id,
              productoId: productoId,
              comercioId: comercioId,
              precio: precio,
              fechaToma: fechaToma,
              cargadoPor: 'u1',
              cargadoEn: '2026-01-01T10:00:00',
            ),
          );

  Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  group('variacionPorcentual (R8)', () {
    test('suba de precio da porcentaje positivo', () {
      expect(variacionPorcentual(100, 110), closeTo(10.0, 0.001));
    });

    test('baja de precio da porcentaje negativo', () {
      expect(variacionPorcentual(100, 90), closeTo(-10.0, 0.001));
    });

    test('precio igual da cero', () {
      expect(variacionPorcentual(100, 100), 0.0);
    });

    test('anterior no utilizable (<= 0) da null', () {
      expect(variacionPorcentual(0, 50), isNull);
      expect(variacionPorcentual(-5, 50), isNull);
    });
  });

  group('HistorialScreen', () {
    testWidgets('sin precios muestra estado vacío', (tester) async {
      await tester.pumpWidget(envolver(HistorialScreen(baseDeDatos: db)));
      await tester.pumpAndSettle();

      expect(find.text('Sin precios registrados todavía'), findsOneWidget);
    });

    testWidgets(
        'lista productos con cantidad y última toma, el más reciente primero',
        (tester) async {
      await insertarProducto(id: 'p1', nombre: 'Mayonesa', marca: 'Marca A');
      await insertarProducto(id: 'p2', nombre: 'Arroz');
      await insertarComercio(id: 'c1', nombre: 'Almacén');
      await insertarPrecio(
          id: 'pr1',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 100,
          fechaToma: '2026-01-02');
      await insertarPrecio(
          id: 'pr2',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 105,
          fechaToma: '2026-01-05');
      await insertarPrecio(
          id: 'pr3',
          productoId: 'p2',
          comercioId: 'c1',
          precio: 50,
          fechaToma: '2026-01-03');

      await tester.pumpWidget(envolver(HistorialScreen(baseDeDatos: db)));
      await tester.pumpAndSettle();

      final subtitulos = tester
          .widgetList(find.byType(ListTile))
          .map((w) => ((w as ListTile).subtitle as Text).data!)
          .toList();

      expect(subtitulos, hasLength(2));
      // p1 tiene última toma 2026-01-05 > p2 2026-01-03 → primero.
      expect(subtitulos[0], contains('2 precio(s)'));
      expect(subtitulos[0], contains('2026-01-05'));
      expect(subtitulos[1], contains('1 precio(s)'));
      expect(subtitulos[1], contains('2026-01-03'));
      // Nombre con marca cuando la tiene.
      expect(find.text('Mayonesa · Marca A'), findsOneWidget);
      expect(find.text('Arroz'), findsOneWidget);
    });

    testWidgets('excluye productos con borrado lógico', (tester) async {
      await insertarProducto(
          id: 'p1', nombre: 'Mayonesa', borradoEn: '2026-01-06T00:00:00');
      await insertarComercio(id: 'c1', nombre: 'Almacén');
      await insertarPrecio(
          id: 'pr1',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 100,
          fechaToma: '2026-01-02');

      await tester.pumpWidget(envolver(HistorialScreen(baseDeDatos: db)));
      await tester.pumpAndSettle();

      expect(find.text('Sin precios registrados todavía'), findsOneWidget);
    });

    testWidgets('tocar un producto abre su cronológico', (tester) async {
      await insertarProducto(id: 'p1', nombre: 'Mayonesa');
      await insertarComercio(id: 'c1', nombre: 'Almacén');
      await insertarPrecio(
          id: 'pr1',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 100,
          fechaToma: '2026-01-02');

      await tester.pumpWidget(envolver(HistorialScreen(baseDeDatos: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(HistorialProductoScreen), findsOneWidget);
      expect(find.text('Filtrar por comercio'), findsOneWidget);
    });
  });

  group('HistorialProductoScreen', () {
    testWidgets('producto sin precios muestra estado vacío', (tester) async {
      await insertarProducto(id: 'p1', nombre: 'Mayonesa');

      await tester.pumpWidget(envolver(HistorialProductoScreen(
        baseDeDatos: db,
        productoId: 'p1',
        nombre: 'Mayonesa',
      )));
      await tester.pumpAndSettle();

      expect(
          find.text('Sin precios para el filtro seleccionado'), findsOneWidget);
    });

    testWidgets(
        'cronológico de más nuevo a más viejo con variación % entre tomas consecutivas',
        (tester) async {
      await insertarProducto(id: 'p1', nombre: 'Mayonesa');
      await insertarComercio(id: 'c1', nombre: 'Almacén');
      await insertarPrecio(
          id: 'pr1',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 100,
          fechaToma: '2026-01-01');
      await insertarPrecio(
          id: 'pr2',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 110,
          fechaToma: '2026-01-02');
      await insertarPrecio(
          id: 'pr3',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 99,
          fechaToma: '2026-01-03');

      await tester.pumpWidget(envolver(HistorialProductoScreen(
        baseDeDatos: db,
        productoId: 'p1',
        nombre: 'Mayonesa',
      )));
      await tester.pumpAndSettle();

      final filas = tester.widgetList(find.byType(ListTile)).toList();
      expect(filas, hasLength(3));

      // Orden descendente: 99 (01-03), 110 (01-02), 100 (01-01).
      // Variación de cada fila contra su toma anterior en orden cronológico:
      // 99 vs 110 → -10.0%; 110 vs 100 → +10.0%; 100 es la primera toma → sin variación.
      final variaciones = filas
          .map((w) => (w as ListTile).trailing)
          .map((t) => t is Text ? t.data : null)
          .toList();
      expect(variaciones[0], '-10.0%');
      expect(variaciones[1], '+10.0%');
      expect(variaciones[2], isNull);

      final titulos = filas
          .map((w) => ((w as ListTile).title as Text).data!)
          .toList();
      expect(titulos[0], contains('99.00'));
      expect(titulos[1], contains('110.00'));
      expect(titulos[2], contains('100.00'));
    });

    testWidgets('el filtro por comercio recalcula variaciones dentro del comercio',
        (tester) async {
      await insertarProducto(id: 'p1', nombre: 'Mayonesa');
      await insertarComercio(id: 'c1', nombre: 'Almacén');
      await insertarComercio(id: 'c2', nombre: 'Kiosco');
      await insertarPrecio(
          id: 'pr1',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 100,
          fechaToma: '2026-01-01');
      await insertarPrecio(
          id: 'pr2',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 110,
          fechaToma: '2026-01-02');
      await insertarPrecio(
          id: 'pr3',
          productoId: 'p1',
          comercioId: 'c2',
          precio: 99,
          fechaToma: '2026-01-03');

      await tester.pumpWidget(envolver(HistorialProductoScreen(
        baseDeDatos: db,
        productoId: 'p1',
        nombre: 'Mayonesa',
      )));
      await tester.pumpAndSettle();

      // Filtrar por Kiosco: una sola toma → sin variación.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiosco').last);
      await tester.pumpAndSettle();

      var filas = tester.widgetList(find.byType(ListTile)).toList();
      expect(filas, hasLength(1));
      expect(((filas.single as ListTile).trailing as Text?)?.data, isNull);
      expect(((filas.single as ListTile).title as Text).data, contains('99.00'));

      // Filtrar por Almacén: 100 → 110 → +10.0% en la más nueva.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Almacén').last);
      await tester.pumpAndSettle();

      filas = tester.widgetList(find.byType(ListTile)).toList();
      expect(filas, hasLength(2));
      final variaciones = filas
          .map((w) => (w as ListTile).trailing)
          .map((t) => t is Text ? t.data : null)
          .toList();
      expect(variaciones[0], '+10.0%');
      expect(variaciones[1], isNull);
    });
  });
}
