import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tablas.dart';

part 'base_de_datos.g.dart';

/// Base local (fuente de verdad del dispositivo) — esquema v1 según
/// docs/modelo-de-datos.md. Append-only en `precios` se garantiza en la
/// capa de datos: no se exponen update/delete para esa tabla.
@DriftDatabase(tables: [Articulos, Productos, Comercios, Precios, Usuarios])
class BaseDeDatos extends _$BaseDeDatos {
  /// Instancia de producción: archivo en el directorio de documentos.
  BaseDeDatos() : super(_abrir());

  /// Instancia en memoria para tests.
  BaseDeDatos.memoria() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
