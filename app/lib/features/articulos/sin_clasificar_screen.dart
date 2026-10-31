import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/articulos.dart';
import '../../data/clasificacion.dart';
import '../../data/local/base_de_datos.dart';
import '../../data/local/normalizacion.dart';
import '../../data/productos.dart';

/// v0.3.9 (S2): clasificación de productos sin artículo.
///
/// Lista los productos con articulo_id NULL y sin baja (S3: los borrados
/// nunca aparecen) con nombre, marca, código y chips de sugerencia del
/// motor puro (S1). Modo individual: tocar un chip asigna ese artículo.
/// Modo lote: selección múltiple + UN artículo destino (existente o de
/// alta nuevo) + confirmación antes de aplicar. La asignación toca SOLO
/// articulo_id (S3) y viaja por la sync normal (encolar, regla de sync 2).
class SinClasificarScreen extends StatefulWidget {
  const SinClasificarScreen({super.key, required this.baseDeDatos});

  final BaseDeDatos baseDeDatos;

  @override
  State<SinClasificarScreen> createState() => _SinClasificarScreenState();
}

/// Marca interna del diálogo destino: el dueño eligió «crear artículo
/// nuevo» en lugar de un artículo existente.
class _DestinoNuevo {
  const _DestinoNuevo();
}

class _SinClasificarScreenState extends State<SinClasificarScreen> {
  /// S2: máximo de chips de sugerencia por producto; el resto de los
  /// matches sigue alcanzable (asignar desde el artículo o crear uno).
  static const int maxSugerenciasPorProducto = 3;

