import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/backup.dart';
import '../../data/identidad.dart';
import '../../data/local/base_de_datos.dart';

/// Inicio (S13/S14): acceso a datos, backup y etiqueta de aportante.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, required this.baseDeDatos});

  final BaseDeDatos baseDeDatos;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    // Solo lectura: la creación del usuario es del primer inicio (shell).
    final Usuario? u = await leerUsuario(widget.baseDeDatos);
    if (!mounted) return;
    setState(() => _usuario = u);
  }

  Future<void> _cambiarEtiqueta(BuildContext context) async {
    final TextEditingController controlador =
        TextEditingController(text: _usuario?.etiqueta);
    final String? nueva = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Etiqueta de aportante'),
        content: TextField(
          key: const ValueKey('campo-cambiar-etiqueta'),
          controller: controlador,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre o apodo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controlador.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nueva == null || nueva.isEmpty) return;
    await cambiarEtiqueta(widget.baseDeDatos, nueva);
    await _cargarUsuario();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Etiqueta actualizada a «$nueva»')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Icon(Icons.home, size: 64),
        const SizedBox(height: 8),
        Text(
          'Seguidor de Precios',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const Text(
          'Tus precios, en tu dispositivo.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Datos y backup',
                    style: Theme.of(context).textTheme.titleMedium),
                const Text(
                  'Exportá un backup en formato abierto (JSON/CSV) e '
                  'importalo en otra instalación.',
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const ValueKey('btn-etiqueta'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Etiqueta de aportante'),
                  subtitle: Text(_usuario?.etiqueta ?? 'Aún sin etiqueta'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _cambiarEtiqueta(context),
                ),
                FilledButton.icon(
                  key: const ValueKey('btn-exportar-json'),
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar backup (JSON)'),
                  onPressed: () => _exportarJson(context),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('btn-exportar-csv'),
                  icon: const Icon(Icons.table_view),
                  label: const Text('Exportar precios (CSV)'),
                  onPressed: () => _exportarCsv(context),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('btn-importar'),
                  icon: const Icon(Icons.upload),
                  label: const Text('Importar backup (JSON)'),
                  onPressed: () => _importar(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportarJson(BuildContext context) async {
    final String json =
        JsonEncoder.withIndent('  ').convert(await exportarBackup(widget.baseDeDatos));
    if (!context.mounted) return;
    _mostrarTexto(context, 'Backup JSON', json);
  }

  Future<void> _exportarCsv(BuildContext context) async {
    final String csv = await exportarPreciosCsv(widget.baseDeDatos);
    if (!context.mounted) return;
    _mostrarTexto(context, 'Precios CSV', csv);
  }

  void _mostrarTexto(BuildContext context, String titulo, String texto) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: SelectableText(
            texto,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: texto));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiado al portapapeles')),
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _importar(BuildContext context) async {
    final TextEditingController controlador = TextEditingController();
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Importar backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Pegá acá el contenido del backup JSON. '
              'Las filas que ya existen no se modifican.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('campo-importar'),
              controller: controlador,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{"formato": "seguidor-precios-backup", ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('btn-confirmar-importar'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    try {
      final ResumenImportacion resumen =
          await importarBackup(widget.baseDeDatos, controlador.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup importado: ${resumen.insertadas} filas nuevas, '
            '${resumen.omitidas} omitidas (ya existían o inválidas).',
          ),
        ),
      );
    } on FormatException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El texto no es un backup válido'),
        ),
      );
    }
  }
}
