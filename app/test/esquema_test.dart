import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertarArticulo(
    BaseDeDatos db, {
    String id = 'a1',
    String nombre = 'Mayonesa',
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
    BaseDeDatos db, {
    required String id,
    String? codigoBarras,
    String? articuloId,
    String nombre = 'Mayonesa Marca A',
    String unidad = 'g',
    double? contenidoNeto,
  }) {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: id,
            nombre: nombre,
            unidad: unidad,
            codigoBarras: Value(codigoBarras),
            articuloId: Value(articuloId),
            contenidoNeto: Value(contenidoNeto),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  Future<void> insertarComercio(BaseDeDatos db, {String id = 'c1'}) {
    return db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: id,
            nombre: 'El Almacén',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  Future<void> insertarPrecio(
    BaseDeDatos db, {
    String id = 'pr1',
    required String productoId,
    required String comercioId,
    double precio = 1500,
    String fecha = '2026-01-02',
  }) {
    return db.into(db.precios).insert(
          PreciosCompanion.insert(
            id: id,
            productoId: productoId,
            comercioId: comercioId,
            precio: precio,
            fechaToma: fecha,
            cargadoPor: 'u1',
            cargadoEn: '2026-01-02T10:00:00',
          ),
        );
  }

  test('inserta artículo, producto con EAN y precio; los recupera', () async {
    await insertarArticulo(db);
    await insertarProducto(db, id: 'p1', codigoBarras: '7790001001001', articuloId: 'a1');
    await insertarComercio(db);
    await insertarPrecio(db, productoId: 'p1', comercioId: 'c1');

    final productos = await db.select(db.productos).get();
    expect(productos, hasLength(1));
    expect(productos.single.codigoBarras, '7790001001001');

    final precios = await db.select(db.precios).get();
    expect(precios, hasLength(1));
    expect(precios.single.precio, 1500);
    expect(precios.single.fechaToma, '2026-01-02');
  });

  test('permite varios productos sin EAN (NULL no ocupa el índice único)', () async {
    await insertarProducto(db, id: 'p1');
    await insertarProducto(db, id: 'p2', nombre: 'Asado');
    final productos = await db.select(db.productos).get();
    expect(productos, hasLength(2));
  });

  test('rechaza EAN duplicado', () async {
    await insertarProducto(db, id: 'p1', codigoBarras: '7790001001001');
    await expectLater(
      insertarProducto(db, id: 'p2', codigoBarras: '7790001001001'),
      throwsA(anything),
    );
  });

  test('rechaza precio <= 0 (CHECK)', () async {
    await insertarProducto(db, id: 'p1');
    await insertarComercio(db);
    await expectLater(insertarPrecio(db, productoId: 'p1', comercioId: 'c1', precio: 0), throwsA(anything));
    await expectLater(insertarPrecio(db, productoId: 'p1', comercioId: 'c1', precio: -5), throwsA(anything));
  });

  test('rechaza precio con producto inexistente (foreign keys ON)', () async {
    await insertarComercio(db);
    await expectLater(
      insertarPrecio(db, productoId: 'no-existe', comercioId: 'c1'),
      throwsA(anything),
    );
  });

  test('usuario guarda etiqueta de aportante y auth_uid nullable', () async {
    await db.into(db.usuarios).insert(
          UsuariosCompanion.insert(
            id: 'u1',
            etiqueta: 'Jorge',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    final usuarios = await db.select(db.usuarios).get();
    expect(usuarios.single.etiqueta, 'Jorge');
    expect(usuarios.single.authUid, isNull);
  });
}
