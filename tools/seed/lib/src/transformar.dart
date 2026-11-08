/// Transformación de dumps CSV de Open Food Facts / Open Products Facts
/// al pack semilla de Seguidor de Precios (R10).
///
/// Reglas:
/// - Solo EAN-13 (13 dígitos) — R10.
/// - Solo filas con nombre y cantidad interpretable (contenido neto).
/// - Filtrado por país: si la fila declara países y ninguno es Argentina,
///   se descarta; si no declara, se conserva (el operador ya filtró el dump).
/// - Cantidades normalizadas a g / mL / unidad (kg, L y cl se convierten).
/// - Deduplicación por EAN (gana la primera aparición).
library;

import 'package:csv/csv.dart';

/// v0.3.17 (S1): diccionario de sinónimos de categorías, curado por el
/// dueño (variante país → canónico argentino; crece con un edit).
/// ESPEJO de app/lib/data/categorias.dart — paquete Dart separado que no
/// importa código de la app: mantener las dos listas en sync a mano.
const Map<String, String> _sinonimosCategorias = <String, String>{
  'guisantes': 'arvejas',
  'chicharos': 'arvejas', // «chícharos»
};

/// Prefijo de tag de idioma de OFF ('en:guisantes'): 2-3 letras + ':'
/// al inicio del término (el mismo patrón que venía usándose aquí).
final RegExp _prefijoTag = RegExp(r'^[a-z]{2,3}:');

