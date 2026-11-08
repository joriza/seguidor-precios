/// Fecha corta compartida para toda la UI (S2, v0.3.16).
///
/// Las tomas guardan `fecha_toma` como ISO `YYYY-MM-DD`; mostrarlo crudo
/// obliga a descifrar la fecha (queja #14). Toda superficie muestra la
/// fecha en formato corto `dd/mm`, con el año solo cuando no es el actual.
/// Solo presentación (S6): no toca la base ni las consultas.
library;

/// Fecha corta `dd/mm`; `dd/mm/aaaa` cuando el año de [iso] no es el actual.
///
/// [ahora] es inyectable para tests. Acepta fecha con hora (`...T...`) y
/// devuelve [iso] sin cambios si no es parseable (defensivo, nunca rompe).
String fechaCorta(String? iso, {DateTime? ahora}) {
  if (iso == null || iso.length < 10) return iso ?? '';
  final List<String> partes = iso.substring(0, 10).split('-');
  if (partes.length != 3) return iso;
  final int? anio = int.tryParse(partes[0]);
  final int? mes = int.tryParse(partes[1]);
  final int? dia = int.tryParse(partes[2]);
  if (anio == null || mes == null || dia == null) return iso;

  final String dd = dia.toString().padLeft(2, '0');
  final String mm = mes.toString().padLeft(2, '0');
  final bool mismoAnio = (ahora ?? DateTime.now()).year == anio;
  return mismoAnio ? '$dd/$mm' : '$dd/$mm/$anio';
}
