import 'package:flutter/material.dart';

import '../../data/codigo_interno.dart';
import '../../data/enriquecimiento.dart';
import '../../data/local/base_de_datos.dart';
import '../../data/local/normalizacion.dart';
import '../../data/productos.dart';
import '../../data/valoraciones.dart';

/// S5 (R1/R7/R11): alta y edición de producto.
///
/// v0.3.5 (S1/S6): en el alta, código vacío = se asigna un código interno
/// `S-<TOK>-<NNNN>` único por construcción (TOK de la instalación).
///
/// Campos: código (opcional, editable), nombre (obligatorio), marca,
/// unidad de venta, contenido neto (vacío = 1 para granel, AD-014),
/// unidades por pack (v0.3.8, S5: default 1, entero ≥ 1), categoría y
/// artículo (opcional).
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({
    super.key,
    required this.baseDeDatos,
    this.producto,
    this.codigoBarrasInicial,
    this.datosIniciales,
    this.tokInterno,
    this.alGuardar,
  });

  final BaseDeDatos baseDeDatos;
  final Producto? producto;
  final String? codigoBarrasInicial;

  /// T5 (S3): datos precargados desde Open Food Facts al crear un producto
  /// nuevo. Solo aplican al alta (la edición manda) y el usuario siempre
  /// confirma antes de guardar.
  final DatosEnriquecidos? datosIniciales;

  /// S1 (v0.3.5): TOK del código interno inyectable (pruebas); null = el
  /// archivo real de la instalación (patrón del archivo de sesión).
  final Future<String> Function()? tokInterno;

  final void Function(Producto producto)? alGuardar;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _marca;
  late final TextEditingController _contenido;
  late final TextEditingController _pack;
  late final TextEditingController _categoria;
  late String _unidad;
  String? _articuloId;
  List<Articulo> _articulos = <Articulo>[];
  bool _guardando = false;
  String? _error;

  /// v0.1.5: valoración personal — neutro por defecto.
  String _gusto = 'neutro';
  final TextEditingController _observacion = TextEditingController();

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _codigo = TextEditingController(
      text: widget.producto?.codigoBarras ?? widget.codigoBarrasInicial ?? '',
    );
    _nombre = TextEditingController(
      text: widget.producto?.nombre ?? widget.datosIniciales?.nombre ?? '',
    );
    _marca = TextEditingController(
      text: widget.producto?.marca ?? widget.datosIniciales?.marca ?? '',
    );
    _contenido = TextEditingController(
      text: widget.producto?.contenidoNeto?.toString() ??
          widget.datosIniciales?.contenidoNeto?.toString() ??
          '',
    );
    // S5 (v0.3.8): default 1; Open Food Facts no informa pack.
    _pack = TextEditingController(
      text: widget.producto?.pack.toString() ?? '1',
    );
    // S1 (v0.3.9): la categoría cruda de OFF precarga el campo en el alta;
    // en la edición manda el producto guardado. El usuario confirma antes
    // de guardar (S3): la fila se crea/recién se cambia al guardar.
    _categoria = TextEditingController(
      text: widget.producto?.categoria ??
          widget.datosIniciales?.categorias ??
          '',
    );
    _unidad =
        widget.producto?.unidad ?? widget.datosIniciales?.unidad ?? 'unidad';
    _articuloId = widget.producto?.articuloId;
    _cargarArticulos();
    if (_esEdicion) {
      _cargarValoracion();
    }
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _marca.dispose();
    _contenido.dispose();
    _pack.dispose();
    _categoria.dispose();
    _observacion.dispose();
    super.dispose();
  }

  /// Carga la valoración personal existente del producto (solo edición).
  Future<void> _cargarValoracion() async {
    final valoracion =
        await valoracionDe(widget.baseDeDatos, widget.producto!.id);
    if (!mounted || valoracion == null) return;
    setState(() {
      _gusto = valoracion.gusto ?? 'neutro';
      _observacion.text = valoracion.observacion ?? '';
    });
  }

  Future<void> _cargarArticulos() async {
    final lista = await (widget.baseDeDatos.select(widget.baseDeDatos.articulos)
          ..where((t) => t.borradoEn.isNull()))
        .get();
    if (mounted) setState(() => _articulos = lista);
  }

  double? _contenidoNetoNormalizado() {
    final texto = _contenido.text.trim();
    if (texto.isEmpty) return null;
    final valor = double.tryParse(texto.replaceAll(',', '.'));
    if (valor == null || valor <= 0) return null;
    return (valor * 100).roundToDouble() / 100;
  }

  /// S5 (v0.3.8): unidades por pack — vacío = 1 (el validador garantiza
  /// que lo ingresado sea un entero ≥ 1).
  int _packNormalizado() {
    final texto = _pack.text.trim();
    if (texto.isEmpty) return 1;
    return int.parse(texto);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    final codigo = _codigo.text.trim();
    final nombre = _nombre.text.trim();
    final marca = _marca.text.trim();
    final categoria = _categoria.text.trim();
    final neto = _contenidoNetoNormalizado();
    final pack = _packNormalizado();

    try {
      // S1 (v0.3.5): alta sin código → se asigna el próximo código interno
      // S-<TOK>-<NNNN> de esta instalación. La edición mantiene su contrato
      // de siempre: vacío = quita el código.
      String? codigoBarras = codigo.isEmpty ? null : codigo;
      if (!_esEdicion && codigo.isEmpty) {
        final String tok = await (widget.tokInterno ?? tokDeInstalacion)();
        codigoBarras =
            await proximoCodigoInterno(widget.baseDeDatos, tok: tok);
      }

      // T4: la escritura es local y queda encolada para la sync (regla de
      // sync 2). Si el código de barras ya existe localmente, el insert
      // lanza y se muestra el error de siempre.
      final Producto guardado = _esEdicion
          ? await editarProducto(
              widget.baseDeDatos,
              widget.producto!.id,
              codigoBarras: codigoBarras,
              nombre: nombre,
              marca: marca.isEmpty ? null : marca,
              unidad: _unidad,
              contenidoNeto: neto,
              pack: pack,
              categoria: categoria.isEmpty ? null : categoria,
              articuloId: _articuloId,
            )
          : await altaProducto(
              widget.baseDeDatos,
              nombre: nombre,
              codigoBarras: codigoBarras,
              marca: marca.isEmpty ? null : marca,
              unidad: _unidad,
              contenidoNeto: neto,
              pack: pack,
              categoria: categoria.isEmpty ? null : categoria,
              articuloId: _articuloId,
            );
      await guardarValoracion(
        widget.baseDeDatos,
        guardado.id,
        gusto: _gusto == 'neutro' ? null : _gusto,
        observacion: _observacion.text.trim().isEmpty
            ? null
            : _observacion.text.trim(),
      );
      widget.alGuardar?.call(guardado);
      if (mounted) Navigator.of(context).pop(guardado);
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error =
              'No se pudo guardar. ¿El código de barras ya existe en otro producto?';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (widget.datosIniciales != null) ...<Widget>[
            Text(
              'Datos precargados desde Open Food Facts — revisalos y confirmá antes de guardar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
              controller: _codigo,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Código de barras (opcional)',
                hintText: 'Ej.: 7790001001001',
                helperText: _esEdicion
                    ? null
                    : 'Vacío = se asigna un código interno (S-AB-0001)',
              ),
              validator: (String? v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                return RegExp(r'^\d{8,13}$').hasMatch(t)
                    ? null
                    : 'Solo dígitos (8 a 13)';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(labelText: 'Nombre del producto *'),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresá el nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _marca,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(labelText: 'Marca (opcional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unidad,
              decoration:
                  const InputDecoration(labelText: 'Unidad de venta *'),
              items: <DropdownMenuItem<String>>[
                for (final String u in unidadesDeVenta)
                  DropdownMenuItem<String>(value: u, child: Text(u)),
              ],
              onChanged: (String? u) => setState(() => _unidad = u ?? 'unidad'),
              validator: (String? u) =>
                  (u == null || u.isEmpty) ? 'Elegí la unidad' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contenido,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Contenido neto (opcional)',
                helperText: 'Vacío = 1 si es a granel (kg/L/m/unidad) — AD-014',
              ),
              validator: (String? v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                final n = double.tryParse(t.replaceAll(',', '.'));
                if (n == null) return 'Número inválido';
                if (n <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pack,
              keyboardType: TextInputType.number,
              // S5 (v0.3.8): el pack es cuántas unidades del contenido neto
              // trae la presentación; solo sirve para normalizar el precio.
              decoration: const InputDecoration(
                labelText: 'Unidades por pack',
                helperText:
                    'Cuántas unidades trae la presentación. Precio '
                    'normalizado = precio ÷ (pack × contenido por unidad). '
                    'Default: 1.',
              ),
              validator: (String? v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null; // vacío = 1
                final n = int.tryParse(t);
                if (n == null) return 'Ingresá un número entero';
                if (n < 1) return 'Debe ser 1 o más';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoria,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(labelText: 'Categoría (opcional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _articuloId,
              decoration:
                  const InputDecoration(labelText: 'Artículo (opcional)'),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Sin artículo'),
                ),
                for (final Articulo a in _articulos)
                  DropdownMenuItem<String>(value: a.id, child: Text(a.nombre)),
              ],
              onChanged: (String? a) => setState(() => _articuloId = a),
            ),
            const SizedBox(height: 20),
            Text('Mi valoración',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'neutro', label: Text('Neutro')),
                ButtonSegment<String>(
                    value: 'si', label: Text('Me gusta 👍')),
                ButtonSegment<String>(
                    value: 'no', label: Text('No me gusta 👎')),
              ],
              selected: <String>{_gusto},
              onSelectionChanged: (Set<String> sel) =>
                  setState(() => _gusto = sel.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacion,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 140,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mi observación (opcional)',
                hintText: 'Ej.: salió bueno, para repetir',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar producto'),
            ),
          ],
        ),
      ),
    );
  }
}
