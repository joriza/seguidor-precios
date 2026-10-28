import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/local/base_de_datos.dart';
import '../precios/producto_comparacion_screen.dart';
import '../precios/registro_precio_screen.dart';
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
  Producto? _productoEncontrado;

  /// S4 (v0.1.2): último precio conocido del producto encontrado — propio o
  /// ajeno (misma base local, cualquier aportante).
  ({double precio, String comercio, String fecha})? _ultimoPrecio;

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

    final ultimo = producto == null ? null : await _ultimoPrecioDe(producto.id);

    if (!mounted) return;
    setState(() {
      _buscando = false;
      _productoEncontrado = producto;
      _ultimoPrecio = ultimo;
      _mensaje = producto == null
          ? 'No existe un producto con ese código — crealo desde la sección Artículos (Fase 1.5).'
          : 'Producto encontrado: ${producto.nombre}';
    });
  }

  /// Último precio conocido del producto (R1): la toma de fecha más reciente.
  Future<({double precio, String comercio, String fecha})?>
      _ultimoPrecioDe(String productoId) async {
    final filas = await widget.baseDeDatos.customSelect(
      'SELECT pr.precio AS precio, c.nombre AS comercio, '
      'pr.fecha_toma AS fecha '
      'FROM precios pr JOIN comercios c ON pr.comercio_id = c.id '
      'WHERE pr.producto_id = ? '
      'ORDER BY pr.fecha_toma DESC, pr.cargado_en DESC LIMIT 1',
      variables: [Variable.withString(productoId)],
      readsFrom: {
        widget.baseDeDatos.precios,
        widget.baseDeDatos.comercios,
      },
    ).get();
    if (filas.isEmpty) return null;
    final f = filas.first;
    return (
      precio: f.read<double>('precio'),
      comercio: f.read<String>('comercio'),
      fecha: f.read<String>('fecha'),
    );
  }

  Future<void> _registrarPrecio() async {
    final Producto? producto = _productoEncontrado;
    if (producto == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegistroPrecioScreen(
          baseDeDatos: widget.baseDeDatos,
          producto: producto,
        ),
      ),
    );
    if (!mounted) return;
    final ultimo = await _ultimoPrecioDe(producto.id);
    if (!mounted) return;
    setState(() {
      _mensaje = 'Precio registrado ✓';
      _ultimoPrecio = ultimo; // refresca el precio mostrado (S4)
    });
  }

  Future<void> _compararPrecios() async {
    final Producto? producto = _productoEncontrado;
    if (producto == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductoComparacionScreen(
          baseDeDatos: widget.baseDeDatos,
          producto: producto,
        ),
      ),
    );
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
            // S4 (v0.1.2): menos altura para dejar lugar a los datos del
            // producto escaneado (último precio, etc.). El dueño pidió
            // reducir un 25% adicional sobre los 180.
            height: 135,
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
        if (_productoEncontrado != null) ...<Widget>[
          const SizedBox(height: 12),
          if (_ultimoPrecio != null)
            Text(
              'Último precio: \$${_ultimoPrecio!.precio.toStringAsFixed(2)}'
              ' · ${_ultimoPrecio!.comercio} · ${_ultimoPrecio!.fecha}',
            )
          else
            const Text('Este producto todavía no tiene precios registrados'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _registrarPrecio,
            child: const Text('Registrar precio'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _compararPrecios,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Comparar precios'),
          ),
        ],
      ],
    );
  }
}
