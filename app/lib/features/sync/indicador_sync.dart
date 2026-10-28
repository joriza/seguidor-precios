import 'package:flutter/material.dart';

import 'gestor_sync.dart';

/// Ícono del indicador de sync (T4) según el estado: sin nube configurada,
/// cargando, con pendientes o al día. El ícono no presiona datos: el
/// detalle vive en su diálogo.
IconData iconoSync(EstadoSync estado) {
  if (!estado.habilitado) return Icons.cloud_off_outlined;
  final int? pendientes = estado.pendientes;
  if (pendientes == null) return Icons.cloud_sync_outlined; // cargando
  if (pendientes > 0) return Icons.cloud_upload_outlined;
  return Icons.cloud_done_outlined;
}

/// Texto accesible del indicador.
String textoTooltipSync(EstadoSync estado) {
  if (!estado.habilitado) return 'Sin nube configurada (solo local)';
  final int? pendientes = estado.pendientes;
  if (pendientes == null) return 'Sincronización: cargando estado';
  if (pendientes > 0) {
    return 'Sincronización: $pendientes cambio(s) pendientes';
  }
  return 'Sincronización al día';
}

/// Fecha corta local (dd/mm/aaaa HH:mm) para el diálogo de estado.
String textoFechaSync(DateTime momento) {
  final DateTime local = momento.toLocal();
  String dos(int valor) => valor.toString().padLeft(2, '0');
  return '${dos(local.day)}/${dos(local.month)}/${local.year} '
      '${dos(local.hour)}:${dos(local.minute)}';
}
