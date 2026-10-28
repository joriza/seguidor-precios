import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tablas.dart';

part 'base_de_datos.g.dart';

/// Base local (fuente de verdad del dispositivo) — esquema v3 según
/// docs/modelo-de-datos.md. Append-only en `precios` se garantiza en la
/// capa de datos: no se exponen update/delete para esa tabla.
/// v2 (v0.1.5): agrega `valoraciones` (valoración personal por usuario).
/// v3 (Fase 2, T2): agrega las tablas de sync — outbox, cursores por tabla
/// y marca global de última sync exitosa (reglas de sync 2, 3 y 8).
@DriftDatabase(tables: [
  Articulos,
  Productos,
  Comercios,
  Precios,
  Usuarios,
  Valoraciones,
  Outbox,
  CursoresSync,
  EstadoSync,
])
class BaseDeDatos extends _$BaseDeDatos {
  /// Instancia de producción: archivo en el directorio de documentos.
  BaseDeDatos() : super(_abrir());

  /// Instancia en memoria para tests. Acepta un [executor] alternativo
  /// (por ejemplo, un NativeDatabase con `setup` para probar migraciones).
  BaseDeDatos.memoria({QueryExecutor? executor})
      : super(executor ?? NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v1 → v2: la tabla valoraciones es nueva; las existentes no
          // cambian (sin pérdida de datos en la actualización).
          if (from < 2) {
            await m.createTable(valoraciones);
          }
          // v2 → v3: tablas de sync nuevas; las de datos no cambian.
          if (from < 3) {
            await m.createTable(outbox);
            await m.createTable(cursoresSync);
            await m.createTable(estadoSync);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _abrir() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final archivo = File(p.join(dir.path, 'seguidor_precios.sqlite'));
    return NativeDatabase.createInBackground(archivo);
  });
}
