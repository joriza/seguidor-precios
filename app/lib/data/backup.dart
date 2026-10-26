import 'dart:convert';

import 'package:drift/drift.dart';

import 'local/base_de_datos.dart';

/// S13 (R3, R5): backup/export JSON + CSV e importación.
///
/// El backup JSON contiene todas las tablas del esquema v1 y restaura en
/// otra instalación (criterio de salida de la fase). La importación es
/// transaccional y no destructiva: las filas que ya existen (mismo id)
/// quedan como están — la carga manual del dueño gana, igual que en el
/// import del pack semilla (T3).

const String formatoBackup = 'seguidor-precios-backup';
const int versionBackup = 1;

/// Exporta toda la base como mapa listo para JSON (R5: datos en formatos
/// abiertos, sin herramientas propietarias).
Future<Map<String, dynamic>> exportarBackup(BaseDeDatos db) async {
  final usuarios = await db.select(db.usuarios).get();
  final comercios = await db.select(db.comercios).get();
  final articulos = await db.select(db.articulos).get();
  final productos = await db.select(db.productos).get();
  final precios = await db.select(db.precios).get();

  return <String, dynamic>{
    'formato': formatoBackup,
    'version': versionBackup,
    'exportado_en': DateTime.now().toUtc().toIso8601String(),
    'usuarios': usuarios.map((u) => u.toJson()).toList(),
    'comercios': comercios.map((c) => c.toJson()).toList(),
    'articulos': articulos.map((a) => a.toJson()).toList(),
    'productos': productos.map((p) => p.toJson()).toList(),
    'precios': precios.map((p) => p.toJson()).toList(),
  };
}

/// Resumen de una importación: filas nuevas insertadas y filas omitidas
/// (ya existían, o eran inválidas).
class ResumenImportacion {
  const ResumenImportacion({
    required this.insertadas,
    required this.omitidas,
  });

  final int insertadas;
  final int omitidas;

  @override
  String toString() => 'insertadas=$insertadas omitidas=$omitidas';
}

/// Importa un backup JSON de forma transaccional y no destructiva.
///
/// Valida formato y versión; salta filas con id existente (sin pisar datos
/// del dueño) y filas inválidas; lanza [FormatException] si el texto no es
/// JSON válido o no es un backup de esta app.
Future<ResumenImportacion> importarBackup(
  BaseDeDatos db,
  String jsonTexto,
) async {
  final dynamic raiz;
  try {
    raiz = jsonDecode(jsonTexto);
  } on FormatException {
    throw FormatException('El texto no es JSON válido');
  }
  if (raiz is! Map<String, dynamic> ||
      raiz['formato'] != formatoBackup ||
      raiz['version'] != versionBackup) {
    throw FormatException('No es un backup de Seguidor de Precios v$versionBackup');
  }

  int insertadas = 0;
  int omitidas = 0;

  Future<void> importarTabla<T extends DataClass>(
    List<dynamic> filas,
    TableInfo<Table, T> tabla,
    Future<bool> Function(T) existe,
    Future<void> Function(T) insertar,
    T Function(Map<String, dynamic>) desdeJson,
  ) async {
    for (final dynamic fila in filas) {
      if (fila is! Map<String, dynamic>) {
        omitidas++;
        continue;
      }
      final T filaTipada;
      try {
        filaTipada = desdeJson(fila);
      } catch (_) {
        omitidas++;
        continue;
      }
      if (await existe(filaTipada)) {
        omitidas++;
        continue;
      }
      await insertar(filaTipada);
      insertadas++;
    }
  }

  await db.transaction(() async {
    final dinamicas = <String, List<dynamic>>{
      for (final String k in const <String>[
        'usuarios',
        'comercios',
        'articulos',
        'productos',
        'precios',
      ])
        k: (raiz[k] as List? ?? const <dynamic>[]),
    };

    await importarTabla<Usuario>(
      dinamicas['usuarios']!,
      db.usuarios,
      (u) async =>
          await (db.select(db.usuarios)..where((t) => t.id.equals(u.id)))
              .getSingleOrNull() !=
          null,
      (u) => db.into(db.usuarios).insert(u),
      Usuario.fromJson,
    );
    await importarTabla<Comercio>(
      dinamicas['comercios']!,
      db.comercios,
      (c) async =>
          await (db.select(db.comercios)..where((t) => t.id.equals(c.id)))
              .getSingleOrNull() !=
          null,
      (c) => db.into(db.comercios).insert(c),
      Comercio.fromJson,
    );
    await importarTabla<Articulo>(
      dinamicas['articulos']!,
      db.articulos,
      (a) async =>
          await (db.select(db.articulos)..where((t) => t.id.equals(a.id)))
              .getSingleOrNull() !=
          null,
      (a) => db.into(db.articulos).insert(a),
      Articulo.fromJson,
    );
    await importarTabla<Producto>(
      dinamicas['productos']!,
      db.productos,
      (p) async =>
          await (db.select(db.productos)..where((t) => t.id.equals(p.id)))
              .getSingleOrNull() !=
          null,
      (p) => db.into(db.productos).insert(p),
      Producto.fromJson,
    );
    await importarTabla<Precio>(
      dinamicas['precios']!,
      db.precios,
      (p) async =>
          await (db.select(db.precios)..where((t) => t.id.equals(p.id)))
              .getSingleOrNull() !=
          null,
      (p) => db.into(db.precios).insert(p),
      Precio.fromJson,
    );
  });

  return ResumenImportacion(insertadas: insertadas, omitidas: omitidas);
}

/// Exporta los precios como CSV (R5: planilla de cálculo), con campos
/// escapados según RFC 4180.
Future<String> exportarPreciosCsv(BaseDeDatos db) async {
  final filas = await db.customSelect(
    'SELECT pr.fecha_toma AS fecha_toma, c.nombre AS comercio, '
    'p.nombre AS producto, p.marca AS marca, p.codigo_barras AS codigo, '
    'pr.precio AS precio '
    'FROM precios pr '
    'JOIN comercios c ON pr.comercio_id = c.id '
    'JOIN productos p ON pr.producto_id = p.id '
    'ORDER BY pr.fecha_toma ASC, c.nombre ASC',
    readsFrom: {
      db.precios,
      db.comercios,
      db.productos,
    },
  ).get();

  final StringBuffer csv = StringBuffer(
    'fecha_toma,comercio,producto,marca,codigo_barras,precio\n',
  );
  for (final f in filas) {
    final String precio = (f.read<double>('precio')).toStringAsFixed(2);
    csv.writeln(<String>[
      campoCsv(f.read<String>('fecha_toma')),
      campoCsv(f.read<String>('comercio')),
      campoCsv(f.read<String>('producto')),
      campoCsv(f.read<String?>('marca') ?? ''),
      campoCsv(f.read<String?>('codigo') ?? ''),
      precio,
    ].join(','));
  }
  return csv.toString();
}

/// Escapa un campo CSV: lo entrecomilla si tiene coma, comilla o salto de
/// línea, duplicando las comillas internas (RFC 4180).
String campoCsv(String valor) {
  final bool necesita = valor.contains(',') ||
      valor.contains('"') ||
      valor.contains('\n') ||
      valor.contains('\r');
  if (!necesita) return valor;
  return '"${valor.replaceAll('"', '""')}"';
}
