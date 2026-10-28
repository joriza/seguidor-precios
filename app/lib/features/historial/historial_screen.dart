import 'package:flutter/material.dart';

import '../../data/local/base_de_datos.dart';
import '../sync/gestor_sync.dart';
import '../sync/refresco.dart';
import 'historial_producto_screen.dart';

/// S10 (R8): historial — productos con precios registrados.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required this.baseDeDatos, this.gestorSync});

  final BaseDeDatos baseDeDatos;

  /// T4: con backend configurado, el pull-to-refresh sincroniza antes de
  /// recargar; sin backend, solo recarga lo local.
  final GestorSync? gestorSync;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Map<String, dynamic>> _productos = <Map<String, dynamic>>[];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final filas = await widget.baseDeDatos.customSelect(
      'SELECT p.id AS id, p.nombre AS nombre, p.marca AS marca, '
      'COUNT(pr.id) AS cantidad, MAX(pr.fecha_toma) AS ultima '
      'FROM precios pr JOIN productos p ON pr.producto_id = p.id '
      'WHERE p.borrado_en IS NULL '
      'GROUP BY p.id ORDER BY ultima DESC',
      readsFrom: {
        widget.baseDeDatos.precios,
        widget.baseDeDatos.productos,
      },
    ).get();

    if (!mounted) return;
    setState(() {
      _productos = filas.map((f) => f.data).toList();
      _cargando = false;
    });
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
    if (_productos.isEmpty) {
      return const Center(
        child: Text('Sin precios registrados todavía'),
      );
    }
    return RefreshIndicator(
      onRefresh: _refrescar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: _productos.length,
      itemBuilder: (BuildContext contexto, int i) {
        final Map<String, dynamic> p = _productos[i];
        final String nombre = p['marca'] == null || (p['marca'] as String).isEmpty
            ? p['nombre'] as String
            : '${p['nombre']} · ${p['marca']}';
        return ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(nombre),
          subtitle: Text(
            '${p['cantidad']} precio(s) · última toma: ${p['ultima']}',
          ),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => HistorialProductoScreen(
                  baseDeDatos: widget.baseDeDatos,
                  productoId: p['id'] as String,
                  nombre: nombre,
                ),
              ),
            );
          },
        );
        },
      ),
    );
  }
}
