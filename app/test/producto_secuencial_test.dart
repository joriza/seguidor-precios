import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/codigo_interno.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';

/// S1 (v0.3.5, diseño v2): código interno `S-<TOK>-<NNNN>` para productos
/// sin EAN. TOK = 2 caracteres A-Z0-9 generados UNA vez por instalación y
/// persistidos al estilo del archivo de sesión; NNNN = contador por
/// instalación (max existente para ESE TOK + 1, parseo robusto: valores
/// malformados o de otra instalación no participan ni rompen la numeración).
void main() {
  Future<void> insertarProducto(BaseDeDatos db, String? codigo) {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p-${codigo ?? 'sin-codigo'}',
            codigoBarras: Value(codigo),
            nombre: 'Producto',
            unidad: 'g',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  test('base sin productos: devuelve S-QT-0001', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);

    expect(await proximoCodigoInterno(db, tok: 'QT'), 'S-QT-0001');
  });

  test('cuenta solo su TOK y solo valores válidos: máximo propio + 1',
      () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);

    await insertarProducto(db, 'S-QT-0003');
    await insertarProducto(db, 'S-XY-0009'); // otra instalación: no participa
    await insertarProducto(db, 'S-QT-0007');
    // Malformados: se ignoran, no participan del máximo ni lanzan.
    await insertarProducto(db, 'S-abc-0005');
    await insertarProducto(db, 'S-QT-');
    await insertarProducto(db, 'S-QT-0001x');
    await insertarProducto(db, 'X-QT-0005');
    await insertarProducto(db, '7790001001001'); // EAN real: no participa
    // Dígitos que desbordan int: se ignora sin lanzar (parseo robusto).
    await insertarProducto(db, 'S-QT-99999999999999999999');

    expect(await proximoCodigoInterno(db, tok: 'QT'), 'S-QT-0008');
  });

  test('generarTok: 2 caracteres A-Z0-9', () {
    final RegExp patron = RegExp(r'^[A-Z0-9]{2}$');
    for (int i = 0; i < 50; i++) {
      expect(generarTok(), matches(patron));
    }
  });

  test('tokDeInstalacion: se genera una vez y se persiste en el archivo',
      () async {
    final Directory temp = await Directory.systemTemp.createTemp(
        'seguidor_tok_test_');
    addTearDown(() => temp.delete(recursive: true));

    final String primero =
        await tokDeInstalacion(directorio: temp);
    expect(primero, matches(RegExp(r'^[A-Z0-9]{2}$')));

    // Segunda llamada: mismo TOK (no se regenera).
    final String segundo = await tokDeInstalacion(directorio: temp);
    expect(segundo, primero);

    // Otra instalación (otro directorio): TOK propio e independiente.
    final Directory otra = await Directory.systemTemp
        .createTemp('seguidor_tok_test_');
    addTearDown(() => otra.delete(recursive: true));
    expect(await tokDeInstalacion(directorio: otra),
        matches(RegExp(r'^[A-Z0-9]{2}$')));
  });

  test('tokDeInstalacion: archivo corrupto o malformado se regenera',
      () async {
    final Directory temp =
        await Directory.systemTemp.createTemp('seguidor_tok_test_');
    addTearDown(() => temp.delete(recursive: true));

    // JSON inválido: regenera un TOK válido y no lanza.
    await File('${temp.path}/$nombreArchivoTok')
        .writeAsString('no-es-json{');
    expect(await tokDeInstalacion(directorio: temp),
        matches(RegExp(r'^[A-Z0-9]{2}$')));

    // JSON válido pero con TOK malformado: también regenera.
    await File('${temp.path}/$nombreArchivoTok')
        .writeAsString('{"tok": "ab!"}');
    final String tok = await tokDeInstalacion(directorio: temp);
    expect(tok, matches(RegExp(r'^[A-Z0-9]{2}$')));
    // Y queda persistido el nuevo valor.
    expect(await tokDeInstalacion(directorio: temp), tok);
  });
}
