import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/local/base_de_datos.dart';
import '../../data/precios.dart';
import '../comercios/alta_comercio_dialog.dart';

/// S8 (R8/R1): registro de precio de un producto — append-only.
/// Comercio: existente o creado en el momento (R9). Fecha de toma: hoy por
/// defecto, editable, sin fechas futuras.
class RegistroPrecioScreen extends StatefulWidget {
  const RegistroPrecioScreen({
    super.key,
    required this.baseDeDatos,
    required this.producto,
  });

  final BaseDeDatos baseDeDatos;
  final Producto producto;

  @override
  State<RegistroPrecioScreen> createState() => _RegistroPrecioScreenState();
}

class _RegistroPrecioScreenState extends State<RegistroPrecioScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  DateTime _fechaToma = DateTime.now();
  String? _comercioId;
  List<Comercio> _comercios = <Comercio>[];
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fechaController.text = _formatoFecha(_fechaToma);
    _cargarComercios();
  }

  @override
  void dispose() {
    _precioController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  String _formatoFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _cargarComercios() async {
    final lista = await (widget.baseDeDatos.select(widget.baseDeDatos.comercios)
          ..where((t) => t.borradoEn.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.nombre)]))
        .get();
    if (!mounted) return;
    setState(() {
      _comercios = lista;
      // Comodidad: si hay un único comercio, queda preseleccionado.
      if (_comercioId == null && lista.length == 1) {
        _comercioId = lista.single.id;
      }
    });
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaToma,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida == null) return;
    setState(() {
      _fechaToma = elegida;
      _fechaController.text = _formatoFecha(elegida);
    });
  }

  Future<void> _nuevoComercio() async {
    final creado = await mostrarAltaComercio(context, widget.baseDeDatos);
    if (creado == null) return;
    await _cargarComercios();
    if (mounted) setState(() => _comercioId = creado.id);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    final valor = double.parse(_precioController.text.trim().replaceAll(',', '.'));
    final precio = (valor * 100).roundToDouble() / 100;

    try {
      // T4: local primero y encolado para la sync (regla de sync 2); el
      // precio es append-only (regla de sync 4).
      await registrarPrecio(
        widget.baseDeDatos,
        productoId: widget.producto.id,
        comercioId: _comercioId!,
        precio: precio,
        fechaToma: _fechaController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'No se pudo registrar el precio. Probá de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar precio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(widget.producto.nombre),
                subtitle: widget.producto.codigoBarras == null
                    ? null
                    : Text(widget.producto.codigoBarras!),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio *',
                prefixText: r'$ ',
                border: OutlineInputBorder(),
              ),
              validator: (String? v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Ingresá el precio';
                final n = double.tryParse(t.replaceAll(',', '.'));
                if (n == null) return 'Número inválido';
                if (n <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _comercioId,
              decoration: const InputDecoration(
                labelText: 'Comercio *',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                for (final Comercio c in _comercios)
                  DropdownMenuItem<String>(value: c.id, child: Text(c.nombre)),
              ],
              onChanged: (String? c) => setState(() => _comercioId = c),
              validator: (String? c) =>
                  (c == null) ? 'Elegí o creá un comercio' : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _nuevoComercio,
                icon: const Icon(Icons.add_business),
                label: const Text('Crear comercio'),
              ),
            ),
            TextFormField(
              controller: _fechaController,
              readOnly: true,
              onTap: _elegirFecha,
              decoration: const InputDecoration(
                labelText: 'Fecha de toma *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                helperText: 'Hoy por defecto; se puede editar',
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
              icon: const Icon(Icons.check),
              label: const Text('Registrar precio'),
            ),
          ],
        ),
      ),
    );
  }
}
