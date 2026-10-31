/// v0.3.9 (S1): motor de sugerencia de artículo para clasificar productos.
///
/// Función PURA y determinista, sin I/O: dado un producto (categoría de
/// OFF + nombre + marca) y la lista de artículos propios, sugiere los
/// artículos ordenados por cantidad de tokens coincidentes (desc), con
/// desempate determinista por nombre normalizado y luego id. El match es
/// case-insensitive y sin acentos.
///
/// Decisión de diseño (Log L3): NO hay tabla fija EN→ES de categorías
/// (frágil); el match principal es el token común — ej.: producto
/// «Galletitas de chocolate» ↔ artículo «Galletitas», también el token de
/// marca si coincide. Sin matches → sin sugerencia (alta manual desde la
/// pantalla de clasificación).
library;

import 'local/base_de_datos.dart';

/// Una sugerencia: el artículo y cuántos tokens coincidieron.
class SugerenciaArticulo {
  const SugerenciaArticulo({
    required this.articulo,
    required this.coincidencias,
  });

  final Articulo articulo;

  /// Cantidad de tokens del producto presentes en el nombre del artículo.
  final int coincidencias;
}

/// Mapeo de acentos y letras especiales para comparar sin tildes.
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

final RegExp _separadorTokens = RegExp(r'[^a-z0-9]+');

/// Normaliza texto para comparar: minúsculas y sin acentos (á→a, ñ→n…).
/// Null o vacío → string vacío.
String normalizarParaComparar(String? texto) {
  final String minusculas = (texto ?? '').toLowerCase();
  if (minusculas.isEmpty) return '';
  final StringBuffer normalizado = StringBuffer();
  for (final int codigo in minusculas.runes) {
    final String letra = String.fromCharCode(codigo);
    normalizado.write(_acentos[letra] ?? letra);
  }
  return normalizado.toString();
}

/// Tokens para el match de clasificación: texto normalizado partido por
/// todo separador no alfanumérico ('Snacks, Sweet snacks, Biscuits' →
/// snacks, sweet, snacks, biscuits).
List<String> tokensDeClasificacion(String? texto) {
  final String normalizado = normalizarParaComparar(texto);
  if (normalizado.isEmpty) return const <String>[];
  return normalizado
      .split(_separadorTokens)
      .where((String token) => token.isNotEmpty)
      .toList();
}

/// Sugiere artículos para el producto dado: los tokens del producto
/// (categoria + nombre + marca, sin duplicados) matcheados contra los
/// tokens del nombre de cada artículo. Solo sugiere artículos no borrados
/// (S3) con al menos un token en común; orden descendente por cantidad de
/// tokens coincidentes, empate por nombre normalizado y luego id.
List<SugerenciaArticulo> sugerirArticulos({
  required String? categoria,
  required String nombre,
  String? marca,
  required List<Articulo> articulos,
}) {
  final Set<String> tokensProducto = <String>{
    ...tokensDeClasificacion(categoria),
    ...tokensDeClasificacion(nombre),
    ...tokensDeClasificacion(marca),
  };
  if (tokensProducto.isEmpty) return const <SugerenciaArticulo>[];

  final List<SugerenciaArticulo> sugerencias = <SugerenciaArticulo>[];
  for (final Articulo articulo in articulos) {
    // S3: los artículos borrados nunca se sugieren.
    if (articulo.borradoEn != null) continue;
    final int coincidencias = tokensProducto
        .intersection(tokensDeClasificacion(articulo.nombre).toSet())
        .length;
    if (coincidencias > 0) {
      sugerencias.add(SugerenciaArticulo(
        articulo: articulo,
        coincidencias: coincidencias,
      ));
    }
  }

  sugerencias.sort((SugerenciaArticulo a, SugerenciaArticulo b) {
    final int porCantidad = b.coincidencias.compareTo(a.coincidencias);
    if (porCantidad != 0) return porCantidad;
    final int porNombre = normalizarParaComparar(a.articulo.nombre)
        .compareTo(normalizarParaComparar(b.articulo.nombre));
    if (porNombre != 0) return porNombre;
    return a.articulo.id.compareTo(b.articulo.id);
  });
  return List.unmodifiable(sugerencias);
}
