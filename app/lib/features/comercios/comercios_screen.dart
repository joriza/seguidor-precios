import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/local/base_de_datos.dart';
import 'alta_comercio_dialog.dart';

/// Sección Comercios: listado y alta (S7, R9).
class ComerciosScreen extends StatefulWidget {
  const ComerciosScreen({super.key, required this.baseDeDatos});

  final BaseDeDatos baseDeDatos;

  @override
  State<ComerciosScreen> createState() => _ComerciosScreenState();
}

class _ComerciosScreenState extends State<ComerciosScreen> {
  List<Comercio> _comercios = <Comercio>[];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await (widget.baseDeDatos.select(widget.baseDeDatos.comercios)
          ..where((t) => t.borradoEn.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.nombre)]))
        .get();
    if (!mounted) return;
    setState(() {
      _comercios = lista;
      _cargando = false;
    });
  }

  Future<void> _alta() async {
    await mostrarAltaComercio(context, widget.baseDeDatos);
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
            onPressed: _alta,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo comercio'),
          ),
        ),
        Expanded(
          child: _comercios.isEmpty
              ? const Center(child: Text('Todavía no hay comercios'))
              : ListView.builder(
                  itemCount: _comercios.length,
                  itemBuilder: (BuildContext contexto, int i) {
                    final Comercio c = _comercios[i];
                    final String? tipo = c.tipo;
                    return ListTile(
                      leading: const Icon(Icons.storefront),
                      title: Text(c.nombre),
                      subtitle: Text(tipo ?? 'Sin tipo'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
