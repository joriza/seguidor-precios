/// v0.1.5: valoración personal del producto — observación breve + me gusta /
/// no me gusta (neutro por defecto). Por usuario: en la etapa colaborativa
/// cada aportante conserva la suya (Fase 2 ponderará con las ajenas).
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'identidad.dart';
import 'local/base_de_datos.dart';

/// La valoración del usuario actual para un producto, o null si no cargó
/// ninguna (neutro).
Future<Valoracion?> valoracionDe(BaseDeDatos db, String productoId) async {
  final usuario = await usuarioActual(db);
  final filas = await (db.select(db.valoraciones)
        ..where((v) =>
            v.usuarioId.equals(usuario.id) &
            v.productoId.equals(productoId)))
      .get();
  return filas.isEmpty ? null : filas.first;
}

/// Guarda la valoración del usuario actual (upsert). Si no hay gusto ni
/// observación, elimina la fila: volver a neutro deja cero datos.
Future<void> guardarValoracion(
  BaseDeDatos db,
  String productoId, {
  required String? gusto,
  required String? observacion,
}) async {
  assert(gusto == null || gusto == 'si' || gusto == 'no');
  final String texto = (observacion ?? '').trim();
  final String ahora = DateTime.now().toUtc().toIso8601String();
  final bool sinDatos = gusto == null && texto.isEmpty;
  final usuario = await usuarioActual(db);

  final existentes = await (db.select(db.valoraciones)
        ..where((v) =>
            v.usuarioId.equals(usuario.id) &
            v.productoId.equals(productoId)))
      .get();

  if (sinDatos) {
    if (existentes.isNotEmpty) {
      await (db.delete(db.valoraciones)
            ..where((v) =>
                v.usuarioId.equals(usuario.id) &
                v.productoId.equals(productoId)))
          .go();
    }
    return;
  }

  if (existentes.isEmpty) {
    await db.into(db.valoraciones).insert(
          ValoracionesCompanion.insert(
            id: const Uuid().v4(),
            usuarioId: usuario.id,
            productoId: productoId,
            gusto: Value(gusto),
            observacion: Value(texto.isEmpty ? null : texto),
            creadoEn: ahora,
            actualizadoEn: ahora,
          ),
        );
    return;
  }

  await (db.update(db.valoraciones)
        ..where((v) => v.id.equals(existentes.first.id)))
      .write(
        ValoracionesCompanion(
          gusto: Value(gusto),
          observacion: Value(texto.isEmpty ? null : texto),
          actualizadoEn: Value(ahora),
        ),
      );
}
