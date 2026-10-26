import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../data/local/base_de_datos.dart';
import '../../../data/local/normalizacion.dart';
import '../precios/comparador.dart';
import 'agregados.dart';

/// S9 (R11/R13): comparador de un artículo — sus productos ordenados por
/// precio por unidad de medida, con el mínimo resaltado.
/// S11 (R12): agregados mínimo/promedio/máximo con ventana de 30 días
/// por defecto o histórico completo, y filtro por comercio.
class ArticuloDetalleScreen extends StatefulWidget {
  const ArticuloDetalleScreen({
    super.key,
    required this.baseDeDatos,
    required this.articulo,
    this.hoy,
  });

  final BaseDeDatos baseDeDatos;
  final Articulo articulo;

  /// Fecha de referencia para la ventana de 30 días (inyectable en tests).
  final DateTime? hoy;

  @override
  State<ArticuloDetalleScreen> createState() => _ArticuloDetalleScreenState();
}

class _ArticuloDetalleScreenState extends State<ArticuloDetalleScreen> {
  List<FilaComparacion> _filas = <FilaComparacion>[];
  bool _cargando = true;

  // S11: precios por unidad comparables con fecha y comercio, base de los
  // agregados; los filtros (ventana/comercio) se aplican sobre esta lista.
  List<_PrecioComparable> _comparables = <_PrecioComparable>[];
  List<({String id, String nombre})> _comerciosConPrecios =
      <({String id, String nombre})>[];
  bool _historico = false;
  String? _comercioSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final filas = await widget.baseDeDatos.customSelect(
      'SELECT p.nombre AS producto_nombre, p.marca AS producto_marca, '
      'c.nombre AS comercio_nombre, pr.precio AS precio, p.unidad AS unidad, '
      'p.contenido_neto AS contenido_neto, a.unidad_base AS unidad_base, '
      'pr.fecha_toma AS fecha_toma, pr.comercio_id AS comercio_id '
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
    final comparables = <_PrecioComparable>[];
    final comercios = <String, String>{};
    for (final fila in filas) {
      final double? precioUnitario = precioPorUnidad(
        precio: fila.read<double>('precio'),
        unidad: fila.read<String>('unidad'),
        unidadBase: fila.read<String>('unidad_base'),
        contenidoNeto: fila.read<double?>('contenido_neto'),
      );
      if (precioUnitario == null) continue;
      final String comercioId = fila.read<String>('comercio_id');
      comercios[comercioId] = fila.read<String>('comercio_nombre');
      comparables.add(_PrecioComparable(
        precioUnitario: precioUnitario,
        fechaToma: fila.read<String>('fecha_toma'),
        comercioId: comercioId,
      ));
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
      _comparables = comparables;
      _comerciosConPrecios = comercios.entries
          .map((e) => (id: e.key, nombre: e.value))
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      _cargando = false;
    });
  }

  /// Agregados S11 según la ventana y el comercio elegidos (R12).
  AgregadosArticulo? get _agregados {
    final DateTime hoy = widget.hoy ?? DateTime.now();
    final String? limite = _historico ? null : inicioDeVentana(hoy);
    return agregar(_comparables
        .where((p) => limite == null || p.fechaToma.compareTo(limite) >= 0)
        .where((p) =>
            _comercioSeleccionado == null ||
            p.comercioId == _comercioSeleccionado)
        .map((p) => p.precioUnitario)
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.articulo.nombre)),
      body: Column(
        children: <Widget>[
          _seccionAgregados(),
          const Divider(height: 1),
          Expanded(child: _cuerpo()),
        ],
      ),
    );
  }

  /// S11 (R12): ventana 30 días/histórico + filtro por comercio y card de
  /// agregados. No afecta al comparador de abajo (R11/R13).
  Widget _seccionAgregados() {
    final AgregadosArticulo? agregados = _cargando ? null : _agregados;
    final String base = widget.articulo.unidadBase;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _historico ? 'historico' : '30',
                  decoration: const InputDecoration(labelText: 'Ventana'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                        value: '30', child: Text('Últimos 30 días')),
                    DropdownMenuItem<String>(
                        value: 'historico', child: Text('Histórico')),
                  ],
                  onChanged: (String? v) => setState(
                      () => _historico = v == 'historico'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _comercioSeleccionado,
                  decoration:
                      const InputDecoration(labelText: 'Comercio'),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos los comercios'),
                    ),
                    for (final (:id, :nombre) in _comerciosConPrecios)
                      DropdownMenuItem<String>(
                          value: id, child: Text(nombre)),
                  ],
                  onChanged: (String? id) =>
                      setState(() => _comercioSeleccionado = id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (agregados == null)
            // Sin comparables en absoluto: el estado vacío del comparador ya
            // lo explica. Con datos pero filtro vacío: mensaje propio.
            if (_comparables.isEmpty)
              const SizedBox.shrink()
            else
              const Text('Sin precios para el filtro seleccionado',
                  textAlign: TextAlign.center)
          else
            Card(
              key: const ValueKey('agregados-card'),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _agregado('Mínimo', agregados.minimo, base),
                    _agregado('Promedio', agregados.promedio, base),
                    _agregado('Máximo', agregados.maximo, base),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _agregado(String etiqueta, double valor, String base) => Column(
        children: <Widget>[
          Text(etiqueta,
              style: Theme.of(context).textTheme.labelSmall),
          Text(
            '${valor.toStringAsFixed(2)} / $base',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );

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

/// Precio por unidad comparable con su fecha de toma y comercio, insumo de
/// los agregados S11.
class _PrecioComparable {
  const _PrecioComparable({
    required this.precioUnitario,
    required this.fechaToma,
    required this.comercioId,
  });

  final double precioUnitario;
  final String fechaToma;
  final String comercioId;
}
