import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';

/// Migración v3 → v4 (T2 correctivo de campo): las filas nacidas antes de
/// v0.2.0 no pasaron por los hooks de encolado y nunca entrarían a la sync
/// (caso real: precio → FK contra un comercio que el servidor no conocía).
/// El backfill encola una sola vez toda fila pre-existente de las tablas de
/// sync, en orden de dependencias.
void main() {
  // DDL fiel del esquema v2, previo a la apertura, para que drift ejecute
  // la migración onUpgrade(from: 2, to: 4) contra datos reales.
  const ddlV2 = [
    'CREATE TABLE articulos (id TEXT NOT NULL PRIMARY KEY, nombre TEXT NOT NULL, categoria TEXT NULL, unidad_base TEXT NOT NULL, creado_por TEXT NOT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL, borrado_en TEXT NULL)',
    'CREATE TABLE usuarios (id TEXT NOT NULL PRIMARY KEY, etiqueta TEXT NOT NULL, auth_uid TEXT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL)',
    'CREATE TABLE productos (id TEXT NOT NULL PRIMARY KEY, codigo_barras TEXT NULL UNIQUE, articulo_id TEXT NULL REFERENCES articulos (id), nombre TEXT NOT NULL, marca TEXT NULL, categoria TEXT NULL, unidad TEXT NOT NULL, contenido_neto REAL NULL, origen TEXT NULL, notas TEXT NULL, creado_por TEXT NOT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL, borrado_en TEXT NULL)',
    'CREATE TABLE comercios (id TEXT NOT NULL PRIMARY KEY, nombre TEXT NOT NULL, tipo TEXT NULL, direccion TEXT NULL, creado_por TEXT NOT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL, borrado_en TEXT NULL)',
    'CREATE TABLE precios (id TEXT NOT NULL PRIMARY KEY, producto_id TEXT NOT NULL REFERENCES productos (id), comercio_id TEXT NOT NULL REFERENCES comercios (id), precio REAL NOT NULL CHECK (precio > 0), fecha_toma TEXT NOT NULL, cargado_por TEXT NOT NULL, cargado_en TEXT NOT NULL)',
    'CREATE TABLE valoraciones (id TEXT NOT NULL PRIMARY KEY, usuario_id TEXT NOT NULL REFERENCES usuarios (id), producto_id TEXT NOT NULL REFERENCES productos (id), gusto TEXT NULL, observacion TEXT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL)',
  ];

  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria(
      executor: NativeDatabase.memory(
        setup: (dbSinDrift) {
          for (final ddl in ddlV2) {
            dbSinDrift.execute(ddl);
          }
          dbSinDrift.execute('PRAGMA user_version = 2');
          dbSinDrift.execute(
            "INSERT INTO articulos VALUES ('a1', 'Mayonesas', NULL, 'kg', 'u1', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', NULL)",
          );
          dbSinDrift.execute(
            "INSERT INTO usuarios VALUES ('u1', 'Nadia', NULL, '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z')",
          );
          dbSinDrift.execute(
            "INSERT INTO productos VALUES ('p1', '7791234567890', NULL, 'Mayonesa', 'Natura', NULL, 'g', 500, 'semilla', NULL, 'u1', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', NULL)",
          );
          dbSinDrift.execute(
            "INSERT INTO comercios VALUES ('c1', 'Almacén', 'almacen', NULL, 'u1', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', NULL)",
          );
          dbSinDrift.execute(
            "INSERT INTO precios VALUES ('pr1', 'p1', 'c1', 1500, '2026-01-02', 'u1', '2026-01-02T10:00:00.000Z')",
          );
          dbSinDrift.execute(
            "INSERT INTO valoraciones VALUES ('v1', 'u1', 'p1', 'si', NULL, '2026-01-03T00:00:00.000Z', '2026-01-03T00:00:00.000Z')",
          );
        },
      ),
    );
  });

  test('el backfill encola toda fila pre-existente de las tablas de sync', () async {
    final pendientes = await db.select(db.outbox).get();
    final claves = pendientes.map((e) => '${e.tabla}:${e.filaId}').toSet();

    expect(
      claves,
      containsAll(<String>[
        'usuario:u1',
        'articulo:a1',
        'producto:p1',
        'comercio:c1',
        'precio:pr1',
        'valoracion:v1',
      ]),
    );
    expect(pendientes.every((e) => e.operacion == 'upsert'), isTrue);
  });
}
