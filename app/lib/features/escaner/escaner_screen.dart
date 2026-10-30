import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/enriquecimiento.dart';
import '../../data/local/normalizacion.dart';
import '../../data/valoraciones.dart';

import '../../data/local/base_de_datos.dart';
import '../precios/producto_comparacion_screen.dart';
import '../precios/registro_precio_screen.dart';
import '../productos/producto_form_screen.dart';
import '../sync/red.dart';

/// S4 (R6): escáner con cámara (ML Kit, on-device) + ingreso manual del código.
///
/// `mostrarCamara` permite apagar la cámara en pruebas de widget (no hay
/// hardware) y validar el flujo manual contra la base en memoria.
class EscanerScreen extends StatefulWidget {
  const EscanerScreen({
    super.key,
    required this.baseDeDatos,
    this.mostrarCamara = true,
    this.enriquecimiento,
  });

  final BaseDeDatos baseDeDatos;
  final bool mostrarCamara;

  /// T5 (S3): puerto de enriquecimiento inyectable (pruebas usan fakes o
  /// el cliente OFF con http mockeado). Si no viene, el estado arma el
  /// default según [mostrarCamara].
  final ServicioEnriquecimiento? enriquecimiento;

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  final TextEditingController _controladorCodigo = TextEditingController();
  bool _buscando = false;
  String? _mensaje;
  Producto? _productoEncontrado;

  /// T5 (S3): datos precargados de Open Food Facts para el EAN sin
  /// resultado local. Solo se pasan al formulario: el usuario SIEMPRE
  /// confirma antes de guardar (nunca se guarda solo).
  DatosEnriquecidos? _datosEnriquecidos;

  /// T5 (S3): servicio de enriquecimiento. En uso real (cámara activa)
  /// consulta Open Food Facts respetando la heurística de conectividad de
  /// red.dart. Con la cámara apagada (pruebas de widget, sin hardware) es
  /// nulo: las pruebas nunca tocan la red real; las que prueban
  /// enriquecimiento inyectan fakes explícitos (mismo criterio de
  /// mostrarCamara).
  late final ServicioEnriquecimiento _enriquecimiento =
      widget.enriquecimiento ??
          (widget.mostrarCamara
              ? ServicioEnriquecimientoOFF(hayConexion: _hayConexion)
              : const ServicioEnriquecimientoNulo());

  /// S4 (v0.1.2): último precio conocido del producto encontrado — propio o
  /// ajeno (misma base local, cualquier aportante).
  ({double precio, String comercio, String fecha})? _ultimoPrecio;
  Valoracion? _valoracion;

  /// v0.1.4: linterna desde la interfaz (cámaras CCD con poca luz).
  MobileScannerController? _controladorCamara;
  bool _linterna = false;