/// Espeja el mapeo de acentos de la app (clasificacion.dart y
/// categorias.dart): misma forma canónica de comparación en ambos lados.
const Map<String, String> _acentos = <String, String>{
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
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

/// Categoría cruda → canónica (S1/S2). Igual semántica que
/// `categoriaCanonica` en app/lib/data/categorias.dart: matchea el
/// término completo o cada segmento separado por comas,
/// case/acento-insensitive; quita el prefijo de tag 'en:'/'xx:'; lo
/// desconocido vuelve tal cual; null → null.
String? categoriaCanonica(String? cruda) {
  if (cruda == null) return null;
  final StringBuffer resultado = StringBuffer();
  var cambio = false;
  var primero = true;
  for (final segmento in cruda.split(',')) {
    final String recortado = segmento.trim();
    final String termino = recortado.replaceFirst(_prefijoTag, '');
    if (!primero) resultado.write(', ');
    resultado.write(_sinonimosCategorias[_normalizar(termino)] ?? termino);
    if (termino != recortado ||
        _sinonimosCategorias.containsKey(_normalizar(termino))) {
      cambio = true;
    }
    primero = false;
  }
  // Sin match y sin tag que quitar: devuelvo la entrada EXACTA.
  return cambio ? resultado.toString() : cruda;
}

/// Regex de cantidades OFF: valor (con decimal por coma o punto) + unidad.
/// v0.3.15 (S5): se toleran sufijos informativos tras la unidad — la «e»
/// del estiario europeo ('500 g e') ya no descarta la fila.
final RegExp _regexCantidad = RegExp(
  r'^\s*(\d+(?:[.,]\d+)?)\s*(kg|g|cl|ml|l|unidades|unidad)\s*(?:e|℮)*\s*$',
  caseSensitive: false,
);

/// Multipack OFF (v0.3.15 S5): «N x M unidad» o «N unidades de M
/// unidad» métrica. La semilla no tiene campo pack (el JSON v1 no lo
/// lleva) → contenido TOTAL (N×M) en unidad canónica.
final RegExp _regexMultipack = RegExp(
  r'^\s*(\d+)\s*(?:x|unidades?\s+de)\s*(\d+(?:[.,]\d+)?)\s*(kg|g|cl|ml|l)\s*(?:e|℮)*\s*$',
  caseSensitive: false,
);

/// Valor en unidad métrica cruda → canónica {g, mL}. Null si la unidad
/// no es una de las soportadas.
(double, String)? _aCanonica(double valor, String unidad) => switch (unidad) {
      'kg' => (valor * 1000, 'g'),
      'g' => (valor, 'g'),
      'cl' => (valor * 10, 'mL'),
      'ml' => (valor, 'mL'),
      'l' => (valor * 1000, 'mL'),
      _ => null,
    };

/// ¿El código es un EAN-13 válido (13 dígitos)?
bool esEan13(String codigo) => RegExp(r'^\d{13}$').hasMatch(codigo);

/// Primera marca de la lista separada por comas; null si está vacía.
String? extraerMarca(String brands) {
  final primera = brands.split(',').first.trim();
  return primera.isEmpty ? null : primera;
}

/// Primera categoría legible de `categories_tags` ("en:mayonnaises,...")
/// o de `categories` ("Mayonesas, Untables"); null si está vacía.
/// v0.3.17 (S2-c): el pack sale con la categoría canónica (S1, espejo
/// del diccionario del dueño); lo desconocido sigue igual.
String? extraerCategoria(String categorias) {
  final primera = categorias.split(',').first.trim();
  if (primera.isEmpty) return null;
  return categoriaCanonica(primera.replaceFirst(_prefijoTag, ''));
}

/// Cantidad OFF normalizada a (contenido neto, unidad) — unidad en
/// {g, mL, unidad}; kg/L/cl se convierten. Null si no es interpretable.
/// v0.3.15 (S5): multipack «N x M unidad» / «N unidades de M unidad» →
/// contenido TOTAL (N×M) en canónica {g, mL} (sin descartes evitables);
/// '10 unidades' → (unidad, N); sufijos informativos ('500 g e') se
/// toleran.
(double, String)? parsearCantidad(String? cantidad) {
  if (cantidad == null) return null;
  final RegExpMatch? multi = _regexMultipack.firstMatch(cantidad);
  if (multi != null) {
    final double? pack = double.tryParse(multi.group(1)!);
    final double? porUnidad =
        double.tryParse(multi.group(2)!.replaceAll(',', '.'));
    final (double, String)? canonica = porUnidad == null
        ? null
        : _aCanonica(porUnidad, multi.group(3)!.toLowerCase());
    if (pack == null || pack <= 0 || canonica == null) return null;
    return (pack * canonica.$1, canonica.$2);
  }
  final match = _regexCantidad.firstMatch(cantidad);
  if (match == null) return null;
  final valor = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (valor == null || valor <= 0) return null;
  switch (match.group(2)!.toLowerCase()) {
    case 'unidades':
    case 'unidad':
      return (valor, 'unidad'); // v0.3.15 (S5): (unidad, N)
  }
  return _aCanonica(valor, match.group(2)!.toLowerCase());
}

/// Convierte el contenido CSV completo en la lista de productos del pack.
///
/// Requiere columnas `code` y `product_name` (nombres estándar de OFF);
/// el resto es opcional. `limite` acota la salida (útil para pruebas).
List<Map<String, dynamic>> transformarCsv(String contenido, {int? limite}) {
  final filas = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(contenido.replaceFirst('\uFEFF', ''));
  if (filas.isEmpty) return const [];

  final cabecera = filas.first
      .map((c) => c.toString().trim().toLowerCase())
      .toList(growable: false);
  int indice(Set<String> nombres) =>
      cabecera.indexWhere((h) => nombres.contains(h));

  final iCodigo = indice({'code', 'barcode'});
  final iNombre = indice({'product_name', 'product_name_es', 'product_name_en'});
  final iMarcas = indice({'brands', 'brands_tags'});
  final iCantidad = indice({'quantity'});
  final iCategorias = indice({'categories_tags', 'categories'});
  final iPaises = indice({'countries_tags'});
  if (iCodigo < 0 || iNombre < 0) {
    throw ArgumentError(
        'El CSV debe incluir al menos las columnas "code" y "product_name".');
  }

  String celda(List<dynamic> fila, int i) =>
      (i >= 0 && i < fila.length) ? fila[i].toString().trim() : '';

  final vistos = <String>{};
  final resultado = <Map<String, dynamic>>[];
  for (final fila in filas.skip(1)) {
    if (limite != null && resultado.length >= limite) break;

    final codigo = celda(fila, iCodigo);
    if (!esEan13(codigo) || vistos.contains(codigo)) continue;

    final nombre = celda(fila, iNombre);
    if (nombre.isEmpty) continue;

    if (iPaises >= 0) {
      final paises = celda(fila, iPaises).toLowerCase();
      if (paises.isNotEmpty && !paises.contains('argentina')) continue;
    }

    final cantidad = parsearCantidad(iCantidad >= 0 ? celda(fila, iCantidad) : null);
    if (cantidad == null) continue;

    vistos.add(codigo);
    resultado.add(<String, dynamic>{
      'codigo_barras': codigo,
      'nombre': nombre,
      'marca': extraerMarca(iMarcas >= 0 ? celda(fila, iMarcas) : ''),
      'unidad': cantidad.$2,
      'contenido_neto': cantidad.$1,
      'categoria': extraerCategoria(iCategorias >= 0 ? celda(fila, iCategorias) : ''),
    });
  }
  return resultado;
}

/// Empaqueta la lista con los metadatos de atribución (R10 / AD-008).
Map<String, dynamic> armarPack({
  required List<Map<String, dynamic>> productos,
  required String version,
  DateTime? ahora,
}) {
  return <String, dynamic>{
    'fuente': 'Open Food Facts / Open Products Facts (contribuyentes)',
    'licencia': 'ODbL',
    'version': version,
    'generado': (ahora ?? DateTime.now()).toUtc().toIso8601String(),
    'cantidad': productos.length,
    'productos': productos,
  };
}
