import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'identidad.dart';
import 'local/base_de_datos.dart';
import 'sync/cola_saliente.dart';

/// Repositorio de productos (hooks de encolado de T4, regla de sync 2):
/// la escritura es local primero (R3) y todo alta o cambio queda encolado
/// en el outbox para la próxima sync. El dedup de EAN es asunto del push
/// (regla de sync 6): acá solo se valida la unicidad local, que si falla
/// lanza y la pantalla muestra su error de siempre.

/// Da de alta un producto y devuelve la fila guardada.
Future<Producto> altaProducto(
  BaseDeDatos db, {
  required String nombre,
  String? codigoBarras,
  String? marca,
  required String unidad,
  double? contenidoNeto,
  String? categoria,
  String? articuloId,
  String? id,
  DateTime? ahora,
}) async {
  final usuario = await usuarioActual(db);
  final String nuevoId = id ?? const Uuid().v4();
  final DateTime momento = ahora ?? DateTime.now();
  final String cuando = momento.toUtc().toIso8601String();
  await db.into(db.productos).insert(
        ProductosCompanion.insert(
          id: nuevoId,
          codigoBarras: Value(codigoBarras),
          nombre: nombre,
          marca: Value(marca),
          unidad: unidad,
          contenidoNeto: Value(contenidoNeto),
          categoria: Value(categoria),
          articuloId: Value(articuloId),
          creadoPor: usuario.id,
          creadoEn: cuando,
          actualizadoEn: cuando,
        ),
      );
  await encolarUpsert(db, 'producto', nuevoId, ahora: momento);
  return await (db.select(db.productos)..where((t) => t.id.equals(nuevoId)))
      .getSingle();
}

/// Edita un producto existente y devuelve la fila actualizada.
Future<Producto> editarProducto(
  BaseDeDatos db,
  String id, {
  String? codigoBarras,
  required String nombre,
  String? marca,
  required String unidad,
  double? contenidoNeto,
  String? categoria,
  String? articuloId,
  DateTime? ahora,
}) async {
  final DateTime momento = ahora ?? DateTime.now();
  await (db.update(db.productos)..where((t) => t.id.equals(id))).write(
        ProductosCompanion(
          codigoBarras: Value(codigoBarras),
          nombre: Value(nombre),
          marca: Value(marca),
          unidad: Value(unidad),
          contenidoNeto: Value(contenidoNeto),
          categoria: Value(categoria),
          articuloId: Value(articuloId),
          actualizadoEn: Value(momento.toUtc().toIso8601String()),
        ),
      );
  await encolarUpsert(db, 'producto', id, ahora: momento);
  return await (db.select(db.productos)..where((t) => t.id.equals(id)))
      .getSingle();
}
