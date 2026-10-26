import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/identidad.dart';
import '../../data/local/base_de_datos.dart';
import '../../data/local/normalizacion.dart';

/// S5 (R1/R7/R11): alta y edición de producto.
///
/// Campos: código (opcional, editable), nombre (obligatorio), marca,
/// unidad de venta, contenido neto (vacío = 1 para granel, AD-014),
/// categoría y artículo (opcional).
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({
    super.key,
    required this.baseDeDatos,
    this.producto,
    this.codigoBarrasInicial,
    this.alGuardar,
  });

  final BaseDeDatos baseDeDatos;
  final Producto? producto;
  final String? codigoBarrasInicial;
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
  late final TextEditingController _categoria;
  late String _unidad;
  String? _articuloId;
  List<Articulo> _articulos = <Articulo>[];
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _codigo = TextEditingController(
      text: widget.producto?.codigoBarras ?? widget.codigoBarrasInicial ?? '',
    );
    _nombre = TextEditingController(text: widget.producto?.nombre ?? '');
    _marca = TextEditingController(text: widget.producto?.marca ?? '');
    _contenido =
        TextEditingController(text: widget.producto?.contenidoNeto?.toString() ?? '');
    _categoria = TextEditingController(text: widget.producto?.categoria ?? '');
    _unidad = widget.producto?.unidad ?? 'unidad';
    _articuloId = widget.producto?.articuloId;
    _cargarArticulos();
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _marca.dispose();
    _contenido.dispose();
    _categoria.dispose();
    super.dispose();
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    final ahora = DateTime.now().toUtc().toIso8601String();
    final codigo = _codigo.text.trim();
    final nombre = _nombre.text.trim();
    final marca = _marca.text.trim();
    final categoria = _categoria.text.trim();
    final neto = _contenidoNetoNormalizado();

    try {
      Producto guardado;
      if (_esEdicion) {
        await (widget.baseDeDatos.update(widget.baseDeDatos.productos)
              ..where((t) => t.id.equals(widget.producto!.id)))
            .write(ProductosCompanion(
              codigoBarras: Value(codigo.isEmpty ? null : codigo),
              nombre: Value(nombre),
              marca: Value(marca.isEmpty ? null : marca),
              unidad: Value(_unidad),
              contenidoNeto: Value(neto),
              categoria: Value(categoria.isEmpty ? null : categoria),
              articuloId: Value(_articuloId),
              actualizadoEn: Value(ahora),
            ));
        guardado = await (widget.baseDeDatos.select(widget.baseDeDatos.productos)
              ..where((t) => t.id.equals(widget.producto!.id)))
            .getSingle();
      } else {
        final id = const Uuid().v4();
        final usuario = await usuarioActual(widget.baseDeDatos);
        await widget.baseDeDatos.into(widget.baseDeDatos.productos).insert(
              ProductosCompanion.insert(
                id: id,
                codigoBarras: Value(codigo.isEmpty ? null : codigo),
                nombre: nombre,
                unidad: _unidad,
                contenidoNeto: Value(neto),
                marca: Value(marca.isEmpty ? null : marca),
                categoria: Value(categoria.isEmpty ? null : categoria),
                articuloId: Value(_articuloId),
                creadoPor: usuario.id,
                creadoEn: ahora,
                actualizadoEn: ahora,
              ),
            );
        guardado = await (widget.baseDeDatos.select(widget.baseDeDatos.productos)
              ..where((t) => t.id.equals(id)))
            .getSingle();
      }
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
            TextFormField(
              controller: _codigo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de barras (opcional)',
                hintText: 'Ej.: 7790001001001',
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
