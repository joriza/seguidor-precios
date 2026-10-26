import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../../data/local/base_de_datos.dart';
import '../articulos/articulo_detalle_screen.dart';
import '../precios/producto_comparacion_screen.dart';

/// S12 (R1): búsqueda y listado por producto y por artículo.
///
/// Busca por nombre, marca o código (EAN) de producto y por nombre de
/// artículo. Cada producto muestra su último precio conocido (R1); el tap
/// lleva a la comparación (R13) o al detalle del artículo.
class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key, required this.baseDeDatos});

  final BaseDeDatos baseDeDatos;

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _ResultadoProductos {
  const _ResultadoProductos({required this.producto, this.ultimoPrecio});

  final Producto producto;

  /// Último precio conocido (R1): precio de la toma más reciente.
  final ({double precio, String comercio, String fecha})? ultimoPrecio;
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  final TextEditingController _controlador = TextEditingController();
  List<_ResultadoProductos> _productos = <_ResultadoProductos>[];
  List<Articulo> _articulos = <Articulo>[];
  Map<String, int> _productosPorArticulo = <String, int>{};
  String _consulta = '';
  int _peticion = 0;

  @override
  void initState() {
    super.initState();
    _cargarConteos();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _cargarConteos() async {
    final filas = await widget.baseDeDatos.customSelect(
      'SELECT articulo_id AS aid, COUNT(*) AS n FROM productos '
      'WHERE borrado_en IS NULL AND articulo_id IS NOT NULL '
      'GROUP BY articulo_id',
      readsFrom: {widget.baseDeDatos.productos},
    ).get();
    if (!mounted) return;
    setState(() {
      _productosPorArticulo = <String, int>{
        for (final f in filas) f.read<String>('aid'): f.read<int>('n'),
      };
    });
  }

  Future<void> _buscar(String consulta) async {
    final String q = consulta.trim();
    setState(() => _consulta = q);
    if (q.isEmpty) {
      setState(() {
        _productos = <_ResultadoProductos>[];
        _articulos = <Articulo>[];
      });
      return;
    }
    final int miaPeticion = ++_peticion;
    final patron = '%$q%';

    final productos = await (widget.baseDeDatos.select(
      widget.baseDeDatos.productos,
    )
          ..where((p) =>
              p.borradoEn.isNull() &
              (p.nombre.like(patron) |
                  p.marca.like(patron) |
                  p.codigoBarras.like(patron))))
        .get();

    final articulos = await (widget.baseDeDatos.select(
      widget.baseDeDatos.articulos,
    )
          ..where((a) => a.borradoEn.isNull() & a.nombre.like(patron)))
        .get();

    // Último precio conocido por producto (R1): la toma de fecha máxima.
    final ultimos = await widget.baseDeDatos.customSelect(
      'SELECT pr.producto_id AS pid, pr.precio AS precio, '
      'c.nombre AS comercio, pr.fecha_toma AS fecha '
      'FROM precios pr '
      'JOIN comercios c ON pr.comercio_id = c.id '
      'JOIN (SELECT producto_id, MAX(fecha_toma) AS fmax FROM precios '
      '      GROUP BY producto_id) m '
      'ON m.producto_id = pr.producto_id AND m.fmax = pr.fecha_toma',
      readsFrom: {
        widget.baseDeDatos.precios,
        widget.baseDeDatos.comercios,
      },
    ).get();
    final Map<String, ({double precio, String comercio, String fecha})>
        ultimoPorProducto = <String, ({double precio, String comercio, String fecha})>{
      for (final f in ultimos)
        f.read<String>('pid'): (
          precio: f.read<double>('precio'),
          comercio: f.read<String>('comercio'),
          fecha: f.read<String>('fecha'),
        ),
    };

    // Ignora respuestas de consultas viejas (el usuario siguió tipeando).
    if (!mounted || miaPeticion != _peticion) return;
    setState(() {
      _productos = productos
          .map((p) => _ResultadoProductos(
                producto: p,
                ultimoPrecio: ultimoPorProducto[p.id],
              ))
          .toList()
        ..sort((a, b) =>
            a.producto.nombre.toLowerCase().compareTo(
                  b.producto.nombre.toLowerCase(),
                ));
      _articulos = articulos.toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool sinConsulta = _consulta.isEmpty;
    final bool sinResultados =
        !sinConsulta && _productos.isEmpty && _articulos.isEmpty;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controlador,
            decoration: const InputDecoration(
              labelText: 'Buscar',
              hintText: 'Producto, marca, código o artículo',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _buscar,
          ),
        ),
        Expanded(
          child: sinConsulta
              ? const Center(
                  child: Text('Escribí para buscar por producto o artículo'))
              : sinResultados
                  ? const Center(child: Text('Sin resultados'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: <Widget>[
                        if (_productos.isNotEmpty) ...<Widget>[
                          const _Encabezado('Productos'),
                          for (final r in _productos) _filaProducto(r),
                        ],
                        if (_articulos.isNotEmpty) ...<Widget>[
                          const _Encabezado('Artículos'),
                          for (final a in _articulos) _filaArticulo(a),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _filaProducto(_ResultadoProductos r) {
    final p = r.producto;
    final String titulo =
        (p.marca == null || p.marca!.isEmpty) ? p.nombre : '${p.nombre} · ${p.marca}';
    final String codigo = p.codigoBarras ?? '';
    final ultimo = r.ultimoPrecio;
    return ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(titulo),
      subtitle: Text(
        ultimo == null
            ? (codigo.isEmpty ? 'Sin precios registrados' : '$codigo · sin precios')
            : '${codigo.isEmpty ? '' : '$codigo · '}'
                'Último: \$${ultimo.precio.toStringAsFixed(2)} · '
                '${ultimo.comercio} · ${ultimo.fecha}',
      ),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProductoComparacionScreen(
            baseDeDatos: widget.baseDeDatos,
            producto: p,
          ),
        ),
      ),
    );
  }

  Widget _filaArticulo(Articulo a) {
    final int n = _productosPorArticulo[a.id] ?? 0;
    return ListTile(
      leading: const Icon(Icons.category_outlined),
      title: Text(a.nombre),
      subtitle: Text('$n producto(s) · unidad base: ${a.unidadBase}'),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ArticuloDetalleScreen(
            baseDeDatos: widget.baseDeDatos,
            articulo: a,
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          texto,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
}
