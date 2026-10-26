import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/base_de_datos.dart';
import '../../data/local/normalizacion.dart';

/// S6 (R11): administración de artículos — alta, renombre y conteo de
/// productos asignados. La asignación producto ↔ artículo también puede
/// hacerse desde el formulario de producto (S5); la unidad base se define
/// al crear el artículo y no cambia (da estabilidad a las comparaciones).
class ArticulosScreen extends StatefulWidget {
  const ArticulosScreen({super.key, required this.baseDeDatos});

  final BaseDeDatos baseDeDatos;

  @override
  State<ArticulosScreen> createState() => _ArticulosScreenState();
}

class _ArticulosScreenState extends State<ArticulosScreen> {
  List<Articulo> _articulos = <Articulo>[];
  Map<String, int> _productosPorArticulo = <String, int>{};
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

    if (!mounted) return;
    setState(() {
      _articulos = articulos;
      _productosPorArticulo = <String, int>{
        for (final fila in conteos)
          fila.read<String>('articulo_id'): fila.read<int>('c'),
      };
      _cargando = false;
    });
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
    final ahora = DateTime.now().toUtc().toIso8601String();
    final nombre = nombreController.text.trim();

    if (existente == null) {
      await widget.baseDeDatos.into(widget.baseDeDatos.articulos).insert(
            ArticulosCompanion.insert(
              id: const Uuid().v4(),
              nombre: nombre,
              unidadBase: unidadBase,
              creadoPor: 'local',
              creadoEn: ahora,
              actualizadoEn: ahora,
            ),
          );
    } else {
      await (widget.baseDeDatos.update(widget.baseDeDatos.articulos)
            ..where((t) => t.id.equals(existente.id)))
          .write(ArticulosCompanion(
            nombre: Value(nombre),
            actualizadoEn: Value(ahora),
          ));
    }
    await _cargar();
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
              : ListView.builder(
                  itemCount: _articulos.length,
                  itemBuilder: (BuildContext contexto, int i) {
                    final Articulo a = _articulos[i];
                    final int cantidad = _productosPorArticulo[a.id] ?? 0;
                    return ListTile(
                      title: Text(a.nombre),
                      subtitle: Text(
                        '${a.unidadBase} · $cantidad producto(s)',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Renombrar',
                        onPressed: () => _dialogoArticulo(existente: a),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
