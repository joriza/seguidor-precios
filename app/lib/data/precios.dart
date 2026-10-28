import 'package:uuid/uuid.dart';

import 'identidad.dart';
import 'local/base_de_datos.dart';
import 'sync/cola_saliente.dart';

/// Repositorio de precios (hooks de encolado de T4, regla de sync 2):
/// la escritura es local primero (R3) y cada precio queda encolado en el
/// outbox para la próxima sync. Append-only: no hay edición ni baja de un
/// precio ya registrado (regla de sync 4).

/// Registra el precio de un producto en un comercio y devuelve la fila.
Future<Precio> registrarPrecio(
  BaseDeDatos db, {
  required String productoId,
  required String comercioId,
  required double precio,
  required String fechaToma,
  String? id,
  DateTime? ahora,
}) async {
  final usuario = await usuarioActual(db);
  final String nuevoId = id ?? const Uuid().v4();
  final DateTime momento = ahora ?? DateTime.now();
  await db.into(db.precios).insert(
        PreciosCompanion.insert(
          id: nuevoId,
          productoId: productoId,
          comercioId: comercioId,
          precio: precio,
          fechaToma: fechaToma,
          cargadoPor: usuario.id,
          cargadoEn: momento.toUtc().toIso8601String(),
        ),
      );
  await encolarUpsert(db, 'precio', nuevoId, ahora: momento);
  return await (db.select(db.precios)..where((t) => t.id.equals(nuevoId)))
      .getSingle();
}
