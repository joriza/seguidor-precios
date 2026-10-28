import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'identidad.dart';
import 'local/base_de_datos.dart';
import 'sync/cola_saliente.dart';

/// Repositorio de comercios (hooks de encolado de T4, regla de sync 2):
/// la escritura es local primero (R3) y el alta queda encolada en el
/// outbox para la próxima sync.

/// Da de alta un comercio y devuelve la fila guardada.
Future<Comercio> altaComercio(
  BaseDeDatos db, {
  required String nombre,
  String? tipo,
  String? direccion,
  String? id,
  DateTime? ahora,
}) async {
  final usuario = await usuarioActual(db);
  final String nuevoId = id ?? const Uuid().v4();
  final DateTime momento = ahora ?? DateTime.now();
  final String cuando = momento.toUtc().toIso8601String();
  await db.into(db.comercios).insert(
        ComerciosCompanion.insert(
          id: nuevoId,
          nombre: nombre,
          tipo: Value(tipo),
          direccion: Value(direccion),
          creadoPor: usuario.id,
          creadoEn: cuando,
          actualizadoEn: cuando,
        ),
      );
  await encolarUpsert(db, 'comercio', nuevoId, ahora: momento);
  return await (db.select(db.comercios)..where((t) => t.id.equals(nuevoId)))
      .getSingle();
}
