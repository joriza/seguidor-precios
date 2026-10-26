import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../data/local/base_de_datos.dart';
import '../../../data/local/normalizacion.dart';

/// S10 (R8): histórico cronológico de un producto, con variación % entre
/// tomas consecutivas y filtro opcional por comercio.
class HistorialProductoScreen extends StatefulWidget {
  const HistorialProductoScreen({
    super.key,
    required this.baseDeDatos,
    required this.productoId,
    required this.nombre,
  });

  final BaseDeDatos baseDeDatos;
  final String productoId;
  final String nombre;

  @override
  State<HistorialProductoScreen> createState() =>
      _HistorialProductoScreenState();
}

class _HistorialProductoScreenState extends State<HistorialProductoScreen> {
  /// Cronológico ascendente: filas[i] es la toma más vieja hasta la más nueva.
  List<Map<String, dynamic>> _filas = <Map<String, dynamic>>[];
  List<String> _comerciosConPrecios = <String>[];
  String? _comercioSeleccionado;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    const String consultaBase =
        'SELECT pr.precio AS precio, c.nombre AS comercio, '
        'pr.fecha_toma AS fecha FROM precios pr '
        'JOIN comercios c ON pr.comercio_id = c.id '
        'WHERE pr.producto_id = ? ';

    // Nombres de comercio presentes (para el filtro, sin filtrar).
    final nombres = await widget.baseDeDatos.customSelect(
      'SELECT DISTINCT c.nombre AS comercio FROM precios pr '
      'JOIN comercios c ON pr.comercio_id = c.id '
      'WHERE pr.producto_id = ? ORDER BY comercio',
      variables: [Variable.withString(widget.productoId)],
      readsFrom: {
        widget.baseDeDatos.precios,
        widget.baseDeDatos.comercios,
      },
    ).get();

    final filtrada = await widget.baseDeDatos.customSelect(
      '$consultaBase ${_comercioSeleccionado == null ? '' : 'AND c.nombre = ? '}'
      'ORDER BY pr.fecha_toma ASC, pr.cargado_en ASC',
      variables: <Variable>[
        Variable.withString(widget.productoId),
        if (_comercioSeleccionado != null)
          Variable.withString(_comercioSeleccionado!),
      ],
      readsFrom: {
        widget.baseDeDatos.precios,
        widget.baseDeDatos.comercios,
      },
    ).get();

    if (!mounted) return;
    setState(() {
      _comerciosConPrecios =
          nombres.map((f) => f.read<String>('comercio')).toList();
      _filas = filtrada.map((f) => f.data).toList();
      _cargando = false;
    });
  }

  /// Variación de la fila [i] respecto de su toma anterior (cronológico).
  double? _variacionDe(int i) {
    if (i == 0) return null;
    return variacionPorcentual(
      (_filas[i - 1]['precio'] as num).toDouble(),
      (_filas[i]['precio'] as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mostramos de la más nueva a la más vieja.
    final List<int> indicesDesc =
        List<int>.generate(_filas.length, (int i) => i).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _comercioSeleccionado,
              decoration:
                  const InputDecoration(labelText: 'Filtrar por comercio'),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos los comercios'),
                ),
                for (final String c in _comerciosConPrecios)
                  DropdownMenuItem<String>(value: c, child: Text(c)),
              ],
              onChanged: (String? c) {
                _comercioSeleccionado = c;
                _cargando = true;
                _cargar();
              },
            ),
          ),
          Expanded(child: _lista(indicesDesc)),
        ],
      ),
    );
  }

  Widget _lista(List<int> indicesDesc) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filas.isEmpty) {
      return const Center(
        child: Text('Sin precios para el filtro seleccionado'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: indicesDesc.length,
      itemBuilder: (BuildContext contexto, int posicion) {
        final int i = indicesDesc[posicion];
        final Map<String, dynamic> fila = _filas[i];
        final double precio = (fila['precio'] as num).toDouble();
        final double? variacion = _variacionDe(i);

        return ListTile(
          leading: const Icon(Icons.sell),
          title: Text(
            '\$${precio.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${fila['comercio']} · ${fila['fecha']}'),
          trailing: variacion == null
              ? null
              : Text(
                  '${variacion >= 0 ? '+' : ''}${variacion.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: variacion >= 0
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                  ),
                ),
        );
      },
    );
  }
}
