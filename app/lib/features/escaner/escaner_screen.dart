import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/local/base_de_datos.dart';
import '../productos/producto_form_screen.dart';

/// S4 (R6): escáner con cámara (ML Kit, on-device) + ingreso manual del código.
///
/// `mostrarCamara` permite apagar la cámara en pruebas de widget (no hay
/// hardware) y validar el flujo manual contra la base en memoria.
class EscanerScreen extends StatefulWidget {
  const EscanerScreen({
    super.key,
    required this.baseDeDatos,
    this.mostrarCamara = true,
  });

  final BaseDeDatos baseDeDatos;
  final bool mostrarCamara;

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  final TextEditingController _controladorCodigo = TextEditingController();
  bool _buscando = false;
  String? _mensaje;

  @override
  void dispose() {
    _controladorCodigo.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture captura) {
    final barcodes = captura.barcodes;
    final codigo = barcodes.isEmpty ? null : barcodes.first.rawValue;
    if (codigo == null || codigo.isEmpty) return;
    _controladorCodigo.text = codigo;
    _buscar();
  }

  Future<void> _buscar() async {
    final codigo = _controladorCodigo.text.trim();
    if (codigo.isEmpty || _buscando) return;

    setState(() {
      _buscando = true;
      _mensaje = null;
    });

    final producto = await (widget.baseDeDatos.select(widget.baseDeDatos.productos)
          ..where((t) => t.codigoBarras.equals(codigo)))
        .getSingleOrNull();

    setState(() {
      _buscando = false;
      _mensaje = producto == null
          ? 'No existe un producto con ese código — crealo desde la sección Artículos (Fase 1.5).'
          : 'Producto encontrado: ${producto.nombre}';
    });
  }

  Future<void> _crearProducto() async {
    final guardado = await Navigator.of(context).push<Producto>(
      MaterialPageRoute<Producto>(
        builder: (_) => ProductoFormScreen(
          baseDeDatos: widget.baseDeDatos,
          codigoBarrasInicial: _controladorCodigo.text.trim(),
        ),
      ),
    );
    if (guardado != null) {
      _controladorCodigo.text = guardado.codigoBarras ?? '';
      _buscar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (widget.mostrarCamara)
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(onDetect: _alDetectar),
            ),
          ),
        if (widget.mostrarCamara) const SizedBox(height: 16),
        TextField(
          controller: _controladorCodigo,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Código de barras (ingreso manual)',
            hintText: 'Ej.: 7790001001001',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _buscar(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _buscando ? null : _buscar,
          icon: const Icon(Icons.search),
          label: const Text('Buscar producto'),
        ),
        if (_mensaje != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(_mensaje!),
        ],
        if (_mensaje != null && _mensaje!.startsWith('No existe')) ...<Widget>[
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _crearProducto,
            child: const Text('Crear producto'),
          ),
        ],
      ],
    );
  }
}
