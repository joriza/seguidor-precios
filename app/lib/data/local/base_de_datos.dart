import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tablas.dart';

part 'base_de_datos.g.dart';

/// Base local (fuente de verdad del dispositivo) — esquema v2 según
/// docs/modelo-de-datos.md. Append-only en `precios` se garantiza en la
/// capa de datos: no se exponen update/delete para esa tabla.
/// v2 (v0.1.5): agrega `valoraciones` (valoración personal por usuario).
@DriftDatabase(tables: [
  Articulos,
  Productos,
  Comercios,
  Precios,
  Usuarios,
  Valoraciones,
])
class BaseDeDatos extends _$BaseDeDatos {
  /// Instancia de producción: archivo en el directorio de documentos.
  BaseDeDatos() : super(_abrir());

  /// Instancia en memoria para tests.
  BaseDeDatos.memoria() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v1 → v2: la tabla valoraciones es nueva; las existentes no
          // cambian (sin pérdida de datos en la actualización).
          if (from < 2) {
            await m.createTable(valoraciones);
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
