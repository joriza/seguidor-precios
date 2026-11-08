import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/local/base_de_datos.dart';
import '../../data/local/normalizacion.dart';
import '../../data/normalizacion.dart';
import '../../data/productos.dart';
import '../articulos/agregados.dart';
import '../historial/historial_producto_screen.dart';
import '../productos/producto_form_screen.dart';

/// S9 (R13): comparación de UN producto (mismo EAN) entre comercios —
/// la comparación principal cuando el producto existe por su código.
/// v0.3.16 (T1/T2): encabezado por comercio con el ÚLTIMO precio de cada
/// uno (mínimo destacado como hoy), encabezado de tendencia (mín/prom/máx
/// por unidad base, Δ% vs toma anterior y sparkline) y filas densas de
/// 1 línea por toma con el detalle completo a un tap. Solo presentación
/// (S6): la consulta no cambia; las filas ya cargadas se proyectan.
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

/// Una toma ya cargada, proyectada para la UI (S6): sin consultas nuevas.
typedef _Toma = ({
  double precio,
  String comercio,
  String fecha,
  String cargadoEn,
});

class _ProductoComparacionScreenState
    extends State<ProductoComparacionScreen> {
  /// Tomas del producto ordenadas por precio (como venía la consulta).
  List<_Toma> _tomas = <_Toma>[];

  /// Variación % de cada toma contra su toma anterior del MISMO comercio.
  Map<int, double?> _variacionPorToma = <int, double?>{};
  bool _cargando = true;

  /// Índice de la fila densa con el detalle abierto (S3: a un tap).
  int? _filaExpandida;

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
    // S6: proyección de las filas ya cargadas — fecha y orden de carga
    // estaban en la misma fila; no se pide nada nuevo a la base.
    final List<_Toma> tomas = filas
        .map((f) => (
              precio: f.readTable(widget.baseDeDatos.precios).precio,
              comercio: f.readTable(widget.baseDeDatos.comercios).nombre,
              fecha: f.readTable(widget.baseDeDatos.precios).fechaToma,
              cargadoEn: f.readTable(widget.baseDeDatos.precios).cargadoEn,
            ))
        .toList();

    setState(() {
      _tomas = tomas;
      _variacionPorToma = _calcularVariaciones(tomas);
      _filaExpandida = null;
      _cargando = false;
    });
  }

  /// Variación de cada toma contra su toma anterior del mismo comercio
  /// (R8), sobre las filas ya cargadas. Sin comercio previo → null.
  Map<int, double?> _calcularVariaciones(List<_Toma> tomas) {
    final Map<String, List<int>> porComercio = <String, List<int>>{};
    for (int i = 0; i < tomas.length; i++) {
      porComercio.putIfAbsent(tomas[i].comercio, () => <int>[]).add(i);
    }
    final Map<int, double?> resultado = <int, double?>{};
    for (final List<int> indices in porComercio.values) {
      final List<int> orden = indices.toList()
        ..sort((int a, int b) {
          final int porFecha = tomas[a].fecha.compareTo(tomas[b].fecha);
          return porFecha != 0
              ? porFecha
              : tomas[a].cargadoEn.compareTo(tomas[b].cargadoEn);
        });
      for (int j = 0; j < orden.length; j++) {
        resultado[orden[j]] = j == 0
            ? null
            : variacionPorcentual(
                tomas[orden[j - 1]].precio,
                tomas[orden[j]].precio,
              );
      }
    }
    return resultado;
  }

  /// Tomas ordenadas cronológicamente (fecha, luego carga): serie de tendencia.
  List<_Toma> get _cronologicas {
    final List<_Toma> orden = _tomas.toList()
      ..sort((_Toma a, _Toma b) {
        final int porFecha = a.fecha.compareTo(b.fecha);
        return porFecha != 0 ? porFecha : a.cargadoEn.compareTo(b.cargadoEn);
      });
    return orden;
  }

  /// Serie del encabezado de tendencia (S4): por unidad base cuando el
  /// producto es comparable, o precio absoluto como reserva.
  ({List<double> valores, String? base}) get _serieTendencia {
    final List<_Toma> cronologicas = _cronologicas;
    final List<double> crudos = cronologicas.map((t) => t.precio).toList();
    final String? base = unidadBaseDe(_producto.unidad);
    if (base == null) return (valores: crudos, base: null);

    final List<double> unitarios = <double>[];
    for (final _Toma toma in cronologicas) {
      final double? unitario = precioPorUnidad(
        precio: toma.precio,
        unidad: _producto.unidad,
        unidadBase: base,
        contenidoNeto: _producto.contenidoNeto,
        pack: _producto.pack,
      );
      if (unitario == null) return (valores: crudos, base: null);
      unitarios.add(unitario);
    }
    return (valores: unitarios, base: base);
  }

  /// S5: la última toma de cada comercio, de menor a mayor precio.
  List<_Toma> get _ultimosPorComercio {
    final Map<String, _Toma> ultimos = <String, _Toma>{};
    for (final _Toma toma in _tomas) {
      final _Toma? actual = ultimos[toma.comercio];
      final bool masNueva = actual == null ||
          toma.fecha.compareTo(actual.fecha) > 0 ||
          (toma.fecha == actual.fecha &&
              toma.cargadoEn.compareTo(actual.cargadoEn) > 0);
      if (masNueva) ultimos[toma.comercio] = toma;
    }
    final List<_Toma> lista = ultimos.values.toList()
      ..sort((a, b) => a.precio.compareTo(b.precio));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // S5 (v0.3.8): «Pack ×N» desambigua la presentación (N > 1).
        title: Text('${_producto.nombre}${sufijoPack(_producto.pack)}'),
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
    if (_tomas.isEmpty) {
      return const Center(
        child: Text('Sin precios registrados todavía'),
      );
    }
    final List<_Toma> ultimos = _ultimosPorComercio;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // 0: tendencia (S4), 1: último precio por comercio (S5), resto: tomas.
      itemCount: _tomas.length + 2,
      itemBuilder: (BuildContext contexto, int i) {
        if (i == 0) return _tarjetaTendencia();
        if (i == 1) return _encabezadoComercios(ultimos);
        return _filaDensa(i - 2);
      },
    );
  }

  /// S4: encabezado de tendencia — mín/prom/máx por unidad base
  /// (agregados.dart), Δ% vs toma anterior y sparkline de las últimas
  /// ~10 tomas.
  Widget _tarjetaTendencia() {
    final (:valores, :base) = _serieTendencia;
    final AgregadosArticulo? agregados = agregar(valores);
    if (agregados == null) return const SizedBox.shrink();
    final List<_Toma> cronologicas = _cronologicas;
    final double? delta = cronologicas.length >= 2
        ? variacionPorcentual(
            cronologicas[cronologicas.length - 2].precio,
            cronologicas.last.precio,
          )
        : null;
    String valor(String monto) =>
        base == null ? '\$$monto' : '$monto / $base';

    return Card(
      key: const ValueKey('tarjeta-tendencia'),
      margin: const EdgeInsets.only(bottom: 8),
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

  /// S5: encabezado con el último precio por comercio; el mínimo
  /// destacado como hoy (🏆 + «MÍNIMO»).
  Widget _encabezadoComercios(List<_Toma> ultimos) {
    return Card(
      key: const ValueKey('encabezado-comercios'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < ultimos.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    i == 0
                        ? const Icon(Icons.emoji_events, size: 20)
                        : const Icon(Icons.storefront, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ultimos[i].comercio)),
                    Text(
                      '\$${ultimos[i].precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (i == 0) ...<Widget>[
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: 'Más económico',
                        child: Text(
                          'MÍNIMO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// T1 (S3): fila densa de 1 línea por toma; el detalle completo queda
  /// a un tap y no se borra nada.
  Widget _filaDensa(int indice) {
    final _Toma toma = _tomas[indice];
    final double? variacion = _variacionPorToma[indice];
    final bool expandida = _filaExpandida == indice;

    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            '\$${toma.precio.toStringAsFixed(2)} · ${toma.comercio} · '
            '${fechaCorta(toma.fecha)}',
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
              setState(() => _filaExpandida = expandida ? null : indice),
        ),
        if (expandida) _detalleDeToma(toma),
      ],
    );
  }

  /// Detalle completo de la toma (S3): fecha cruda y precio por unidad
  /// cuando la presentación es comparable.
  Widget _detalleDeToma(_Toma toma) {
    final String? base = unidadBaseDe(_producto.unidad);
    final double? unitario = base == null
        ? null
        : precioPorUnidad(
            precio: toma.precio,
            unidad: _producto.unidad,
            unidadBase: base,
            contenidoNeto: _producto.contenidoNeto,
            pack: _producto.pack,
          );
    final String unitarioTexto = unitario == null
        ? ''
        : ' · Precio por unidad: ${unitario.toStringAsFixed(2)} / $base';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Fecha completa: ${toma.fecha}$unitarioTexto',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