  List<Producto> _productos = <Producto>[];
  List<Articulo> _articulos = <Articulo>[];
  final Set<String> _seleccionados = <String>{};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    // S3: solo sin artículo y sin baja, orden fijo por nombre.
    final productos =
        await (widget.baseDeDatos.select(widget.baseDeDatos.productos)
              ..where((t) => t.articuloId.isNull())
              ..where((t) => t.borradoEn.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.nombre)]))
            .get();
    final articulos =
        await (widget.baseDeDatos.select(widget.baseDeDatos.articulos)
              ..where((t) => t.borradoEn.isNull()))
            .get();
    if (!mounted) return;
    setState(() {
      _productos = productos;
      _articulos = articulos;
      // La selección solo vive mientras el producto siga sin clasificar.
      _seleccionados.removeWhere(
        (String id) => productos.every((Producto p) => p.id != id),
      );
      _cargando = false;
    });
  }

  List<SugerenciaArticulo> _sugerencias(Producto producto) => sugerirArticulos(
        categoria: producto.categoria,
        nombre: producto.nombre,
        marca: producto.marca,
        articulos: _articulos,
      ).take(maxSugerenciasPorProducto).toList();

  /// Modo individual (S2): el toque en la sugerencia asigna en el momento.
  Future<void> _asignarIndividual(Producto producto, Articulo articulo) async {
    await asignarArticulo(
      widget.baseDeDatos,
      producto.id,
      articuloId: articulo.id,
    );
    await _cargar();
  }

  /// Alta de artículo nuevo desde esta pantalla (S2): el mismo diálogo y
  /// repos que la pantalla de Artículos (altaArticulo encola para la sync).
  Future<Articulo?> _altaArticuloNuevo() async {
    final TextEditingController nombre = TextEditingController();
    String unidadBase = 'kg';
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final (String, String)? datos = await showDialog<(String, String)>(
      context: context,
      builder: (BuildContext contexto) => StatefulBuilder(
        builder: (BuildContext contexto, StateSetter setStateDialogo) =>
            AlertDialog(
          title: const Text('Nuevo artículo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nombre,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del artículo *',
                  ),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresá el nombre' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: unidadBase,
                  decoration: const InputDecoration(labelText: 'Unidad base'),
                  items: <DropdownMenuItem<String>>[
                    for (final String u in unidadesBaseDeArticulo)
                      DropdownMenuItem<String>(value: u, child: Text(u)),
                  ],
                  onChanged: (String? u) =>
                      setStateDialogo(() => unidadBase = u ?? 'kg'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(contexto),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(contexto, (nombre.text.trim(), unidadBase));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (datos == null || !mounted) return null;
    final Articulo creado = await altaArticulo(
      widget.baseDeDatos,
      nombre: datos.$1,
      unidadBase: datos.$2,
    );
    await _cargar();
    return creado;
  }

  /// S2: UN artículo destino para todo el lote — existente o de alta nueva.
  /// Null = el dueño canceló (no se aplica nada).
  Future<Articulo?> _elegirArticuloDestino() async {
    final Object? elegido = await showDialog<Object>(
      context: context,
      builder: (BuildContext contexto) => SimpleDialog(
        title: const Text('Elegir artículo destino'),
        children: <Widget>[
          for (final Articulo articulo in _articulos)
            SimpleDialogOption(
              key: ValueKey('destino-${articulo.id}'),
              onPressed: () => Navigator.pop(contexto, articulo),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined),
                title: Text(articulo.nombre),
                subtitle: Text(articulo.unidadBase),
              ),
            ),
          if (_articulos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Todavía no hay artículos — creá uno nuevo'),
            ),
          SimpleDialogOption(
            key: const ValueKey('destino-nuevo'),
            onPressed: () => Navigator.pop(contexto, const _DestinoNuevo()),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add),
              title: const Text('Crear artículo nuevo…'),
            ),
          ),
        ],
      ),
    );
    if (elegido == null || !mounted) return null;
    if (elegido is _DestinoNuevo) return _altaArticuloNuevo();
    return elegido as Articulo;
  }

  /// S2: confirmación ANTES de aplicar el lote.
  Future<bool> _confirmarLote(Articulo destino, int cantidad) async {
    final bool? aceptado = await showDialog<bool>(
      context: context,
      builder: (BuildContext contexto) => AlertDialog(
        title: const Text('Clasificar en lote'),
        content: Text('¿Asignar «${destino.nombre}» a $cantidad producto(s)?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
    return aceptado ?? false;
  }

  Future<void> _clasificarEnLote() async {
    final Set<String> seleccionados = _seleccionados.toSet();
    if (seleccionados.isEmpty) return;
    final Articulo? destino = await _elegirArticuloDestino();
    if (destino == null || !mounted) return;
    if (!await _confirmarLote(destino, seleccionados.length)) return;
    if (!mounted) return;
    // Un llamado por producto: cada producto queda encolado por la sync
    // normal (regla de sync 2) y solo cambia su articulo_id (S3).
    for (final String id in seleccionados) {
      await asignarArticulo(widget.baseDeDatos, id, articuloId: destino.id);
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sin clasificar (${_productos.length})'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? const Center(child: Text('No hay productos sin clasificar'))
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          for (final Producto producto in _productos)
                            _tarjetaProducto(producto),
                        ],
                      ),
                    ),
                    if (_seleccionados.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          key: const ValueKey('btn-clasificar-lote'),
                          onPressed: _clasificarEnLote,
                          icon: const Icon(Icons.done_all),
                          label: Text('Clasificar (${_seleccionados.length})'),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _tarjetaProducto(Producto producto) {
    final List<SugerenciaArticulo> sugerencias = _sugerencias(producto);
    final String? marca = producto.marca;
    final String detalle = <String>[
      if (marca != null && marca.isNotEmpty) marca,
      producto.codigoBarras ?? 'sin código',
    ].join(' · ');
    return ListTile(
      leading: Checkbox(
        key: ValueKey('check-${producto.id}'),
        value: _seleccionados.contains(producto.id),
        onChanged: (bool? marcado) => setState(() {
          if (marcado ?? false) {
            _seleccionados.add(producto.id);
          } else {
            _seleccionados.remove(producto.id);
          }
        }),
      ),
      title: Text(producto.nombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(detalle),
          if (sugerencias.isEmpty)
            const Text('Sin sugerencias')
          else
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final SugerenciaArticulo sugerencia in sugerencias)
                  ActionChip(
                    key: ValueKey('chip-${producto.id}-${sugerencia.articulo.id}'),
                    label: Text(sugerencia.articulo.nombre),
                    tooltip: 'Asignar a ${sugerencia.articulo.nombre}',
                    onPressed: () =>
                        _asignarIndividual(producto, sugerencia.articulo),
                  ),
              ],
            ),
        ],
      ),
      isThreeLine: true,
      trailing: IconButton(
        key: ValueKey('nuevo-articulo-${producto.id}'),
        tooltip: 'Crear artículo nuevo',
        icon: const Icon(Icons.add),
        onPressed: _altaArticuloNuevo,
      ),
    );
  }
}
