import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/articulos/agregados.dart';
import 'package:seguidor_precios/features/articulos/articulo_detalle_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
    await db.into(db.articulos).insert(
          ArticulosCompanion.insert(
            id: 'a1',
            nombre: 'Mayonesa',
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
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: 'c2',
            nombre: 'Kiosco',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  /// Producto a granel (AD-014): unidad = base, sin contenido neto →
  /// precio por unidad = precio.
  Future<void> insertarProductoGranel({required String id}) =>
      db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: id,
              nombre: 'Mayonesa $id',
              unidad: 'kg',
              articuloId: const Value('a1'),
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
  }) =>
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

  /// Escenario base con `hoy` = 2026-01-31: dos precios dentro de la ventana
  /// de 30 días (límite inclusive) y uno fuera.
  Future<void> sembrarVentana() async {
    await insertarProductoGranel(id: 'p1');
    await insertarPrecio(
        id: 'pr1',
        productoId: 'p1',
        comercioId: 'c1',
        precio: 100,
        fechaToma: '2026-01-01'); // límite de la ventana → incluido
    await insertarPrecio(
        id: 'pr2',
        productoId: 'p1',
        comercioId: 'c2',
        precio: 200,
        fechaToma: '2026-01-15');
    await insertarPrecio(
        id: 'pr3',
        productoId: 'p1',
        comercioId: 'c1',
        precio: 300,
        fechaToma: '2025-12-01'); // fuera de la ventana
  }

  Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  /// Busca un texto dentro de la card de agregados (la lista del comparador
  /// de abajo puede mostrar el mismo valor de precio por unidad).
  Finder enCard(String texto) => find.descendant(
        of: find.byKey(const ValueKey('agregados-card')),
        matching: find.text(texto),
      );

  Widget pantalla({DateTime? hoy}) => ArticuloDetalleScreen(
        baseDeDatos: db,
        articulo: const Articulo(
          id: 'a1',
          nombre: 'Mayonesa',
          unidadBase: 'kg',
          creadoPor: 'u1',
          creadoEn: '2026-01-01T00:00:00',
          actualizadoEn: '2026-01-01T00:00:00',
        ),
        hoy: hoy,
      );

  group('agregar (S11, R12)', () {
    test('lista vacía da null', () {
      expect(agregar(<double>[]), isNull);
    });

    test('único precio: mínimo = promedio = máximo', () {
      final a = agregar(<double>[42.5])!;
      expect(a.minimo, 42.5);
      expect(a.promedio, 42.5);
      expect(a.maximo, 42.5);
      expect(a.cantidad, 1);
    });

    test('varios precios: mínimo, promedio y máximo correctos', () {
      final a = agregar(<double>[100, 200, 300])!;
      expect(a.minimo, 100);
      expect(a.promedio, 200);
      expect(a.maximo, 300);
      expect(a.cantidad, 3);
    });
  });

  group('inicioDeVentana', () {
    test('30 días atrás formatea ISO YYYY-MM-DD', () {
      expect(inicioDeVentana(DateTime(2026, 1, 31)), '2026-01-01');
    });

    test('cruza meses y años correctamente', () {
      expect(inicioDeVentana(DateTime(2026, 3, 1)), '2026-01-30');
      expect(inicioDeVentana(DateTime(2026, 1, 15)), '2025-12-16');
    });

    test('ventana personalizada', () {
      expect(inicioDeVentana(DateTime(2026, 1, 31), dias: 7), '2026-01-24');
    });
  });

  group('ArticuloDetalleScreen — agregados (S11)', () {
    testWidgets('por defecto 30 días: el precio fuera de ventana no participa',
        (tester) async {
      await sembrarVentana();

      await tester.pumpWidget(envolver(pantalla(hoy: DateTime(2026, 1, 31))));
      await tester.pumpAndSettle();

      // Agregados de {100 (límite incluido), 200}: el 300 de 2025-12-01 no.
      expect(enCard('100.00 / kg'), findsOneWidget); // Mínimo
      expect(enCard('150.00 / kg'), findsOneWidget); // Promedio
      expect(enCard('200.00 / kg'), findsOneWidget); // Máximo
      expect(enCard('300.00 / kg'), findsNothing);
      // El comparador de abajo sigue mostrando TODOS los precios (R11/R13):
      // la fila del precio fuera de ventana está, con su subtítulo.
      expect(find.textContaining('\$300.00'), findsOneWidget);
    });

    testWidgets('histórico incluye los precios fuera de la ventana',
        (tester) async {
      await sembrarVentana();

      await tester.pumpWidget(envolver(pantalla(hoy: DateTime(2026, 1, 31))));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Últimos 30 días'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Histórico').last);
      await tester.pumpAndSettle();

      // Agregados de {100, 200, 300}.
      expect(enCard('100.00 / kg'), findsOneWidget);
      expect(enCard('200.00 / kg'), findsOneWidget); // Promedio
      expect(enCard('300.00 / kg'), findsOneWidget); // Máximo
    });

    testWidgets('el filtro por comercio recalcula los agregados',
        (tester) async {
      await sembrarVentana();

      await tester.pumpWidget(envolver(pantalla(hoy: DateTime(2026, 1, 31))));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Todos los comercios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiosco').last);
      await tester.pumpAndSettle();

      // Solo el Kiosco tiene 200 en la ventana → único valor en los tres.
      expect(enCard('200.00 / kg'), findsNWidgets(3));
      expect(enCard('100.00 / kg'), findsNothing);
    });

    testWidgets(
        'producto sin contenido neto (no granel) no participa de los agregados',
        (tester) async {
      await sembrarVentana();
      // Empaquetado en g sin contenido neto → no comparable (R12, AD-014).
      await db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: 'p2',
              nombre: 'Mayonesa p2',
              unidad: 'g',
              articuloId: const Value('a1'),
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );
      await insertarPrecio(
          id: 'pr4',
          productoId: 'p2',
          comercioId: 'c1',
          precio: 999,
          fechaToma: '2026-01-20');

      await tester.pumpWidget(envolver(pantalla(hoy: DateTime(2026, 1, 31))));
      await tester.pumpAndSettle();

      // Los agregados siguen siendo los de {100, 200}.
      expect(enCard('100.00 / kg'), findsOneWidget);
      expect(enCard('150.00 / kg'), findsOneWidget);
      expect(enCard('200.00 / kg'), findsOneWidget);
    });
  });
}
