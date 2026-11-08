import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';
import 'package:seguidor_precios/data/categorias.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';

/// v0.3.17 (S3): pass retroactivo LOCAL de producto.categoria al iniciar
/// la app — idempotente, sin outbox, no-op cuando ya todo es canónico.
/// El prefijo de guión bajo marca pruebas de fase (patrón del repo).
void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() => db.close());

  Future<void> productoConCategoria(String id, String? categoria) async {
    await db.into(db.productos).insert(ProductosCompanion.insert(
          id: id,
          nombre: 'Producto $id',
          unidad: 'g',
          categoria: Value(categoria),
          creadoPor: 'u1',
          creadoEn: '2026-01-01T00:00:00',
          actualizadoEn: '2026-01-01T00:00:00',
        ));
  }

  Future<List<String>> categoriasGuardadas() async {
    final filas = await (db.select(db.productos)
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
    return filas.map((Producto f) => f.categoria ?? '(null)').toList();
  }

  test('normaliza variantes crudas y deja desconocidas tal cual (S6)',
      () async {
    await productoConCategoria('p1', 'guisantes');
    await productoConCategoria('p2', 'Guisantes, Legumbres');
    await productoConCategoria('p3', 'Papas'); // desconocida: no se toca
    await productoConCategoria('p4', null);
    await productoConCategoria('p5', 'en:chícharos');

    final int actualizadas = await normalizarCategoriasGuardadas(db);

    expect(actualizadas, 3);
    expect(await categoriasGuardadas(), <String>[
      'arvejas',
      'arvejas, Legumbres',
      'Papas',
      '(null)',
      'arvejas',
    ]);
  });

  test('idempotente: segunda pasada no actualiza nada', () async {
    await productoConCategoria('p1', 'guisantes');
    await productoConCategoria('p2', 'Papas');

    expect(await normalizarCategoriasGuardadas(db), 1);
    expect(await normalizarCategoriasGuardadas(db), 0);
    expect(await categoriasGuardadas(), <String>['arvejas', 'Papas']);
  });

  test('NO encola outbox (S3: el servidor converge al re-editar)', () async {
    await productoConCategoria('p1', 'guisantes');

    await normalizarCategoriasGuardadas(db);
    await normalizarCategoriasGuardadas(db);

    final outbox = await db.select(db.outbox).get();
    expect(outbox, isEmpty);
  });

  test('sin variantes crudas es no-op barato (cero updates)', () async {
    await productoConCategoria('p1', 'Papas');
    await productoConCategoria('p2', null);

    expect(await normalizarCategoriasGuardadas(db), 0);
    expect(await categoriasGuardadas(), <String>['Papas', '(null)']);
    expect(await db.select(db.outbox).get(), isEmpty);
  });

  testWidgets('el arranque de la app ejecuta el pass (S3)', (tester) async {
    await productoConCategoria('p1', 'guisantes');

    await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
    await tester.pumpAndSettle();

    // Drenar el async real del pass (unawaited, sin frames propios).
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 200),
        ));

    final fila = await (db.select(db.productos)
          ..where((t) => t.id.equals('p1')))
        .getSingle();
    expect(fila.categoria, 'arvejas');
  });
}
