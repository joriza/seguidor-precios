import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';

/// Migración v4 → v5 (v0.3.8, S1/S6): el producto gana la columna `pack`
/// (INTEGER NOT NULL DEFAULT 1) = cuántas unidades del contenido neto trae
/// la presentación. Las filas existentes quedan intactas con pack = 1;
/// el pack sirve SOLO para normalizar el precio (S2).
void main() {
  // DDL fiel del esquema v4 (datos v2 + tablas de sync v3), previo a la
  // apertura, para que drift ejecute la migración onUpgrade(from: 4, to: 5)
  // contra datos reales (patrón de migracion_v3_test / migracion_v4_test).
  const ddlV4 = [
    'CREATE TABLE articulos (id TEXT NOT NULL PRIMARY KEY, nombre TEXT NOT NULL, categoria TEXT NULL, unidad_base TEXT NOT NULL, creado_por TEXT NOT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL, borrado_en TEXT NULL)',
    'CREATE TABLE usuarios (id TEXT NOT NULL PRIMARY KEY, etiqueta TEXT NOT NULL, auth_uid TEXT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL)',
    'CREATE TABLE productos (id TEXT NOT NULL PRIMARY KEY, codigo_barras TEXT NULL UNIQUE, articulo_id TEXT NULL REFERENCES articulos (id), nombre TEXT NOT NULL, marca TEXT NULL, categoria TEXT NULL, unidad TEXT NOT NULL, contenido_neto REAL NULL, origen TEXT NULL, notas TEXT NULL, creado_por TEXT NOT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL, borrado_en TEXT NULL)',
    'CREATE TABLE comercios (id TEXT NOT NULL PRIMARY KEY, nombre TEXT NOT NULL, tipo TEXT NULL, direccion TEXT NULL, creado_por TEXT NOT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL, borrado_en TEXT NULL)',
    'CREATE TABLE precios (id TEXT NOT NULL PRIMARY KEY, producto_id TEXT NOT NULL REFERENCES productos (id), comercio_id TEXT NOT NULL REFERENCES comercios (id), precio REAL NOT NULL CHECK (precio > 0), fecha_toma TEXT NOT NULL, cargado_por TEXT NOT NULL, cargado_en TEXT NOT NULL)',
    'CREATE TABLE valoraciones (id TEXT NOT NULL PRIMARY KEY, usuario_id TEXT NOT NULL REFERENCES usuarios (id), producto_id TEXT NOT NULL REFERENCES productos (id), gusto TEXT NULL, observacion TEXT NULL, creado_en TEXT NOT NULL, actualizado_en TEXT NOT NULL)',
    'CREATE TABLE outbox (tabla TEXT NOT NULL, fila_id TEXT NOT NULL, operacion TEXT NOT NULL, encolado_en TEXT NOT NULL, PRIMARY KEY (tabla, fila_id))',
    'CREATE TABLE cursores_sync (tabla TEXT NOT NULL PRIMARY KEY, cursor TEXT NOT NULL)',
    'CREATE TABLE estado_sync (id TEXT NOT NULL PRIMARY KEY, ultimo_sync_exitoso TEXT NULL)',
  ];

  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria(
      executor: NativeDatabase.memory(
        setup: (dbSinDrift) {
          for (final ddl in ddlV4) {
            dbSinDrift.execute(ddl);
          }
          dbSinDrift.execute('PRAGMA user_version = 4');
          dbSinDrift.execute(
            "INSERT INTO usuarios VALUES ('u1', 'Nadia', NULL, '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z')",
          );
          dbSinDrift.execute(
            "INSERT INTO articulos VALUES ('a1', 'Fideos', NULL, 'kg', 'u1', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', NULL)",
          );
          dbSinDrift.execute(
            "INSERT INTO productos VALUES ('p1', '7791234567890', 'a1', 'Fideos Marca', 'Marca A', NULL, 'g', 500, 'semilla', NULL, 'u1', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', NULL)",
          );
          dbSinDrift.execute(
            "INSERT INTO comercios VALUES ('c1', 'Almacén', 'almacen', NULL, 'u1', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', NULL)",
          );
          dbSinDrift.execute(
            "INSERT INTO precios VALUES ('pr1', 'p1', 'c1', 7500, '2026-01-02', 'u1', '2026-01-02T10:00:00.000Z')",
          );
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('migrar v4 → v5 conserva las filas y les deja pack = 1', () async {
    // Datos v4 intactos tras la migración.
    final producto = await (db.select(db.productos)
          ..where((p) => p.id.equals('p1')))
        .getSingle();
    expect(producto.nombre, 'Fideos Marca');
    expect(producto.codigoBarras, '7791234567890');
    expect(producto.contenidoNeto, 500);
    expect(producto.marca, 'Marca A');
    // S1/S6: la fila vieja queda con el default pack = 1.
    expect(producto.pack, 1);

    final precio = await (db.select(db.precios)
          ..where((p) => p.id.equals('pr1')))
        .getSingle();
    expect(precio.precio, 7500);

    // El esquema quedó en la versión nueva.
    expect(db.schemaVersion, 5);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], 5);
  });

  test('un alta posterior a la migración usa pack = 1 sin indicarlo', () async {
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p-nuevo',
            nombre: 'Unitario',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-03T00:00:00.000Z',
            actualizadoEn: '2026-01-03T00:00:00.000Z',
          ),
        );
    final producto = await (db.select(db.productos)
          ..where((p) => p.id.equals('p-nuevo')))
        .getSingle();
    expect(producto.pack, 1);
  });
}
