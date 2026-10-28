import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/articulos.dart';
import 'package:seguidor_precios/data/comercios.dart';
import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/precios.dart';
import 'package:seguidor_precios/data/productos.dart';

/// Hooks de encolado de T4 (regla de sync 2): toda alta/cambio local de
/// artículo, producto, comercio o precio queda en el outbox además de en
/// su tabla. Los repos de identidad y valoraciones ya lo hacían (T2).
void main() {
  test('altaProducto guarda la fila con el usuario actual y encola', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final usuario = await crearUsuarioConEtiqueta(db, 'Vale');

    final producto = await altaProducto(
      db,
      nombre: 'Yerba Playadito 1 kg',
      codigoBarras: '7790001001001',
      marca: 'Playadito',
      unidad: 'g',
      contenidoNeto: 1000,
      categoria: 'almacen',
    );

    final filas = await db.select(db.productos).get();
    expect(filas, hasLength(1));
    expect(filas.single.id, producto.id);
    expect(filas.single.nombre, 'Yerba Playadito 1 kg');
    expect(filas.single.creadoPor, usuario.id);
    expect(filas.single.contenidoNeto, 1000);

    final outbox = await db.select(db.outbox).get();
    final delProducto = outbox
        .where((e) => e.tabla == 'producto' && e.filaId == producto.id)
        .toList();
    expect(delProducto, hasLength(1));
    expect(delProducto.single.operacion, 'upsert');
  });

  test('altaProducto sin código de barras ni marca: fila con nulls', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);

    final producto = await altaProducto(db, nombre: 'Pan por kilo', unidad: 'kg');

    expect(producto.codigoBarras, isNull);
    expect(producto.marca, isNull);
    expect(producto.categoria, isNull);
  });

  test('editarProducto actualiza los campos y deja una sola entrada', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    await crearUsuarioConEtiqueta(db, 'Vale');
    final producto = await altaProducto(db, nombre: 'Nombre viejo', unidad: 'g');

    final editado = await editarProducto(
      db,
      producto.id,
      nombre: 'Nombre nuevo',
      unidad: 'g',
      marca: 'La Marca',
    );

    expect(editado.nombre, 'Nombre nuevo');
    expect(editado.marca, 'La Marca');

    final entradas = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals('producto') &
              e.filaId.equals(producto.id)))
        .get();
    expect(entradas, hasLength(1));
  });

  test('altaComercio guarda y encola en outbox', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final usuario = await crearUsuarioConEtiqueta(db, 'Vale');

    final comercio = await altaComercio(
      db,
      nombre: 'El Almacén',
      tipo: 'almacen',
      direccion: 'Av. Siempre Viva 742',
    );

    final filas = await db.select(db.comercios).get();
    expect(filas.single.id, comercio.id);
    expect(filas.single.nombre, 'El Almacén');
    expect(filas.single.creadoPor, usuario.id);
    expect(filas.single.direccion, 'Av. Siempre Viva 742');

    final outbox = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals('comercio')))
        .get();
    expect(outbox, hasLength(1));
    expect(outbox.single.filaId, comercio.id);
  });

  test('registrarPrecio guarda el precio con atribución y encola', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final usuario = await crearUsuarioConEtiqueta(db, 'Vale');
    final producto = await altaProducto(db, nombre: 'Arroz', unidad: 'kg');
    final comercio = await altaComercio(db, nombre: 'El Chino');

    final precio = await registrarPrecio(
      db,
      productoId: producto.id,
      comercioId: comercio.id,
      precio: 1250.50,
      fechaToma: '2026-11-05',
    );

    final filas = await db.select(db.precios).get();
    expect(filas.single.id, precio.id);
    expect(filas.single.precio, 1250.50);
    expect(filas.single.cargadoPor, usuario.id);
    expect(filas.single.fechaToma, '2026-11-05');
    expect(DateTime.parse(filas.single.cargadoEn).isUtc, isTrue);

    final outbox = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals('precio')))
        .get();
    expect(outbox, hasLength(1));
    expect(outbox.single.filaId, precio.id);
  });

  test('altaArticulo guarda con unidad base y encola; renombrar actualiza',
      () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final usuario = await crearUsuarioConEtiqueta(db, 'Vale');

    final articulo = await altaArticulo(db, nombre: 'Harinas', unidadBase: 'kg');

    final filas = await db.select(db.articulos).get();
    expect(filas.single.id, articulo.id);
    expect(filas.single.nombre, 'Harinas');
    expect(filas.single.unidadBase, 'kg');
    expect(filas.single.creadoPor, usuario.id);

    final renombrado =
        await renombrarArticulo(db, articulo.id, nombre: 'Harinas y premezclas');
    expect(renombrado.nombre, 'Harinas y premezclas');
    expect(renombrado.unidadBase, 'kg'); // la unidad base no cambia (S6)

    final entradas = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals('articulo') &
              e.filaId.equals(articulo.id)))
        .get();
    expect(entradas, hasLength(1));
  });
}
