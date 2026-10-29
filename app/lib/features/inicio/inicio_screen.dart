import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup.dart';
import '../../data/cuenta.dart';
import '../../data/identidad.dart';
import '../../data/local/base_de_datos.dart';
import '../../data/sync/config_backend.dart';
import '../cuenta/dialogo_cuenta.dart';
import '../sync/gestor_sync.dart';
import '../sync/refresco.dart';

/// Inicio (S13/S14): acceso a datos, backup y etiqueta de aportante.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, required this.baseDeDatos, this.gestorSync});

  final BaseDeDatos baseDeDatos;

  /// T4: con backend configurado, el pull-to-refresh sincroniza antes de
  /// recargar; sin backend, solo recarga lo local.
  final GestorSync? gestorSync;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  Usuario? _usuario;
  int? _productosSemilla;
  String? _version;

  /// S3 (R17/AD-003): cuenta opcional por email. Sin nube configurada la
  /// entrada no se ofrece (isEnabled false) y la pantalla queda igual.
  late final AccountService _cuenta;
  String? _emailCuenta;

  @override
  void initState() {
    super.initState();
    _cuenta = AccountService(
      baseDeDatos: widget.baseDeDatos,
      cliente: widget.gestorSync?.cliente,
      config: widget.gestorSync?.config ?? configBackend,
    );
    _cargarUsuario();
    _cargarCatalogoYVersion();
  }

  /// S3 (v0.1.2): el catálogo base viaja DENTRO del APK (no se descarga);
  /// acá se muestra cuántos productos trae y cuántos siguen disponibles.
  Future<void> _cargarCatalogoYVersion() async {
    final filas = await (widget.baseDeDatos.select(widget.baseDeDatos.productos)
          ..where((p) => p.origen.equals('semilla')))
        .get();
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      version = null; // en tests sin mock no hay plataforma real
    }
    if (!mounted) return;
    setState(() {
      _productosSemilla = filas.length;
      _version = version;
    });
  }

  Future<void> _cargarUsuario() async {
    // Solo lectura: la creación del usuario es del primer inicio (shell).
    final Usuario? u = await leerUsuario(widget.baseDeDatos);
    final String? email = await _cuenta.linkedEmail();
    if (!mounted) return;
    setState(() {
      _usuario = u;
      _emailCuenta = email;
    });
  }

  /// S3 (R17/AD-003): entrada opcional a la cuenta por email. Al cerrar el
  /// diálogo con vinculación confirmada, recarga el estado y avisa; si se
  /// cancela, nada cambió.
  Future<void> _abrirCuenta() async {
    final String? email = await showDialog<String>(
      context: context,
      builder: (_) => AccountDialog(service: _cuenta),
    );
    if (email == null || !mounted) return;
    await _cargarUsuario();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cuenta vinculada a $email. Tu identidad se actualiza en la '
          'próxima sincronización.',
        ),
      ),
    );
  }

  /// T4: pull-to-refresh — sync (si hay backend) y recarga local.
  Future<void> _refrescar() async {
    await refrescarLista(context, widget.gestorSync, _cargarUsuario);
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
    return RefreshIndicator(
      onRefresh: _refrescar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
        // S3 (R17/AD-003): cuenta opcional por email. Sin nube configurada
        // la entrada no aparece y la pantalla funciona igual: la cuenta
        // nunca bloquea el uso de la app (R3).
        if (_cuenta.isEnabled)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Cuenta (opcional)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Text(
                    'Vinculá tu email con un enlace mágico para llevar tus '
                    'datos a otro dispositivo. No cambia nada de lo que ya '
                    'cargaste.',
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    key: const ValueKey('btn-cuenta'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mark_email_unread_outlined),
                    title: const Text('Cuenta por email'),
                    subtitle: Text(_emailCuenta == null
                        ? 'Sin cuenta: la app funciona igual sin ella'
                        : 'Vinculada a $_emailCuenta'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _abrirCuenta,
                  ),
                ],
              ),
            ),
          ),
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
                ListTile(
                  key: const ValueKey('info-catalogo'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory),
                  title: const Text('Catálogo base'),
                  subtitle: Text(
                    _productosSemilla == null
                        ? '…'
                        : '$_productosSemilla productos incluidos en la app '
                            '(sin conexión, no se descarga nada)',
                  ),
                ),
                ListTile(
                  key: const ValueKey('info-version'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versión'),
                  subtitle: Text(_version ?? '…'),
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
      ),
    );
  }

  /// S1 (v0.1.1): el backup viaja como archivo vía share sheet.
  Future<void> _compartirArchivo(
    BuildContext context,
    String asunto,
    Future<File> Function() crear,
  ) async {
    try {
      final File archivo = await crear();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(archivo.path)],
          title: asunto,
          text: '$asunto — guardalo o compartilo donde quieras.',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el archivo')),
      );
    }
  }

  Future<void> _exportarJson(BuildContext context) => _compartirArchivo(
        context,
        'Backup Seguidor de Precios (JSON)',
        () => exportarBackupAArchivo(widget.baseDeDatos),
      );

  Future<void> _exportarCsv(BuildContext context) => _compartirArchivo(
        context,
        'Precios de Seguidor de Precios (CSV)',
        () => exportarCsvAArchivo(widget.baseDeDatos),
      );

  /// S1 (v0.1.1): importar elige el archivo .json del backup.
  Future<void> _importar(BuildContext context) async {
    final archivos = await FilePicker.pickFiles(
      dialogTitle: 'Elegí el backup (JSON)',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final String? path = archivos.isEmpty ? null : archivos.first.path;
    if (path == null || !context.mounted) return; // cancelado

    try {
      final String contenido = await File(path).readAsString();
      final ResumenImportacion resumen =
          await importarBackup(widget.baseDeDatos, contenido);
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
          content: Text('El archivo no es un backup válido'),
        ),
      );
    } on FileSystemException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo')),
      );
    }
  }
}
