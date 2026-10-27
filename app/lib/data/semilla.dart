import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle, AssetBundle;

import 'identidad.dart';
import 'local/base_de_datos.dart';
import 'local/importar_semilla.dart';

/// S2 (v0.1.1, R10): catálogo semilla incluido en el APK.
///
/// En el primer arranque (y siempre que la base no tenga aún productos del
/// semillero) se importa `assets/semilla/pack_semilla.json` en segundo
/// plano. La dedup por EAN hace la operación idempotente: los productos
/// borrados por el dueño no resucitan (su fila sigue existiendo) y la carga
/// manual del dueño siempre gana (T3).

const String rutaPackSemilla = 'assets/semilla/pack_semilla.json';

/// ¿Hay productos del semillero en la base?
Future<bool> haySemilla(BaseDeDatos db) async {
  final filas = await (db.select(db.productos)
        ..where((p) => p.origen.equals('semilla')))
      .get();
  return filas.isNotEmpty;
}

/// Importa el pack del asset si falta. Devuelve el resultado de la
/// importación, o null si ya había semillero (no hace nada).
Future<ResultadoImportacion?> importarSemillaDelAsset(
  BaseDeDatos db, {
  AssetBundle? bundle,
}) async {
  if (await haySemilla(db)) return null;
  final usuario = await usuarioActual(db);
  final String crudo =
      await (bundle ?? rootBundle).loadString(rutaPackSemilla);
  final dynamic pack = jsonDecode(crudo);
  if (pack is! Map<String, dynamic>) {
    throw const FormatException('El pack semilla no es un objeto JSON');
  }
  return importarPackSemilla(db, pack: pack, usuarioId: usuario.id);
}
