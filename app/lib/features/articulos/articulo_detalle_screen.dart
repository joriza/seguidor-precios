import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../data/local/base_de_datos.dart';
import '../../../data/local/normalizacion.dart';
import '../precios/comparador.dart';

/// S9 (R11/R13): comparador de un artículo — sus productos ordenados por
/// precio por unidad de medida, con el mínimo resaltado.
class ArticuloDetalleScreen extends StatefulWidget {
  const ArticuloDetalleScreen({
    super.key,
    required this.baseDeDatos,
    required this.articulo,
  });

  final BaseDeDatos baseDeDatos;
  final Articulo articulo;

  @override
  State<ArticuloDetalleScreen> createState() => _ArticuloDetalleScreenState();
}

class _ArticuloDetalleScreenState extends State<ArticuloDetalleScreen> {
  List<FilaComparacion> _filas = <FilaComparacion>[];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final filas = await widget.baseDeDatos.customSelect(
      'SELECT p.nombre AS producto_nombre, p.marca AS producto_marca, '
      'c.nombre AS comercio_nombre, pr.precio AS precio, p.unidad AS unidad, '
      'p.contenido_neto AS contenido_neto, a.unidad_base AS unidad_base '
      'FROM precios pr '
      'JOIN productos p ON pr.producto_id = p.id '
      'JOIN comercios c ON pr.comercio_id = c.id '
      'JOIN articulos a ON p.articulo_id = a.id '
      'WHERE p.articulo_id = ? AND p.borrado_en IS NULL '
      'AND c.borrado_en IS NULL AND a.borrado_en IS NULL',
      variables: [Variable.withString(widget.articulo.id)],
      readsFrom: {
        widget.baseDeDatos.precios,
        widget.baseDeDatos.productos,
        widget.baseDeDatos.comercios,
        widget.baseDeDatos.articulos,
      },
    ).get();

    final resultado = <FilaComparacion>[];
    for (final fila in filas) {
      final double? precioUnitario = precioPorUnidad(
        precio: fila.read<double>('precio'),
        unidad: fila.read<String>('unidad'),
        unidadBase: fila.read<String>('unidad_base'),
        contenidoNeto: fila.read<double?>('contenido_neto'),
      );
      if (precioUnitario == null) continue;
      resultado.add(FilaComparacion(
        productoNombre: fila.read<String>('producto_nombre'),
        marca: fila.read<String?>('producto_marca'),
        comercioNombre: fila.read<String>('comercio_nombre'),
        precio: fila.read<double>('precio'),
        precioUnitario: precioUnitario,
      ));
    }

    if (!mounted) return;
    setState(() {
      _filas = ordenarPorPrecioUnitario(resultado);
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.articulo.nombre)),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filas.isEmpty) {
      return const Center(
        child: Text(
          'Sin precios comparables todavía.\n'
          'Registrá precios de productos con contenido neto y artículo asignado.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filas.length,
      itemBuilder: (BuildContext contexto, int i) {
        final FilaComparacion fila = _filas[i];
        final bool esMinimo = i == 0;
        return Card(
          color: esMinimo
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          child: ListTile(
            leading: esMinimo
                ? const Icon(Icons.emoji_events, size: 32)
                : const Icon(Icons.sell, size: 32),
            title: Text(
              '${fila.precioUnitario.toStringAsFixed(2)} / ${widget.articulo.unidadBase}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${fila.etiquetaProducto}\n'
              '${fila.comercioNombre} · \$${fila.precio.toStringAsFixed(2)}',
            ),
            isThreeLine: true,
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
