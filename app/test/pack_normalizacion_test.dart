import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/local/normalizacion.dart';
import 'package:seguidor_precios/features/articulos/articulo_detalle_screen.dart';

/// S2 (v0.3.8): precio normalizado = precio ÷ (pack × contenido_neto).
/// El unitario (pack 1) y el pack se normalizan al mismo $/kg cuando el
/// precio del pack es proporcional; el pack entra igual en el comparador
/// (R11/R13) y en los agregados (S11/R12).
void main() {
  group('precioPorUnidad con pack', () {
    test('fideos pack ×10 (500 g c/u) a 7500 → 1500 por kg', () {
      expect(
        precioPorUnidad(
          precio: 7500,
          unidad: 'g',
          unidadBase: 'kg',
          contenidoNeto: 500,
          pack: 10,
        ),
        closeTo(1500, 0.01),
      );
    });

    test('el unitario (pack 1, precio 1/10) normaliza igual: 1500 por kg', () {
      expect(
        precioPorUnidad(
          precio: 750,
          unidad: 'g',
          unidadBase: 'kg',
          contenidoNeto: 500,
          pack: 1,
        ),
        closeTo(1500, 0.01),
      );
      // Pack omitido = pack 1 (presentaciones viejas, compatibilidad S6).
      expect(
        precioPorUnidad(
          precio: 750,
          unidad: 'g',
          unidadBase: 'kg',
          contenidoNeto: 500,
        ),
        closeTo(1500, 0.01),
      );
    });

    test('granel con pack: harina 6 kg a 4200 → 700 por kg', () {
      expect(
        precioPorUnidad(
          precio: 4200,
          unidad: 'kg',
          unidadBase: 'kg',
          pack: 6,
        ),
        closeTo(700, 0.01),
      );
    });
  });

  group('comparador y agregados con pack (ArticuloDetalleScreen)', () {
    late BaseDeDatos db;

    setUp(() {
      db = BaseDeDatos.memoria();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> insertarArticulo() {
      return db.into(db.articulos).insert(
            ArticulosCompanion.insert(
              id: 'a1',
              nombre: 'Fideos',
              unidadBase: 'kg',
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );
    }

    Future<void> insertarProducto({
      required String id,
      required int pack,
    }) {
      return db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: id,
              nombre: 'Fideos Marca',
              unidad: 'g',
              contenidoNeto: const Value(500),
              articuloId: const Value('a1'),
              pack: Value(pack),
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );
    }

    Future<void> insertarPrecio({
      required String id,
      required String productoId,
      required double precio,
    }) {
      return db.into(db.precios).insert(
            PreciosCompanion.insert(
              id: id,
              productoId: productoId,
              comercioId: 'c1',
              precio: precio,
              fechaToma: '2026-01-02',
              cargadoPor: 'u1',
              cargadoEn: '2026-01-02T10:00:00',
            ),
          );
    }

    testWidgets('pack ×10 al precio del pack y unitario al 1/10 '
        'normalizan al mismo precio por kg y participan igual de los agregados',
        (tester) async {
      await insertarArticulo();
      await db.into(db.comercios).insert(
            ComerciosCompanion.insert(
              id: 'c1',
              nombre: 'Almacén',
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );
      await insertarProducto(id: 'p-pack', pack: 10);
      await insertarProducto(id: 'p-unitario', pack: 1);
      await insertarPrecio(id: 'pr-pack', productoId: 'p-pack', precio: 7500);
      await insertarPrecio(
          id: 'pr-unitario', productoId: 'p-unitario', precio: 750);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArticuloDetalleScreen(
            baseDeDatos: db,
            articulo: await (db.select(db.articulos)
                  ..where((a) => a.id.equals('a1')))
                .getSingle(),
            // Ventana 30 días determinista (el filtro S11 usa `hoy`): los
            // precios son del 2026-01-02.
            hoy: DateTime(2026, 1, 3),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Ambas presentaciones normalizan a 1500.00 / kg: 2 filas del
      // comparador + mínimo/promedio/máximo de los agregados.
      expect(find.text('1500.00 / kg'), findsNWidgets(5));

      // El precio absoluto de cada fila sigue siendo el del pack (el
      // subtítulo lo muestra junto al comercio: 'Almacén · $7500.00').
      expect(find.textContaining('\$7500.00'), findsOneWidget);
      expect(find.textContaining('\$750.00'), findsOneWidget);
    });
  });
}
