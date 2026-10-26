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

/// Regex de cantidades OFF: valor (con decimal por coma o punto) + unidad.
final RegExp _regexCantidad = RegExp(
  r'^\s*(\d+(?:[.,]\d+)?)\s*(kg|g|cl|ml|l|unidades|unidad)\s*$',
  caseSensitive: false,
);

/// ¿El código es un EAN-13 válido (13 dígitos)?
bool esEan13(String codigo) => RegExp(r'^\d{13}$').hasMatch(codigo);

/// Primera marca de la lista separada por comas; null si está vacía.
String? extraerMarca(String brands) {
  final primera = brands.split(',').first.trim();
  return primera.isEmpty ? null : primera;
}

/// Primera categoría legible de `categories_tags` ("en:mayonnaises,...")
/// o de `categories` ("Mayonesas, Untables"); null si está vacía.
String? extraerCategoria(String categorias) {
  final primera = categorias.split(',').first.trim();
  if (primera.isEmpty) return null;
  return primera.replaceFirst(RegExp(r'^[a-z]{2,3}:'), '');
}

/// Cantidad OFF normalizada a (contenido neto, unidad) — unidad en
/// {g, mL, unidad}; kg/L/cl se convierten. Null si no es interpretable.
(double, String)? parsearCantidad(String? cantidad) {
  if (cantidad == null) return null;
  final match = _regexCantidad.firstMatch(cantidad);
  if (match == null) return null;
  final valor = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (valor == null || valor <= 0) return null;
  switch (match.group(2)!.toLowerCase()) {
    case 'kg':
      return (valor * 1000, 'g');
    case 'g':
      return (valor, 'g');
    case 'l':
      return (valor * 1000, 'mL');
    case 'ml':
      return (valor, 'mL');
    case 'cl':
      return (valor * 10, 'mL');
    case 'unidades':
    case 'unidad':
      return (valor, 'unidad');
  }
  return null;
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
