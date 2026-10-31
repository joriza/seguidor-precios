import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/busqueda/busqueda_screen.dart';
import 'package:seguidor_precios/features/escaner/escaner_screen.dart';

/// S2/S5 (v0.3.8) en escáner y búsqueda:
/// - la ficha del escáner marca «Pack ×N» cuando N > 1 (N = 1 render igual);
/// - la línea del último precio normaliza ÷ (pack × contenido) (S2);
/// - las filas de búsqueda marcan «Pack ×N» en el subtítulo, solo si N > 1.
void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
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

  Future<int> insertarProducto({
    required String id,
    required String nombre,
    String? codigo,
    required int pack,
    double? contenidoNeto,
  }) {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: id,
            codigoBarras: Value(codigo),
            nombre: nombre,
            unidad: 'g',
            contenidoNeto: Value(contenidoNeto),
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

  group('ficha del escáner', () {
    Widget envolver(EscanerScreen pantalla) => MaterialApp(
          home: Scaffold(body: pantalla),
        );

    testWidgets('marca Pack ×10 en el producto encontrado (N > 1)',
        (tester) async {
      await insertarProducto(
        id: 'p1',
        nombre: 'Fideos Marca',
        codigo: '7791234567890',
        pack: 10,
      );

      await tester.pumpWidget(envolver(
        EscanerScreen(baseDeDatos: db, mostrarCamara: false),
      ));
      await tester.enterText(find.byType(TextField), '7791234567890');
      await tester.tap(find.text('Buscar producto'));
      await tester.pumpAndSettle();

      expect(find.text('Producto encontrado: Fideos Marca · Pack ×10'),
          findsOneWidget);
    });

    testWidgets('pack = 1: la ficha renderiza exactamente igual que hoy',
        (tester) async {
      await insertarProducto(
        id: 'p2',
        nombre: 'Mayonesa Marca A',
        codigo: '7790001001001',
        pack: 1,
      );

      await tester.pumpWidget(envolver(
        EscanerScreen(baseDeDatos: db, mostrarCamara: false),
      ));
      await tester.enterText(find.byType(TextField), '7790001001001');
      await tester.tap(find.text('Buscar producto'));
      await tester.pumpAndSettle();

      expect(find.text('Producto encontrado: Mayonesa Marca A'),
          findsOneWidget);
    });

    testWidgets('la línea del último precio normaliza ÷ (pack × contenido)',
        (tester) async {
      await insertarProducto(
        id: 'p3',
        nombre: 'Fideos Marca',
        codigo: '7791234567890',
        pack: 10,
        contenidoNeto: 500,
      );
      await insertarPrecio(id: 'pr1', productoId: 'p3', precio: 7500);

      await tester.pumpWidget(envolver(
        EscanerScreen(baseDeDatos: db, mostrarCamara: false),
      ));
      await tester.enterText(find.byType(TextField), '7791234567890');
      await tester.tap(find.text('Buscar producto'));
      await tester.pumpAndSettle();

      // S2: el pack trae 10 × 500 g = 5 kg → 7500 / 5 = 1500.00 / kg.
      // Sin el pack, la línea mostraría 15000.00 / kg.
      expect(
        find.text('Último precio: \$7500.00 · Almacén · 2026-01-02 '
            '(1500.00 / kg)'),
        findsOneWidget,
      );
    });
  });

  group('filas de búsqueda', () {
    Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

    Future<void> escribir(WidgetTester tester, String texto) async {
      await tester.enterText(find.byType(TextField), texto);
      await tester.pumpAndSettle();
    }

    testWidgets('el subtítulo marca Pack ×10 solo cuando N > 1',
        (tester) async {
      await insertarProducto(
        id: 'p-pack',
        nombre: 'Fideos Marca',
        codigo: '7791234567890',
        pack: 10,
        contenidoNeto: 500,
      );
      await insertarPrecio(id: 'pr1', productoId: 'p-pack', precio: 7500);
      await insertarProducto(
        id: 'p-unit',
        nombre: 'Fideos Unitario',
        pack: 1,
      );

      await tester.pumpWidget(envolver(BusquedaScreen(baseDeDatos: db)));
      await escribir(tester, 'FIDEOS');

      // Pack: el subtítulo agrega la marca al final.
      expect(
        find.text('7791234567890 · Último: \$7500.00 · Almacén · 2026-01-02'
            ' · Pack ×10'),
        findsOneWidget,
      );
      // Unitario (N = 1): subtítulo idéntico al de hoy, sin marca.
      expect(find.text('Sin precios registrados'), findsOneWidget);
    });
  });
}
