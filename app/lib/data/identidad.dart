import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'local/base_de_datos.dart';

/// S14 (R17): identidad del aportante — etiqueta elegida en el dispositivo.
///
/// Cada instalación guarda un único usuario con su etiqueta; los precios y
/// productos cargados quedan atribuidos a su id (que viaja con cada dato).
/// El login con enlace mágico queda diferido a Fase 3 (R17).

/// Devuelve el usuario de esta instalación; si no existe (por ejemplo, una
/// base creada antes de T14), crea uno anónimo en el momento.
Future<Usuario> usuarioActual(BaseDeDatos db) async {
  final existentes = await db.select(db.usuarios).get();
  if (existentes.isNotEmpty) return existentes.first;

  final String ahora = DateTime.now().toUtc().toIso8601String();
  await db.into(db.usuarios).insert(
        UsuariosCompanion.insert(
          id: const Uuid().v4(),
          etiqueta: 'Anónimo',
          creadoEn: ahora,
          actualizadoEn: ahora,
        ),
      );
  return (await db.select(db.usuarios).get()).single;
}

/// Usuario de esta instalación si existe, sin crear nada (lectura segura
/// para pantallas que solo muestran la etiqueta).
Future<Usuario?> leerUsuario(BaseDeDatos db) async {
  final existentes = await db.select(db.usuarios).get();
  return existentes.isEmpty ? null : existentes.first;
}

/// ¿Hay usuario guardado en esta instalación? (sin crear nada).
Future<bool> hayUsuario(BaseDeDatos db) async =>
    (await db.select(db.usuarios).get()).isNotEmpty;

/// Guarda la etiqueta elegida en el primer inicio.
Future<Usuario> crearUsuarioConEtiqueta(BaseDeDatos db, String etiqueta) async {
  final String ahora = DateTime.now().toUtc().toIso8601String();
  await db.into(db.usuarios).insert(
        UsuariosCompanion.insert(
          id: const Uuid().v4(),
          etiqueta: etiqueta,
          creadoEn: ahora,
          actualizadoEn: ahora,
        ),
      );
  return (await db.select(db.usuarios).get()).single;
}

/// Cambia la etiqueta del aportante (R17: desde ajustes, sin conexión).
Future<void> cambiarEtiqueta(BaseDeDatos db, String etiqueta) async {
  final Usuario u = await usuarioActual(db);
  await (db.update(db.usuarios)..where((t) => t.id.equals(u.id))).write(
    UsuariosCompanion(
      etiqueta: Value(etiqueta),
      actualizadoEn: Value(DateTime.now().toUtc().toIso8601String()),
    ),
  );
}
