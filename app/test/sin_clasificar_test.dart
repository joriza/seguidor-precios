import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/articulos/sin_clasificar_screen.dart';

/// v0.3.9 (S2): pantalla «Sin clasificar» — productos sin artículo con
/// sugerencias (S1), asignación individual, alta de artículo nuevo y lote
/// con confirmación. La asignación toca SOLO articulo_id (S3) y encola
/// por la sync normal. Sin red real: base en memoria.
void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Widget envolver(SinClasificarScreen pantalla) => MaterialApp(
        home: Scaffold(body: pantalla),
      );

  Future<void> insertarArticulo(
    String id,
    String nombre, {
    String unidadBase = 'kg',
  }) {
    return db.into(db.articulos).insert(
          ArticulosCompanion.insert(
            id: id,
            nombre: nombre,
            unidadBase: unidadBase,
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  Future<void> insertarProducto(
    String id, {
    String nombre = 'Producto',
    String? marca,
    String? codigoBarras,
    String? articuloId,
    String? categoria,
    double? contenidoNeto,
    String? borradoEn,
  }) {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: id,
            nombre: nombre,
            marca: Value(marca),
            codigoBarras: Value(codigoBarras),
            articuloId: Value(articuloId),
            categoria: Value(categoria),
            contenidoNeto: Value(contenidoNeto),
            unidad: 'g',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
            borradoEn: Value(borradoEn),
          ),
        );
  }

  testWidgets(
      'lista solo los productos sin artículo, con nombre, marca y código; '
      'excluye borrados y clasificados (S3)', (tester) async {
    await insertarArticulo('a1', 'Mayonesa');
    await insertarProducto('p1',
        nombre: 'Galletitas de chocolate',
        marca: 'Bagley',
        codigoBarras: '7790001001001',
        categoria: 'Snacks, Sweet snacks, Biscuits, Cookies');
    await insertarProducto('p2', nombre: 'Fideos secos');
    await insertarProducto('p3',
        nombre: 'Clasificado', articuloId: 'a1'); // con artículo: fuera
    await insertarProducto('p4',
        nombre: 'Borrado',
        borradoEn: '2026-01-02T00:00:00'); // baja: nunca aparece (S3)

    await tester.pumpWidget(envolver(SinClasificarScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.text('Sin clasificar (2)'), findsOneWidget);
    expect(find.text('Galletitas de chocolate'), findsOneWidget);
    expect(find.textContaining('Bagley'), findsOneWidget);
    expect(find.textContaining('7790001001001'), findsOneWidget);
    expect(find.textContaining('sin código'), findsOneWidget);expect(find.text('Clasificado'), findsNothing);
    expect(find.text('Borrado'), findsNothing);
  });

  testWidgets('estado vacío cuando no hay productos sin clasificar (S3)',
      (tester) async {
    await tester.pumpWidget(envolver(SinClasificarScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.text('No hay productos sin clasificar'), findsOneWidget);
  });

  testWidgets(
      'S2/S3: tocar la sugerencia asigna el artículo al producto: solo '
      'articulo_id cambia y queda encolado para la sync', (tester) async {
    await insertarArticulo('a1', 'Galletitas');
    await insertarProducto('p1',
        nombre: 'Galletitas de chocolate',
        marca: 'Bagley',
        codigoBarras: '7790001001001',
        categoria: 'Snacks, Sweet snacks, Biscuits, Cookies',
        contenidoNeto: 350);

    await tester.pumpWidget(envolver(SinClasificarScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chip-p1-a1')));
    await tester.pumpAndSettle();

    final fila = await (db.select(db.productos)
          ..where((t) => t.id.equals('p1')))
        .getSingle();
    expect(fila.articuloId, 'a1');
    // S3: nada más del producto cambió.
    expect(fila.nombre, 'Galletitas de chocolate');
    expect(fila.marca, 'Bagley');
    expect(fila.categoria, 'Snacks, Sweet snacks, Biscuits, Cookies');
    expect(fila.contenidoNeto, 350);
    expect(fila.codigoBarras, '7790001001001');
    // Viaja por la sync normal (encolar, regla de sync 2).
    final outbox = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals('producto')))
        .get();
    expect(outbox, hasLength(1));
    expect(outbox.single.filaId, 'p1');
    expect(outbox.single.operacion, 'upsert');
  });

  testWidgets('S2: el dueño da de alta un artículo desde la pantalla y queda '
      'sugerido para el producto', (tester) async {
    await insertarProducto('p1', nombre: 'Galletitas de chocolate');

    await tester.pumpWidget(envolver(SinClasificarScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.text('Sin sugerencias'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nuevo-articulo-p1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del artículo *'),
      'Galletitas',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final articulos = await db.select(db.articulos).get();
    expect(articulos, hasLength(1));
    expect(articulos.single.nombre, 'Galletitas');
    expect(articulos.single.unidadBase, 'kg');

    // El artículo nuevo queda seleccionable/sugerido: chip visible.
    expect(find.widgetWithText(ActionChip, 'Galletitas'), findsOneWidget);
  });

  testWidgets(
      'S2: lote — con confirmación, un artículo destino se asigna a todos '
      'los seleccionados (uno por producto, encolados)', (tester) async {
    await insertarArticulo('a1', 'Galletitas');
    await insertarProducto('p1', nombre: 'Galletitas de chocolate');
    await insertarProducto('p2', nombre: 'Galletitas de vainilla');
    await insertarProducto('p3', nombre: 'Yerba mate');

    await tester.pumpWidget(envolver(SinClasificarScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('check-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('check-p2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('btn-clasificar-lote')));
    await tester.pumpAndSettle();

    // Elige el artículo destino: recién entonces pide confirmación (S2).
    await tester.tap(find.byKey(const ValueKey('destino-a1')));
    await tester.pumpAndSettle();

    // Confirma ANTES de aplicar (S2).
    expect(find.textContaining('¿Asignar «Galletitas» a 2 producto(s)?'),
        findsOneWidget);
    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();

    final fila1 =
        await (db.select(db.productos)..where((t) => t.id.equals('p1')))
            .getSingle();
    final fila2 =
        await (db.select(db.productos)..where((t) => t.id.equals('p2')))
            .getSingle();
    final fila3 =
        await (db.select(db.productos)..where((t) => t.id.equals('p3')))
            .getSingle();
    expect(fila1.articuloId, 'a1');
    expect(fila2.articuloId, 'a1');
    expect(fila3.articuloId, isNull); // no seleccionado: intacto

    // Una entrada de outbox por producto asignado (encolado individual).
    final outbox = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals('producto')))
        .get();
    expect(outbox.map((e) => e.filaId).toSet(), <String>{'p1', 'p2'});
    expect(outbox.every((e) => e.operacion == 'upsert'), isTrue);
  });

  testWidgets('S2: cancelar la confirmación del lote no asigna nada',
      (tester) async {
    await insertarArticulo('a1', 'Galletitas');
    await insertarProducto('p1', nombre: 'Galletitas de chocolate');
    await insertarProducto('p2', nombre: 'Galletitas de vainilla');

    await tester.pumpWidget(envolver(SinClasificarScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('check-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('check-p2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('btn-clasificar-lote')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('destino-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final filas = await db.select(db.productos).get();
    expect(filas.every((p) => p.articuloId == null), isTrue);
    final outbox = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals('producto')))
        .get();
    expect(outbox, isEmpty);
  });

  testWidgets('S2: lote con artículo nuevo creado desde el diálogo destino',
      (tester) async {
    await insertarProducto('p1', nombre: 'Galletitas de chocolate');
    await insertarProducto('p2', nombre: 'Galletitas de vainilla');

    await tester.pumpWidget(envolver(SinClasificarScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('check-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('check-p2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('btn-clasificar-lote')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('destino-nuevo')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del artículo *'),
      'Galletitas',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();

    final articulos = await db.select(db.articulos).get();
    expect(articulos, hasLength(1));
    final filas = await db.select(db.productos).get();
    expect(filas.map((p) => p.articuloId).toSet(), <String>{articulos.single.id});
  });
}
