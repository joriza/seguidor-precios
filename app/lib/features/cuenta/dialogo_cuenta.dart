import 'package:flutter/material.dart';

import '../../data/cuenta.dart';

/// Diálogo de cuenta opcional (S3, R17/AD-003): email → enlace mágico →
/// código del email → identidad vinculada. Los errores se muestran en
/// español dentro del diálogo y siempre se puede cancelar: la cuenta es
/// opcional y nada del resto de la app depende de completarla.
class AccountDialog extends StatefulWidget {
  const AccountDialog({super.key, required this.service});

  final AccountService service;

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  bool _pasoCodigo = false;
  bool _procesando = false;
  String? _error;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _codigo = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _enviarEnlace() async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await widget.service.requestMagicLink(_email.text);
      if (!mounted) return;
      setState(() {
        _pasoCodigo = true;
        _procesando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = accountErrorMessage(e);
        _procesando = false;
      });
    }
  }

  Future<void> _vincular() async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await widget.service.completeMagicLink(
        email: _email.text,
        code: _codigo.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(normalizeEmail(_email.text));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = accountErrorMessage(e);
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? cuerpo = Theme.of(context).textTheme.bodyMedium;

    return AlertDialog(
      key: const ValueKey('dialogo-cuenta'),
      title: const Text('Cuenta por email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!_pasoCodigo) ...<Widget>[
            Text(
              'Opcional: vinculá tu email para llevar tus datos a otro '
              'dispositivo. No cambia nada de lo que ya cargaste.',
              style: cuerpo,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('campo-email-cuenta'),
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'tu@email.com',
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...<Widget>[
            Text(
              'Te enviamos un email a ${normalizeEmail(_email.text)} con un '
              'código de 6 dígitos (y un enlace). Ingresá el código acá:',
              style: cuerpo,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('campo-codigo-cuenta'),
              controller: _codigo,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Código del email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const ValueKey('error-cuenta'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _procesando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (!_pasoCodigo)
          FilledButton(
            key: const ValueKey('btn-enviar-enlace'),
            onPressed: _procesando ? null : _enviarEnlace,
            child: const Text('Enviar enlace'),
          )
        else
          FilledButton(
            key: const ValueKey('btn-vincular-cuenta'),
            onPressed: _procesando ? null : _vincular,
            child: const Text('Vincular cuenta'),
          ),
      ],
    );
  }
}
