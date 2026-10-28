import 'package:flutter/material.dart';

import 'gestor_sync.dart';

/// Refresco de las listas existentes (pull-to-refresh de T4): intenta una
/// sincronización con la nube y después recarga los datos locales. Sin
/// backend configurado solo recarga (local-first, R3). Nunca lanza: si la
/// sync falla, avisa sin perder el refresco local.
Future<void> refrescarLista(
  BuildContext context,
  GestorSync? gestor,
  Future<void> Function() recargar,
) async {
  if (gestor == null || !gestor.habilitado) {
    await recargar();
    return;
  }

  final bool sincronizo = await gestor.sincronizar() != null;
  await recargar();
  if (sincronizo || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'No se pudo sincronizar; tus datos están a salvo en el '
        'dispositivo.\n${gestor.ultimoError}',
      ),
    ),
  );
}