  @override
  void initState() {
    super.initState();
    if (widget.mostrarCamara) {
      _controladorCamara = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _controladorCodigo.dispose();
    _controladorCamara?.dispose();
    super.dispose();
  }

  Future<void> _alternarLinterna() async {
    await _controladorCamara?.toggleTorch();
    if (mounted) setState(() => _linterna = !_linterna);
  }

  void _alDetectar(BarcodeCapture captura) {
    final barcodes = captura.barcodes;
    final codigo = barcodes.isEmpty ? null : barcodes.first.rawValue;
    if (codigo == null || codigo.isEmpty) return;
    _controladorCodigo.text = codigo;
    _buscar();
  }

  /// Conectividad para el enriquecimiento (R14: cualquier tipo alcanza;
  /// solo sin interfaces no consulta).
  Future<bool> _hayConexion() async =>
      await detectarConexion() != TipoConexion.ninguna;

  /// T5 (S3): consulta OFF en segundo plano tras un EAN sin resultado.
  /// Nunca lanza y nunca escribe: el resultado solo se muestra como
  /// precarga; el usuario confirma creando el producto.
  Future<void> _enriquecer(String ean) async {
    // S3 (v0.3.5): los códigos internos S-* nunca consultan OFF; solo
    // EANs reales se enriquecen.
    if (ean.startsWith('S-')) return;
    final DatosEnriquecidos? datos;
    try {
      datos = await _enriquecimiento.consultar(ean);
    } catch (_) {
      return; // OFF caído o timeout: flujo manual como hoy
    }
    if (!mounted) return;
    if (datos == null) return; // sin resultado: formulario vacío como hoy
    // El resultado puede llegar tarde: solo vale si sigue el mismo EAN
    // pendiente de crear.
    if (_productoEncontrado != null) return;
    if (_controladorCodigo.text.trim() != ean) return;
    setState(() {
      _datosEnriquecidos = datos;
    });
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
    final valoracion =
        producto == null ? null : await valoracionDe(widget.baseDeDatos, producto.id);

    if (!mounted) return;
    setState(() {
      _buscando = false;
      _productoEncontrado = producto;
      _ultimoPrecio = ultimo;
      _valoracion = valoracion;
      _datosEnriquecidos = null; // cada búsqueda parte de cero
      _mensaje = producto == null
          ? 'No existe un producto con ese código — crealo con el botón de abajo.'
          : 'Producto encontrado: ${producto.nombre}';
    });
    // T5 (S3): con el producto inexistente, consulta OFF en segundo plano
    // (si hay conectividad) y precarga para confirmación del usuario.
    if (producto == null) unawaited(_enriquecer(codigo));
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

  /// v0.1.4: corregir o completar datos del producto (semillero incluido).
  Future<void> _editarProducto() async {
    final producto = _productoEncontrado;
    if (producto == null) return;
    final guardado = await Navigator.of(context).push<Producto>(
      MaterialPageRoute<Producto>(
        builder: (_) => ProductoFormScreen(
          baseDeDatos: widget.baseDeDatos,
          producto: producto,
        ),
      ),
    );
    if (guardado != null) {
      _controladorCodigo.text = guardado.codigoBarras ?? '';
    }
    _buscar(); // refresca datos del producto, último precio y valoración
  }

  /// Línea del último precio con la estandarización por unidad de medida
  /// (R11/R12): '... (3000.00 / kg)' cuando el producto es comparable.
  String _lineaUltimoPrecio() {
    final u = _ultimoPrecio!;
    final p = _productoEncontrado!;
    final String? base = unidadBaseDe(p.unidad);
    final double? estandar = base == null
        ? null
        : precioPorUnidad(
            precio: u.precio,
            unidad: p.unidad,
            unidadBase: base,
            contenidoNeto: p.contenidoNeto,
          );
    final String sufijo = estandar == null
        ? ''
        : ' (${estandar.toStringAsFixed(2)} / $base)';
    return 'Último precio: \$${u.precio.toStringAsFixed(2)}'
        ' · ${u.comercio} · ${u.fecha}$sufijo';
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
          datosIniciales: _datosEnriquecidos,
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
              child: Stack(
                children: <Widget>[
                  MobileScanner(
                    controller: _controladorCamara,
                    onDetect: _alDetectar,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: _linterna
                          ? 'Apagar linterna'
                          : 'Encender linterna',
                      icon: Icon(
                        _linterna ? Icons.flash_on : Icons.flash_off,
                      ),
                      onPressed: _alternarLinterna,
                    ),
                  ),
                ],
              ),
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
        if (_datosEnriquecidos != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Datos encontrados en Open Food Facts: ${_datosEnriquecidos!.nombre}'
            '${_datosEnriquecidos!.marca == null ? '' : ' (${_datosEnriquecidos!.marca})'}'
            ' — revisalos y confirmá al crear el producto.',
          ),
        ],
        if (_productoEncontrado != null) ...<Widget>[
          const SizedBox(height: 12),
          if (_ultimoPrecio != null)
            Text(_lineaUltimoPrecio())
          else
            const Text('Este producto todavía no tiene precios registrados'),
          if (_valoracion != null &&
              (_valoracion!.gusto != null ||
                  (_valoracion!.observacion ?? '').isNotEmpty)) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Mi valoración: '
              '${_valoracion!.gusto == 'si' ? '👍 Me gusta' : _valoracion!.gusto == 'no' ? '👎 No me gusta' : '—'}'
              '${(_valoracion!.observacion ?? '').isEmpty ? '' : ' — ${_valoracion!.observacion}'}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _registrarPrecio,
            child: const Text('Registrar precio'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _editarProducto,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar datos'),
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
