import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/local/importar_semilla.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  final pack = <String, dynamic>{
    'fuente': 'Open Food Facts (contribuyentes)',
    'licencia': 'ODbL',
    'version': '1.0.0',
    'cantidad': 3,
    'productos': <Map<String, dynamic>>[
      <String, dynamic>{
        'codigo_barras': '7790001001001',
        'nombre': 'Mayonesa Marca A',
        'marca': 'Marca A',
        'unidad': 'g',
        'contenido_neto': 500,
        'categoria': 'mayonnaises',
      },
      <String, dynamic>{
        'codigo_barras': '7790001001002',
        'nombre': 'Marca B 1,5 L',
        'marca': null,
        'unidad': 'mL',
        'contenido_neto': 1500,
        'categoria': null,
      },
      <String, dynamic>{
        'codigo_barras': '7790001001003',
        'nombre': 'Sin unidad válida',
        'unidad': 'litros',
        'contenido_neto': 1,
      },
    ],
  };

  test('importa productos válidos con origen semilla y omite inválidos', () async {
    final resultado = await importarPackSemilla(
      db,
      pack: pack,
      usuarioId: 'u1',
      ahora: DateTime.utc(2026, 1, 1),
    );

    expect(resultado.importados, 2);
    expect(resultado.omitidosInvalidos, 1);
    expect(resultado.omitidosPorDuplicado, 0);

    final filas = await db.select(db.productos).get();
    final mayonesa = filas.firstWhere((f) => f.codigoBarras == '7790001001001');
    expect(mayonesa.nombre, 'Mayonesa Marca A');
    expect(mayonesa.marca, 'Marca A');
    expect(mayonesa.origen, 'semilla');
    expect(mayonesa.contenidoNeto, 500);
    expect(mayonesa.id, 'sem-7790001001001');

    final marcaB = filas.firstWhere((f) => f.codigoBarras == '7790001001002');
    expect(marcaB.marca, isNull);
    expect(marcaB.categoria, isNull);
  });

  test('omite los EAN que ya existen en la base', () async {
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'm1',
            codigoBarras: const Value('7790001001001'),
            nombre: 'Cargada a mano por el dueño',
            unidad: 'g',
            contenidoNeto: const Value(490),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );

    final resultado = await importarPackSemilla(
      db,
      pack: pack,
      usuarioId: 'u1',
      ahora: DateTime.utc(2026, 1, 1),
    );

    expect(resultado.importados, 1);
    expect(resultado.omitidosPorDuplicado, 1);

    final filas = await db.select(db.productos).get();
    expect(filas, hasLength(2));
    // La carga manual del dueño gana: el import no la pisa.
    final manual = filas.firstWhere((f) => f.id == 'm1');
    expect(manual.nombre, 'Cargada a mano por el dueño');
    expect(manual.contenidoNeto, 490);
  });
}
