import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/identidad.dart';
import '../../data/local/base_de_datos.dart';

const List<String> tiposComercio = <String>[
  'almacen',
  'carniceria',
  'verduleria',
  'ferreteria',
  'otro',
];

/// S7 (R9): alta de comercio "en el momento" — diálogo reutilizable por el
/// registro de precio (T8) y por la sección Comercios. Devuelve el comercio
/// creado, o null si el usuario canceló.
Future<Comercio?> mostrarAltaComercio(
  BuildContext context,
  BaseDeDatos db, {
  String? nombreInicial,
}) async {
  final nombreController = TextEditingController(text: nombreInicial ?? '');
  final direccionController = TextEditingController();
  String? tipo;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final Comercio? comercio = await showDialog<Comercio>(
    context: context,
    builder: (BuildContext contexto) => StatefulBuilder(
      builder: (BuildContext contexto, StateSetter setStateDialogo) => AlertDialog(
        title: const Text('Nuevo comercio'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: nombreController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del comercio *',
                ),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresá el nombre' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Tipo (opcional)'),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Sin tipo'),
                  ),
                  for (final String t in tiposComercio)
                    DropdownMenuItem<String>(value: t, child: Text(t)),
                ],
                onChanged: (String? t) => setStateDialogo(() => tipo = t),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: direccionController,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(labelText: 'Dirección (opcional)'),
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ahora = DateTime.now().toUtc().toIso8601String();
              final direccion = direccionController.text.trim();
              final usuario = await usuarioActual(db);
              final Comercio comercio =
                  await db.into(db.comercios).insertReturning(
                        ComerciosCompanion.insert(
                          id: const Uuid().v4(),
                          nombre: nombreController.text.trim(),
                          tipo: Value(tipo),
                          direccion:
                              Value(direccion.isEmpty ? null : direccion),
                          creadoPor: usuario.id,
                          creadoEn: ahora,
                          actualizadoEn: ahora,
                        ),
                      );
              if (contexto.mounted) Navigator.pop(contexto, comercio);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  return comercio;
}
