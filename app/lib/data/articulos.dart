import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'identidad.dart';
import 'local/base_de_datos.dart';
import 'sync/cola_saliente.dart';

/// Repositorio de artículos (hooks de encolado de T4, regla de sync 2):
/// la escritura es local primero (R3) y todo alta o cambio queda encolado
/// en el outbox para la próxima sync. La unidad base se define al crear y
/// no cambia después (S6: estabilidad de las comparaciones).

/// Da de alta un artículo y devuelve la fila guardada.
Future<Articulo> altaArticulo(
  BaseDeDatos db, {
  required String nombre,
  required String unidadBase,
  String? id,
  DateTime? ahora,
}) async {
  final usuario = await usuarioActual(db);
  final String nuevoId = id ?? const Uuid().v4();
  final DateTime momento = ahora ?? DateTime.now();
  final String cuando = momento.toUtc().toIso8601String();
  await db.into(db.articulos).insert(
        ArticulosCompanion.insert(
          id: nuevoId,
          nombre: nombre,
          unidadBase: unidadBase,
          creadoPor: usuario.id,
          creadoEn: cuando,
          actualizadoEn: cuando,
        ),
      );
  await encolarUpsert(db, 'articulo', nuevoId, ahora: momento);
  return await (db.select(db.articulos)..where((t) => t.id.equals(nuevoId)))
      .getSingle();
}

/// Renombra un artículo existente (única edición permitida: S6) y encola.
Future<Articulo> renombrarArticulo(
  BaseDeDatos db,
  String id, {
  required String nombre,
  DateTime? ahora,
}) async {
  final DateTime momento = ahora ?? DateTime.now();
  await (db.update(db.articulos)..where((t) => t.id.equals(id))).write(
        ArticulosCompanion(
          nombre: Value(nombre),
          actualizadoEn: Value(momento.toUtc().toIso8601String()),
        ),
      );
  await encolarUpsert(db, 'articulo', id, ahora: momento);
  return await (db.select(db.articulos)..where((t) => t.id.equals(id)))
      .getSingle();
}
