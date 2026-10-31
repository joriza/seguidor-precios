import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/backup.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';

/// S6 (v0.3.8): compatibilidad de backups. Un backup viejo no trae la clave
/// `pack` en las filas de producto: la importación no la exige y las filas
/// entran con pack = 1. Los backups nuevos viajan con pack como columna
/// normal y se conservan tal cual.
void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, dynamic> backupConProductos(List<Map<String, dynamic>> filas) =>
      <String, dynamic>{
        'formato': formatoBackup,
        'version': versionBackup,
        'exportado_en': '2026-01-01T00:00:00.000Z',
        'usuarios': <dynamic>[],
        'comercios': <dynamic>[],
        'articulos': <dynamic>[],
        'productos': filas,
        'precios': <dynamic>[],
        'valoraciones': <dynamic>[],
      };

  Map<String, dynamic> productoViejo(String id, {int? pack}) =>
      <String, dynamic>{
        'id': id,
        'codigoBarras': null,
        'articuloId': null,
        'nombre': 'Fideos Marca',
        'marca': 'Marca A',
        'categoria': null,
        'unidad': 'g',
        'contenidoNeto': 500,
        'origen': null,
        'notas': null,
        'creadoPor': 'u1',
        'creadoEn': '2026-01-01T00:00:00.000Z',
        'actualizadoEn': '2026-01-01T00:00:00.000Z',
        'borradoEn': null,
        // Backups viejos NO traen la clave; el test decide si la agrega.
        'pack': ?pack,
      };

  test('backup viejo sin la clave pack importa con pack = 1 (S6)', () async {
    final resumen = await importarBackup(
      db,
      jsonEncode(backupConProductos(<Map<String, dynamic>>[productoViejo('p1')])),
    );

    expect(resumen.insertadas, 1);
    final producto = await (db.select(db.productos)
          ..where((p) => p.id.equals('p1')))
        .getSingle();
    expect(producto.nombre, 'Fideos Marca');
    expect(producto.contenidoNeto, 500);
    expect(producto.pack, 1);
  });

  test('backup nuevo con pack distinto de 1 se importa sin alterarlo',
      () async {
    final resumen = await importarBackup(
      db,
      jsonEncode(backupConProductos(
        <Map<String, dynamic>>[productoViejo('p2', pack: 10)],
      )),
    );

    expect(resumen.insertadas, 1);
    final producto = await (db.select(db.productos)
          ..where((p) => p.id.equals('p2')))
        .getSingle();
    expect(producto.pack, 10);
  });

  test('exportarBackup incluye pack como columna normal', () async {
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p3',
            nombre: 'Harina',
            unidad: 'kg',
            contenidoNeto: const Value(1),
            pack: const Value(6),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00.000Z',
            actualizadoEn: '2026-01-01T00:00:00.000Z',
          ),
        );

    final backup = await exportarBackup(db);
    final productos = backup['productos'] as List<dynamic>;
    expect((productos.single as Map<String, dynamic>)['pack'], 6);
  });
}
