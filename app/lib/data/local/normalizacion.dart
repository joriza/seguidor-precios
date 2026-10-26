/// Normalización de precios por unidad de medida (R11/R12, AD-014).
///
/// `precio_unitario = precio / (contenido_neto × factor(unidad → unidad_base))`.
/// Granel (AD-014): si no hay contenido neto y la unidad coincide con la base,
/// se asume 1 (el precio ya es por unidad). Devuelve null cuando el producto
/// no es comparable (sin contenido neto utilizable o conversión imposible).
library;

const Map<String, String> _unidadBase = <String, String>{
  'g': 'kg',
  'kg': 'kg',
  'mL': 'L',
  'L': 'L',
  'unidad': 'unidad',
  'm': 'm',
};

/// Factor multiplicativo para pasar de `desde` a su unidad base.
/// Devuelve null si la conversión no existe.
double? factorConversion(String desde) => switch (desde) {
      'g' || 'mL' => 0.001,
      'kg' || 'L' || 'unidad' || 'm' => 1.0,
      _ => null,
    };

/// Unidad base de una unidad de venta; null si la unidad es desconocida.
String? unidadBaseDe(String unidad) => _unidadBase[unidad];

/// Precio por unidad de medida, o null si el producto no es comparable.
double? precioPorUnidad({
  required double precio,
  required String unidad,
  required String unidadBase,
  double? contenidoNeto,
}) {
  final double? factor = factorConversion(unidad);
  if (factor == null || _unidadBase[unidad] != unidadBase) return null;

  // Granel (AD-014): implícito = 1 SOLO cuando la unidad de venta coincide
  // con la base (kg a granel, m a granel...). Un producto empaquetado en g
  // sin contenido neto declarado NO es comparable.
  final double? neto = contenidoNeto ?? (unidad == unidadBase ? 1.0 : null);
  if (neto == null || neto <= 0) return null;
  return precio / (neto * factor);
}
