import 'dart:math' as math;

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../data/local/base_de_datos.dart';
import '../../../data/local/normalizacion.dart';
import '../../../data/normalizacion.dart';
import '../articulos/agregados.dart';

/// S10 (R8): histórico cronológico de un producto, con variación % entre
/// tomas consecutivas y filtro opcional por comercio.
/// v0.3.16 (T1/T2): filas densas de 1 línea (precio · comercio · fecha
/// corta, variación % al final y detalle completo a un tap) y encabezado
/// de tendencia (mín/prom/máx por unidad base, Δ% vs toma anterior y
/// sparkline). Solo presentación (S6): las consultas existentes no cambian;
/// se agrega UNA lectura de solo lectura de la presentación del producto
/// para poder expresar los agregados por unidad base.
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

  /// Presentación del producto (v0.3.16): unidad, contenido y pack para
  /// normalizar los agregados por unidad base. Lectura única (S6).
  Producto? _producto;

  /// Índice de la fila densa con el detalle abierto (S3: a un tap).
  int? _filaExpandida;

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

    // v0.3.16 (S6): lectura única de la presentación, para la unidad base
    // del encabezado de tendencia. No escribe ni altera las consultas de arriba.
    final Producto? producto = await (widget.baseDeDatos.select(
      widget.baseDeDatos.productos,
    )..where((p) => p.id.equals(widget.productoId))).getSingleOrNull();

    if (!mounted) return;
    setState(() {
      _comerciosConPrecios =
          nombres.map((f) => f.read<String>('comercio')).toList();
      _filas = filtrada.map((f) => f.data).toList();
      _producto = producto;
      _filaExpandida = null;
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

  /// Serie del encabezado de tendencia (S4): precios por unidad base cuando
  /// el producto es comparable (todas sus tomas se normalizan igual) o
  /// precio absoluto como reserva.
  ({List<double> valores, String? base}) get _serieTendencia {
    final List<double> crudos = _filas
        .map((fila) => (fila['precio'] as num).toDouble())
        .toList();
    final Producto? p = _producto;
    if (p == null) return (valores: crudos, base: null);
    final String? base = unidadBaseDe(p.unidad);
    if (base == null) return (valores: crudos, base: null);

    final List<double> unitarios = <double>[];
    for (final Map<String, dynamic> fila in _filas) {
      final double? unitario = precioPorUnidad(
        precio: (fila['precio'] as num).toDouble(),
        unidad: p.unidad,
        unidadBase: base,
        contenidoNeto: p.contenidoNeto,
        pack: p.pack,
      );
      if (unitario == null) return (valores: crudos, base: null);
      unitarios.add(unitario);
    }
    return (valores: unitarios, base: base);
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
          if (!_cargando && _filas.isNotEmpty) _tarjetaTendencia(),
          Expanded(child: _lista(indicesDesc)),
        ],
      ),
    );
  }

  /// T2 (S4): encabezado de tendencia — mín/prom/máx por unidad base
  /// (agregados.dart), Δ% vs toma anterior y sparkline de las últimas
  /// ~10 tomas.
  Widget _tarjetaTendencia() {
    final (:valores, :base) = _serieTendencia;
    final AgregadosArticulo? agregados = agregar(valores);
    if (agregados == null) return const SizedBox.shrink();
    final double? delta =
        _filas.length >= 2 ? _variacionDe(_filas.length - 1) : null;
    String valor(String monto) =>
        base == null ? '\$$monto' : '$monto / $base';

    return Card(
      key: const ValueKey('tarjeta-tendencia'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _dato('Mínimo', valor(agregados.minimo.toStringAsFixed(2))),
                _dato('Promedio', valor(agregados.promedio.toStringAsFixed(2))),
                _dato('Máximo', valor(agregados.maximo.toStringAsFixed(2))),
              ],
            ),
            if (delta != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% '
                  'vs toma anterior',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        // Suba = mala noticia para el bolsillo (como en filas).
                        color: delta >= 0
                            ? Theme.of(context).colorScheme.error
                            : Colors.green,
                      ),
                ),
              ),
            const SizedBox(height: 8),
            SparklineTendencia(
              valores: valores.length > 10
                  ? valores.sublist(valores.length - 10)
                  : valores,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String etiqueta, String valor) => Column(
        children: <Widget>[
          Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );

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
        final String comercio = fila['comercio'] as String;
        final bool expandida = _filaExpandida == i;

        // T1 (S3): fila densa de 1 línea; el detalle completo queda a un
        // tap y no se borra nada.
        return Column(
          children: <Widget>[
            ListTile(
              title: Text(
                '\$${precio.toStringAsFixed(2)} · $comercio · '
                '${fechaCorta(fila['fecha'] as String?)}',
              ),
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
              onTap: () =>
                  setState(() => _filaExpandida = expandida ? null : i),
            ),
            if (expandida) _detalleDeToma(fila, precio),
          ],
        );
      },
    );
  }

  /// Detalle completo de la toma (S3): fecha cruda y precio por unidad
  /// cuando la presentación es comparable.
  Widget _detalleDeToma(Map<String, dynamic> fila, double precio) {
    final Producto? p = _producto;
    final String? base = p == null ? null : unidadBaseDe(p.unidad);
    double? unitario;
    if (p != null && base != null) {
      unitario = precioPorUnidad(
        precio: precio,
        unidad: p.unidad,
        unidadBase: base,
        contenidoNeto: p.contenidoNeto,
        pack: p.pack,
      );
    }
    final String unitarioTexto = unitario == null
        ? ''
        : ' · Precio por unidad: ${unitario.toStringAsFixed(2)} / $base';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Fecha completa: ${fila['fecha']}$unitarioTexto',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// S4 (v0.3.16): sparkline en línea de la serie de precios (últimas ~10
/// tomas). Degrada con elegancia: sin tomas no dibuja nada y con una sola
/// dibuja un punto. Compartida por el cronológico y la ficha de comparación.
class SparklineTendencia extends StatelessWidget {
  const SparklineTendencia({
    super.key,
    required this.valores,
    this.height = 36,
  });

  final List<double> valores;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PintorSparkline(
          valores,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _PintorSparkline extends CustomPainter {
  const _PintorSparkline(this.valores, {required this.color});

  final List<double> valores;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double margen = 4;
    if (valores.length == 1) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        3,
        Paint()..color = color,
      );
      return;
    }

    final double minimo = valores.reduce(math.min);
    final double maximo = valores.reduce(math.max);
    final double rango = maximo - minimo;

    Offset punto(int i) => Offset(
          margen + (size.width - 2 * margen) * i / (valores.length - 1),
          rango == 0
              ? size.height / 2
              : margen +
                  (size.height - 2 * margen) *
                      (1 - (valores[i] - minimo) / rango),
        );

    final Path camino = Path()..moveTo(punto(0).dx, punto(0).dy);
    for (int i = 1; i < valores.length; i++) {
      camino.lineTo(punto(i).dx, punto(i).dy);
    }
    canvas.drawPath(
      camino,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Punto final marcado: la toma más reciente.
    canvas.drawCircle(punto(valores.length - 1), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PintorSparkline oldDelegate) =>
      !listEquals(oldDelegate.valores, valores);
}
