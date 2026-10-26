import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/articulos/articulo_detalle_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Articulo> insertarArticulo() {
    return db.into(db.articulos).insertReturning(
          ArticulosCompanion.insert(
            id: 'a1',
            nombre: 'Mayonesa',
            unidadBase: 'kg',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  Future<void> insertarProducto({
    required String id,
    required String nombre,
    required String? marca,
    required String unidad,
    double? contenidoNeto,
  }) {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: id,
            nombre: nombre,
            unidad: unidad,
            contenidoNeto: Value(contenidoNeto),
            marca: Value(marca),
            articuloId: const Value('a1'),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  /// Los comercios deben existir previamente (los crea el escenario).
  Future<void> insertarPrecio({
    required String id,
    required String productoId,
    required String comercioId,
    required double precio,
  }) async {
    await db.into(db.precios).insert(
          PreciosCompanion.insert(
            id: id,
            productoId: productoId,
            comercioId: comercioId,
            precio: precio,
            fechaToma: '2026-01-02',
            cargadoPor: 'u1',
            cargadoEn: '2026-01-02T10:00:00',
          ),
        );
  }

  /// Escenario del ejemplo de docs/modelo-de-datos.md:
  /// Marca A 1 kg = 2700 (mínimo), Marca A 500 g = 3000, Marca B 250 g = 3600.
  Future<Articulo> escenarioMayonesa() async {
    final Articulo articulo = await insertarArticulo();
    await insertarProducto(
      id: 'pa',
      nombre: 'Mayonesa',
      marca: 'Marca A',
      unidad: 'kg',
    );
    await insertarProducto(
      id: 'pc',
      nombre: 'Mayonesa',
      marca: 'Marca A',
      unidad: 'g',
      contenidoNeto: 500,
    );
    await insertarProducto(
      id: 'pb',
      nombre: 'Mayonesa',
      marca: 'Marca B',
      unidad: 'g',
      contenidoNeto: 250,
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
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: 'c2',
            nombre: 'Kiosco',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await insertarPrecio(
        id: 'pr1', productoId: 'pa', comercioId: 'c1', precio: 2700);
    await insertarPrecio(
        id: 'pr2', productoId: 'pc', comercioId: 'c1', precio: 1500);
    await insertarPrecio(
        id: 'pr3', productoId: 'pb', comercioId: 'c2', precio: 900);
    return articulo;
  }

  testWidgets('lista ordenada por precio/kg con el mínimo primero', (tester) async {
    final Articulo articulo = await escenarioMayonesa();
    await tester.pumpWidget(MaterialApp(
      home: ArticuloDetalleScreen(baseDeDatos: db, articulo: articulo),
    ));
    await tester.pumpAndSettle();

    final titulos = tester
        .widgetList(find.byType(ListTile))
        .map((w) => ((w as ListTile).title as Text).data!)
        .toList();

    expect(titulos, hasLength(3));
    expect(titulos[0], contains('2700.00'));
    expect(titulos[1], contains('3000.00'));
    expect(titulos[2], contains('3600.00'));
    expect(find.text('MÍNIMO'), findsOneWidget);
  });

  testWidgets('muestra cada comercio y precio en la fila', (tester) async {
    final Articulo articulo = await escenarioMayonesa();
    await tester.pumpWidget(MaterialApp(
      home: ArticuloDetalleScreen(baseDeDatos: db, articulo: articulo),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Almacén'), findsNWidgets(2));
    expect(find.textContaining('Kiosco'), findsOneWidget);
    expect(find.textContaining('\$2700.00'), findsOneWidget);
    expect(find.textContaining('\$1500.00'), findsOneWidget);
    expect(find.textContaining('\$900.00'), findsOneWidget);
  });

  testWidgets('sin precios comparables muestra estado vacío', (tester) async {
    final Articulo articulo = await insertarArticulo();
    await tester.pumpWidget(MaterialApp(
      home: ArticuloDetalleScreen(baseDeDatos: db, articulo: articulo),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin precios comparables'), findsOneWidget);
  });
}
