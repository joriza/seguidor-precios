import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/articulos/articulo_detalle_screen.dart';
import 'package:seguidor_precios/features/busqueda/busqueda_screen.dart';
import 'package:seguidor_precios/features/precios/producto_comparacion_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
    await db.into(db.articulos).insert(
          ArticulosCompanion.insert(
            id: 'a1',
            nombre: 'Mayonesas',
            unidadBase: 'kg',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: 'c1',
            nombre: 'Almacén',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertarProducto({
    required String id,
    required String nombre,
    String? marca,
    String? codigo,
    String? borradoEn,
  }) =>
      db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: id,
              nombre: nombre,
              marca: Value(marca),
              codigoBarras: Value(codigo),
              unidad: 'g',
              contenidoNeto: const Value(500),
              articuloId: const Value('a1'),
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
              borradoEn: Value(borradoEn),
            ),
          );

  Future<void> insertarPrecio({
    required String id,
    required String productoId,
    required double precio,
    required String fechaToma,
  }) =>
      db.into(db.precios).insert(
            PreciosCompanion.insert(
              id: id,
              productoId: productoId,
              comercioId: 'c1',
              precio: precio,
              fechaToma: fechaToma,
              cargadoPor: 'u1',
              cargadoEn: '2026-01-01T10:00:00',
            ),
          );

  Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  Future<void> escribir(WidgetTester tester, String texto) async {
    await tester.enterText(find.byType(TextField), texto);
    await tester.pumpAndSettle();
  }

  testWidgets('sin consulta muestra la pista y ningún resultado',
      (tester) async {
    await insertarProducto(id: 'p1', nombre: 'Mayonesa');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));

    expect(
        find.text('Escribí para buscar por producto o artículo'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('busca por nombre parcial (mayúsculas indistintas) y muestra el último precio conocido', (tester) async {
    await insertarProducto(
        id: 'p1', nombre: 'Mayonesa', marca: 'Marca A', codigo: '7791234567890');
    await insertarPrecio(
        id: 'pr1', productoId: 'p1', precio: 100, fechaToma: '2026-01-02');
    await insertarPrecio(
        id: 'pr2', productoId: 'p1', precio: 120, fechaToma: '2026-01-05');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
    await escribir(tester, 'MAYO');

    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Mayonesa · Marca A'), findsOneWidget);
    // R1: último precio conocido = la toma más reciente.
    expect(find.textContaining('120.00'), findsOneWidget);
    expect(find.textContaining('100.00'), findsNothing);
    expect(find.textContaining('Almacén'), findsOneWidget);
    expect(find.textContaining('2026-01-05'), findsOneWidget);
    expect(find.textContaining('7791234567890'), findsOneWidget);
  });

  testWidgets('busca por marca y por código EAN', (tester) async {
    await insertarProducto(id: 'p1', nombre: 'Mayonesa', marca: 'Natura');
    await insertarProducto(
        id: 'p2', nombre: 'Arroz', codigo: '7790001112223');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));

    await escribir(tester, 'natura');
    expect(find.text('Mayonesa · Natura'), findsOneWidget);
    expect(find.text('Arroz'), findsNothing);

    await escribir(tester, '7790001112223');
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.text('Mayonesa'), findsNothing);
  });

  testWidgets('busca por artículo y muestra el conteo de productos',
      (tester) async {
    await insertarProducto(id: 'p1', nombre: 'Mayonesa A');
    await insertarProducto(id: 'p2', nombre: 'Mayonesa B');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
    await escribir(tester, 'mayonesas');

    expect(find.text('Artículos'), findsOneWidget);
    expect(find.text('Mayonesas'), findsOneWidget);
    expect(find.textContaining('2 producto(s)'), findsOneWidget);
  });

  testWidgets('tocar un producto abre su comparación (R13)',
      (tester) async {
    await insertarProducto(id: 'p1', nombre: 'Mayonesa');
    await insertarPrecio(
        id: 'pr1', productoId: 'p1', precio: 100, fechaToma: '2026-01-02');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
    await escribir(tester, 'mayonesa');

    await tester.tap(find.text('Mayonesa'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductoComparacionScreen), findsOneWidget);
  });

  testWidgets('tocar un artículo abre su detalle con agregados',
      (tester) async {
    await insertarProducto(id: 'p1', nombre: 'Mayonesa');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
    await escribir(tester, 'mayonesas');

    await tester.tap(find.text('Mayonesas'));
    await tester.pumpAndSettle();

    expect(find.byType(ArticuloDetalleScreen), findsOneWidget);
  });

  testWidgets('sin coincidencias muestra estado vacío', (tester) async {
    await insertarProducto(id: 'p1', nombre: 'Mayonesa');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
    await escribir(tester, 'yerba');

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('productos con borrado lógico no aparecen', (tester) async {
    await insertarProducto(
        id: 'p1', nombre: 'Jabón', borradoEn: '2026-01-06T00:00:00');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
    await escribir(tester, 'jabon');

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('producto sin precios muestra que no hay registros',
      (tester) async {
    await insertarProducto(id: 'p1', nombre: 'Mayonesa');

    await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
    await escribir(tester, 'mayonesa');

    expect(find.text('Sin precios registrados'), findsOneWidget);
  });
}
