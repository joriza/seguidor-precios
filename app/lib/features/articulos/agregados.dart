/// Agregados de precio por unidad para un artículo (S11, R12).
///
/// Mínimo, promedio y máximo calculados sobre precios por unidad de medida
/// comparables. Ventana por defecto: últimos 30 días; opción de histórico
/// completo. Filtro por comercio a cargo de la pantalla.
library;

/// Agregados sobre una lista de precios por unidad comparables.
class AgregadosArticulo {
  const AgregadosArticulo({
    required this.minimo,
    required this.promedio,
    required this.maximo,
    required this.cantidad,
  });

  final double minimo;
  final double promedio;
  final double maximo;

  /// Cantidad de precios que participaron del cálculo.
  final int cantidad;
}

/// Agregados de una lista de precios por unidad; null si no hay datos.
AgregadosArticulo? agregar(List<double> preciosUnitarios) {
  if (preciosUnitarios.isEmpty) return null;
  final double minimo = preciosUnitarios.reduce(
      (double a, double b) => a < b ? a : b);
  final double maximo = preciosUnitarios.reduce(
      (double a, double b) => a > b ? a : b);
  final double suma =
      preciosUnitarios.fold<double>(0, (double a, double b) => a + b);
  return AgregadosArticulo(
    minimo: minimo,
    promedio: suma / preciosUnitarios.length,
    maximo: maximo,
    cantidad: preciosUnitarios.length,
  );
}

/// Límite inferior (ISO `YYYY-MM-DD`) de la ventana de los últimos [dias]
/// días contados desde [hoy]. La fecha límite queda incluida.
String inicioDeVentana(DateTime hoy, {int dias = 30}) {
  final DateTime limite = DateTime(hoy.year, hoy.month, hoy.day)
      .subtract(Duration(days: dias));
  final String mes = limite.month.toString().padLeft(2, '0');
  final String dia = limite.day.toString().padLeft(2, '0');
  return '${limite.year}-$mes-$dia';
}
