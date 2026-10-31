import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/articulos.dart';
import '../../data/local/base_de_datos.dart';
import '../../data/local/normalizacion.dart';
import '../sync/gestor_sync.dart';
import '../sync/refresco.dart';
import 'articulo_detalle_screen.dart';
import 'sin_clasificar_screen.dart';

/// S6 (R11): administración de artículos — alta, renombre y conteo de
/// productos asignados. La asignación producto ↔ artículo también puede
/// hacerse desde el formulario de producto (S5); la unidad base se define
/// al crear el artículo y no cambia (da estabilidad a las comparaciones).
class ArticulosScreen extends StatefulWidget {
  const ArticulosScreen({super.key, required this.baseDeDatos, this.gestorSync});

  final BaseDeDatos baseDeDatos;

  /// T4: si hay backend configurado, el pull-to-refresh sincroniza antes
  /// de recargar; si no, solo recarga lo local.
  final GestorSync? gestorSync;

  @override
  State<ArticulosScreen> createState() => _ArticulosScreenState();
}

class _ArticulosScreenState extends State<ArticulosScreen> {
  List<Articulo> _articulos = <Articulo>[];
  Map<String, int> _productosPorArticulo = <String, int>{};

  /// v0.3.9 (S2): conteo de productos sin artículo (sin borrados) para la
  /// entrada «Sin clasificar (N)».
  int _sinClasificar = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final articulos =
        await (widget.baseDeDatos.select(widget.baseDeDatos.articulos)
              ..where((t) => t.borradoEn.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.nombre)]))
            .get();

    final conteos = await widget.baseDeDatos.customSelect(
      'SELECT articulo_id, COUNT(*) AS c FROM productos '
      'WHERE articulo_id IS NOT NULL AND borrado_en IS NULL '
      'GROUP BY articulo_id',
      readsFrom: {widget.baseDeDatos.productos},
    ).get();

    // v0.3.9 (S2): N de la entrada «Sin clasificar» — mismo criterio que
    // la pantalla: articulo_id NULL y sin baja (S3: los borrados no cuentan).
    final conteoSinClasificar = await widget.baseDeDatos.customSelect(
      'SELECT COUNT(*) AS c FROM productos '
      'WHERE articulo_id IS NULL AND borrado_en IS NULL',
      readsFrom: {widget.baseDeDatos.productos},
    ).getSingle();

    if (!mounted) return;
    setState(() {
      _articulos = articulos;
      _productosPorArticulo = <String, int>{
        for (final fila in conteos)
          fila.read<String>('articulo_id'): fila.read<int>('c'),
      };
      _sinClasificar = conteoSinClasificar.read<int>('c');
      _cargando = false;
    });
  }

  /// v0.3.9 (S2): abre la pantalla de clasificación; al volver, el conteo
  /// puede haber cambiado — recarga.
  Future<void> _abrirSinClasificar() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SinClasificarScreen(baseDeDatos: widget.baseDeDatos),
      ),
    );
    await _cargar();
  }

  Future<void> _dialogoArticulo({Articulo? existente}) async {
    final nombreController =
        TextEditingController(text: existente?.nombre ?? '');
    String unidadBase = existente?.unidadBase ?? 'kg';
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final aceptado = await showDialog<bool>(
      context: context,
      builder: (BuildContext contexto) => StatefulBuilder(
        builder: (BuildContext contexto, StateSetter setStateDialogo) =>
            AlertDialog(
          title: Text(
              existente == null ? 'Nuevo artículo' : 'Renombrar artículo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nombreController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Nombre del artículo *'),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresá el nombre' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: unidadBase,
                  decoration:
                      const InputDecoration(labelText: 'Unidad base'),
                  items: <DropdownMenuItem<String>>[
                    for (final String u in unidadesBaseDeArticulo)
                      DropdownMenuItem<String>(value: u, child: Text(u)),
                  ],
                  onChanged: existente == null
                      ? (String? u) =>
                          setStateDialogo(() => unidadBase = u ?? 'kg')
                      : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(contexto, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(contexto, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (aceptado != true) return;
    final nombre = nombreController.text.trim();

    // T4: alta/cambio local + encolado para la sync (regla de sync 2). El
    // renombre es la única edición de un artículo (S6).
    if (existente == null) {
      await altaArticulo(
        widget.baseDeDatos,
        nombre: nombre,
        unidadBase: unidadBase,
      );
    } else {
      await renombrarArticulo(widget.baseDeDatos, existente.id, nombre: nombre);
    }
    await _cargar();
  }

  /// T4: pull-to-refresh — sync (si hay backend) y recarga local.
  Future<void> _refrescar() async {
    await refrescarLista(context, widget.gestorSync, _cargar);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => _dialogoArticulo(),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo artículo'),
          ),
        ),
        // v0.3.9 (S2): entrada a la clasificación — lista los productos sin
        // artículo y permite asignarlos individualmente o en lote.
        Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text('Sin clasificar ($_sinClasificar)'),
            subtitle: const Text('Productos sin artículo asignado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _abrirSinClasificar,
          ),
        ),
        Expanded(
          child: _articulos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('Todavía no hay artículos'),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () => _dialogoArticulo(),
                        child: const Text('Crear el primero'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refrescar,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _articulos.length,
                    itemBuilder: (BuildContext contexto, int i) {
                    final Articulo a = _articulos[i];
                    final int cantidad = _productosPorArticulo[a.id] ?? 0;
                    return ListTile(
                      title: Text(a.nombre),
                      subtitle: Text(
                        '${a.unidadBase} · $cantidad producto(s)',
                      ),
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ArticuloDetalleScreen(
                              baseDeDatos: widget.baseDeDatos,
                              articulo: a,
                            ),
                          ),
                        );
                        await _cargar();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Renombrar',
                        onPressed: () => _dialogoArticulo(existente: a),
                      ),
                    );
                  },
                  ),
              ),
        ),
      ],
    );
  }
}
