import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/local/base_de_datos.dart';
import '../productos/producto_form_screen.dart';

/// S9 (R13): comparación de UN producto (mismo EAN) entre comercios —
/// la comparación principal cuando el producto existe por su código.
/// Precios ordenados de menor a mayor, mínimo resaltado.
class ProductoComparacionScreen extends StatefulWidget {
  const ProductoComparacionScreen({
    super.key,
    required this.baseDeDatos,
    required this.producto,
  });

  final BaseDeDatos baseDeDatos;
  final Producto producto;

  @override
  State<ProductoComparacionScreen> createState() =>
      _ProductoComparacionScreenState();
}

class _ProductoComparacionScreenState
    extends State<ProductoComparacionScreen> {
  List<double> _preciosOrdenados = <double>[];
  Map<double, String> _comercioPorPrecio = <double, String>{};
  bool _cargando = true;

  /// v0.1.4: copia editable del producto (el dueño puede corregir o
  /// completar datos del semillero; los cambios valen para consultas).
  late Producto _producto = widget.producto;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _editarDatos() async {
    final guardado = await Navigator.of(context).push<Producto>(
      MaterialPageRoute<Producto>(
        builder: (_) => ProductoFormScreen(
          baseDeDatos: widget.baseDeDatos,
          producto: _producto,
        ),
      ),
    );
    if (!mounted) return;
    if (guardado != null) {
      setState(() => _producto = guardado);
    }
    _cargar();
  }

  Future<void> _cargar() async {
    final filas = await (widget.baseDeDatos.select(widget.baseDeDatos.precios)
          .join([
          innerJoin(widget.baseDeDatos.comercios,
              widget.baseDeDatos.comercios.id
                  .equalsExp(widget.baseDeDatos.precios.comercioId)),
        ])
          ..where(widget.baseDeDatos.precios.productoId
              .equals(widget.producto.id))
          ..orderBy([OrderingTerm.asc(widget.baseDeDatos.precios.precio)]))
        .get();

    if (!mounted) return;
    setState(() {
      _preciosOrdenados =
          filas.map((f) => f.readTable(widget.baseDeDatos.precios).precio).toList();
      _comercioPorPrecio = <double, String>{
        for (final f in filas)
          f.readTable(widget.baseDeDatos.precios).precio:
              f.readTable(widget.baseDeDatos.comercios).nombre,
      };
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_producto.nombre),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar datos',
            onPressed: _editarDatos,
          ),
        ],
      ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_preciosOrdenados.isEmpty) {
      return const Center(
        child: Text('Sin precios registrados todavía'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _preciosOrdenados.length,
      itemBuilder: (BuildContext contexto, int i) {
        final double precio = _preciosOrdenados[i];
        final bool esMinimo = i == 0;
        return Card(
          color: esMinimo
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          child: ListTile(
            leading: esMinimo
                ? const Icon(Icons.emoji_events, size: 32)
                : const Icon(Icons.storefront, size: 32),
            title: Text(
              '\$${precio.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_comercioPorPrecio[precio] ?? ''),
            trailing: esMinimo
                ? const Tooltip(
                    message: 'Más económico',
                    child: Text('MÍNIMO',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                : null,
          ),
        );
      },
    );
  }
}
