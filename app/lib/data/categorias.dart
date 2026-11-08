/// v0.3.17 (S1): diccionario de sinónimos de categorías curado por el
/// dueño — variantes país de Open Food Facts → canónico argentino.
///
/// «A las arvejas le dicen guisantes en otros países» (L1): la misma
/// categoría llega distinta según el origen del dump y el matching de
/// sugerencias (v0.3.9) se pierde. Este mapa une lo conocido a un solo
/// valor; crece con un edit + release (S1). NO es la tabla automática
/// EN→ES descartada en v0.3.9 (L3 de clasificacion.dart): solo traduce
/// lo que el dueño aprobó. Lo desconocido queda tal cual (S6: texto
/// libre del usuario).
///
/// ESPEJO: tools/seed/lib/src/transformar.dart replica este diccionario
/// y su lógica (paquete Dart separado que no importa código de la app).
/// Mantener las dos listas en sync a mano.
///
/// v0.3.17 (S2): la canonización se aplica en los 3 puntos de entrada de
/// categoría — (a) parser de enriquecimiento (enriquecimiento.dart),
/// (b) import de semilla (importar_semilla.dart), (c) generación de
/// semilla (tools/seed transformar.dart) — y en el pass retroactivo
/// LOCAL (S3) [normalizarCategoriasGuardadas], que al iniciar la app
/// actualiza producto.categoria al canónico cuando difiere. El pass no
/// encola outbox ni fuerza sync (el servidor converge cuando cada
/// producto se re-edita: push normal) y no cambia el esquema (S5).
library;

import 'package:drift/drift.dart';

import 'local/base_de_datos.dart';

/// Variantes conocidas (normalizadas: minúsculas y sin acentos) → valor
/// canónico. Mapeo de UN paso, sin cadenas: los valores canónicos no
/// deben aparecer como claves.
const Map<String, String> sinonimosCategorias = <String, String>{
  'guisantes': 'arvejas',
  'chicharos': 'arvejas', // «chícharos»
};

/// Prefijo de tag de idioma de OFF ('en:guisantes'): 2-3 letras + ':'
/// al inicio del término, como lo quita transformar.dart.
final RegExp _prefijoTag = RegExp(r'^[a-z]{2,3}:');

/// Espeja el mapeo de acentos de clasificacion.dart (minúsculas + sin
/// tildes): la clave del diccionario y el token de sugerencia deben ver
/// la MISMA forma canónica. No se importa clasificacion.dart (ella
/// importa este archivo para S4) para no cerrar una dependencia circular.
const Map<String, String> _acentos = <String, String>{
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'ã': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Forma canónica de comparación: minúsculas y sin acentos.
String _normalizar(String texto) {
  final StringBuffer normalizado = StringBuffer();
  for (final int codigo in texto.toLowerCase().runes) {
    final String letra = String.fromCharCode(codigo);
    normalizado.write(_acentos[letra] ?? letra);
  }
  return normalizado.toString();
}

/// Categoría cruda (de OFF, del pack semilla o guardada por el usuario)
/// → canónica (S1/S2). Null → null. Matchea el término completo o cada
/// segmento separado por comas, case/acento-insensitive; quita el
/// prefijo de tag 'en:'/'xx:' como transformar.dart; lo desconocido
/// vuelve tal cual (S6).
String? categoriaCanonica(String? cruda) {
  if (cruda == null) return null;
  final StringBuffer resultado = StringBuffer();
  var cambio = false;
  var primero = true;
  for (final segmento in cruda.split(',')) {
    final String recortado = segmento.trim();
    final String termino = recortado.replaceFirst(_prefijoTag, '');
    if (!primero) resultado.write(', ');
    resultado.write(sinonimosCategorias[_normalizar(termino)] ?? termino);
    // Hubo cambio si el diccionario reemplazó el término o si se quitó
    // un prefijo de tag (siempre, aunque la categoría sea desconocida).
    if (termino != recortado ||
        sinonimosCategorias.containsKey(_normalizar(termino))) {
      cambio = true;
    }
    primero = false;
  }
  // Sin match y sin tag que quitar: devuelvo la entrada EXACTA (S6).
  return cambio ? resultado.toString() : cruda;
}

/// v0.3.17 (S3): normalización retroactiva LOCAL de producto.categoria
/// al iniciar la app. Devuelve la cantidad de filas actualizadas.
/// Idempotente (segunda pasada = 0), NO encola outbox ni toca
/// actualizado_en (no es una edición del usuario), y es barata cuando
/// todo ya es canónico: un SELECT, cero UPDATE.
Future<int> normalizarCategoriasGuardadas(BaseDeDatos db) async {
  final productos = await (db.select(db.productos)
        ..where((t) => t.categoria.isNotNull()))
      .get();
  var actualizadas = 0;
  for (final producto in productos) {
    final String? canonica = categoriaCanonica(producto.categoria);
    if (canonica == null || canonica == producto.categoria) continue;
    await (db.update(db.productos)..where((t) => t.id.equals(producto.id)))
        .write(ProductosCompanion(categoria: Value(canonica)));
    actualizadas++;
  }
  return actualizadas;
}
