import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import 'local/base_de_datos.dart';

/// S1 (v0.3.5, diseño v2): código interno para productos sin EAN —
/// formato `S-<TOK>-<NNNN>`, único por construcción. TOK son 2 caracteres
/// A-Z0-9 generados UNA sola vez por instalación (persistidos en un
/// archivo local, al estilo del archivo de sesión de sync) y NNNN es el
/// contador por instalación. Dos instalaciones distintas generan TOK
/// distintos → sin colisiones aunque ambas creen offline. Residuo (S4):
/// mismo TOK (1/1296) + mismo NNNN → el dedup por igualdad del servidor
/// converge; probabilísticamente despreciable. Sin cambios de esquema: el
/// código viaja como un `codigo_barras` normal.

/// Caracteres válidos del TOK (36^2 = 1296 combinaciones).
const String caracteresTok = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Código interno completo: `S-AB-0001`, `S-9Z-0012`…
final RegExp patronCodigoInterno = RegExp(r'^S-([A-Z0-9]{2})-(\d+)$');

/// TOK válido: 2 caracteres A-Z0-9.
final RegExp patronTok = RegExp(r'^[A-Z0-9]{2}$');

/// Nombre del archivo de sesión del TOK, junto a la base local.
const String nombreArchivoTok = 'codigo_interno_instalacion.json';

/// Genera un TOK aleatorio de 2 caracteres A-Z0-9 (una vez por instalación).
String generarTok([Random? random]) {
  final Random azar = random ?? Random();
  return List<String>.generate(
    2,
    (_) => caracteresTok[azar.nextInt(caracteresTok.length)],
  ).join();
}

/// Devuelve el TOK de esta instalación; si no existe lo genera UNA vez y
/// lo persiste. Si el archivo está corrupto o el TOK guardado es
/// malformado, regenera y pisa el archivo. [directorio] inyectable para
/// pruebas; null = el directorio de la base local (documents de la app).
Future<String> tokDeInstalacion({Directory? directorio}) async {
  final Directory dir = directorio ?? await getApplicationDocumentsDirectory();
  final File archivo = File('${dir.path}/$nombreArchivoTok');
  if (await archivo.exists()) {
    try {
      final Object? contenido = jsonDecode(await archivo.readAsString());
      if (contenido is Map<String, dynamic>) {
        final Object? tok = contenido['tok'];
        if (tok is String && patronTok.hasMatch(tok)) return tok;
      }
    } catch (_) {
      // JSON inválido: se regenera abajo.
    }
  }
  final String tok = generarTok();
  await archivo.writeAsString(jsonEncode(<String, String>{'tok': tok}));
  return tok;
}

/// Próximo código interno `S-<TOK>-<NNNN>`: máximo NNNN ya usado por ESTE
/// TOK + 1 (4 dígitos con relleno). Valores malformados — o de otra
/// instalación — no participan ni rompen la numeración (parseo robusto;
/// dígitos que desbordan int se ignoran sin lanzar).
Future<String> proximoCodigoInterno(BaseDeDatos db, {required String tok}) async {
  final filas = await db.select(db.productos).get();
  int maximo = 0;
  for (final fila in filas) {
    final String? codigo = fila.codigoBarras;
    if (codigo == null) continue;
    final RegExpMatch? coincidencia = patronCodigoInterno.firstMatch(codigo);
    if (coincidencia == null) continue;
    if (coincidencia.group(1) != tok) continue;
    final int? valor = int.tryParse(coincidencia.group(2)!);
    if (valor == null) continue;
    if (valor > maximo) maximo = valor;
  }
  return 'S-$tok-${(maximo + 1).toString().padLeft(4, '0')}';
}
