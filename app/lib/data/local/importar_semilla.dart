import 'package:drift/drift.dart';

import 'base_de_datos.dart';

class ResultadoImportacion {
  const ResultadoImportacion({
    required this.importados,
    required this.omitidosPorDuplicado,
    required this.omitidosInvalidos,
  });

  final int importados;
  final int omitidosPorDuplicado;
  final int omitidosInvalidos;
}

const Set<String> _unidadesValidas = <String>{'g', 'mL', 'unidad'};

/// Importa el pack semilla (R10) en una transacción, saltando los EAN que ya
/// existan en la base (dedup por código). Los productos importados quedan con
/// `origen = 'semilla'` y sin artículo asignado (la clasificación es tarea
/// del dueño: Fase 1.6 / Fase 3).
Future<ResultadoImportacion> importarPackSemilla(
  BaseDeDatos db, {
  required Map<String, dynamic> pack,
  required String usuarioId,
  DateTime? ahora,
}) async {
  final instantanea = (ahora ?? DateTime.now()).toUtc().toIso8601String();
  final productos = (pack['productos'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();

  var importados = 0;
  var omitidosPorDuplicado = 0;
  var omitidosInvalidos = 0;

  await db.transaction(() async {
    for (final p in productos) {
      final codigo = p['codigo_barras']?.toString() ?? '';
      final nombre = p['nombre']?.toString() ?? '';
      final unidad = p['unidad']?.toString() ?? '';
      final contenido = (p['contenido_neto'] as num?)?.toDouble();

      if (codigo.isEmpty || nombre.isEmpty || !_unidadesValidas.contains(unidad)) {
        omitidosInvalidos++;
        continue;
      }

      final existente = await (db.select(db.productos)
            ..where((t) => t.codigoBarras.equals(codigo)))
          .getSingleOrNull();
      if (existente != null) {
        omitidosPorDuplicado++;
        continue;
      }

      final marca = p['marca']?.toString();
      final categoria = p['categoria']?.toString();

      await db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: 'sem-$codigo',
              codigoBarras: Value(codigo),
              nombre: nombre,
              unidad: unidad,
              contenidoNeto: Value(contenido),
              marca: Value((marca == null || marca.isEmpty) ? null : marca),
              categoria:
                  Value((categoria == null || categoria.isEmpty) ? null : categoria),
              origen: const Value('semilla'),
              creadoPor: usuarioId,
              creadoEn: instantanea,
              actualizadoEn: instantanea,
            ),
          );
      importados++;
    }
  });

  return ResultadoImportacion(
    importados: importados,
    omitidosPorDuplicado: omitidosPorDuplicado,
    omitidosInvalidos: omitidosInvalidos,
  );
}
