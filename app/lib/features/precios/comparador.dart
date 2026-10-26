/// T9 (R13/R11): filas del comparador ordenadas por precio por unidad.
/// La jerarquía (R13): si el producto existe por su EAN, se compara ese
/// producto entre comercios; la comparación por artículo es la vía cuando
/// no hay coincidencia por código. La capa de datos decide qué filas traer;
/// este módulo solo ordena y expone el mínimo.
library;

class FilaComparacion {
  const FilaComparacion({
    required this.productoNombre,
    this.marca,
    required this.comercioNombre,
    required this.precio,
    required this.precioUnitario,
  });

  final String productoNombre;
  final String? marca;
  final String comercioNombre;
  final double precio;

  /// Precio normalizado a la unidad base del artículo (o del producto en la
  /// comparación por EAN).
  final double precioUnitario;

  String get etiquetaProducto => marca == null || marca!.isEmpty
      ? productoNombre
      : '$productoNombre · $marca';
}

/// Copia las filas ordenadas de menor a mayor precio por unidad.
/// Devuelve una lista nueva: no muta la entrada.
List<FilaComparacion> ordenarPorPrecioUnitario(List<FilaComparacion> filas) {
  final List<FilaComparacion> copia = List<FilaComparacion>.of(filas)
    ..sort((FilaComparacion a, FilaComparacion b) =>
        a.precioUnitario.compareTo(b.precioUnitario));
  return copia;
}

/// Precio por unidad mínimo; null si no hay filas.
double? precioMinimo(List<FilaComparacion> filas) => filas.isEmpty
    ? null
    : ordenarPorPrecioUnitario(filas).first.precioUnitario;
