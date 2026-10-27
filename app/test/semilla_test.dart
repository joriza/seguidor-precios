import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/semilla.dart';

/// AssetBundle falso que sirve un contenido fijo para el pack semilla.
class _BundleFalso extends Fake implements AssetBundle {
  _BundleFalso(this.contenido);

  final String contenido;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key != rutaPackSemilla) {
      throw FlutterError('Asset inesperado: $key');
    }
    return contenido;
  }
}

Map<String, dynamic> _packDe(Map<String, dynamic> producto) => <String, dynamic>{
      'formato': 'seguidor-precios-pack-semilla',
      'version': 1,
      'productos': <dynamic>[producto],
    };

void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  group('importarSemillaDelAsset (S2, v0.1.1)', () {
    test('importa el pack del bundle y crea productos semilla', () async {
      final pack = _packDe(<String, dynamic>{
        'codigo_barras': '7790001112223',
        'nombre': 'Arroz paradito',
        'marca': 'Marca',
        'unidad': 'g',
        'contenido_neto': 500,
      });

      final resultado = await importarSemillaDelAsset(
        db,
        bundle: _BundleFalso(jsonEncode(pack)),
      );

      expect(resultado!.importados, 1);
      final productos = await db.select(db.productos).get();
      expect(productos.single.origen, 'semilla');
      expect(productos.single.id, 'sem-7790001112223');
      expect(await haySemilla(db), isTrue);
    });

    test('si ya hay semillero no vuelve a importar (idempotente)', () async {
      final pack = _packDe(<String, dynamic>{
        'codigo_barras': '7790001112223',
        'nombre': 'Arroz paradito',
        'unidad': 'g',
        'contenido_neto': 500,
      });
      final bundle = _BundleFalso(jsonEncode(pack));

      await importarSemillaDelAsset(db, bundle: bundle);
      final segunda = await importarSemillaDelAsset(db, bundle: bundle);

      expect(segunda, isNull);
      expect(await db.select(db.productos).get(), hasLength(1));
    });

    test('producto creado por el dueño con el mismo EAN: el dueño gana',
        () async {
      await db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: 'propio',
              nombre: 'Arroz del dueño',
              codigoBarras: const Value('7790001112223'),
              unidad: 'g',
              contenidoNeto: const Value(500),
              origen: const Value(null),
              creadoPor: 'dueño',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );

      final pack = _packDe(<String, dynamic>{
        'codigo_barras': '7790001112223',
        'nombre': 'Arroz del pack',
        'unidad': 'g',
        'contenido_neto': 500,
      });
      final resultado = await importarSemillaDelAsset(
        db,
        bundle: _BundleFalso(jsonEncode(pack)),
      );

      // La dedup por EAN omite el del pack: no se pisa la carga del dueño.
      expect(resultado!.importados, 0);
      expect(resultado.omitidosPorDuplicado, 1);
      final productos = await db.select(db.productos).get();
      expect(productos.single.nombre, 'Arroz del dueño');
    });

    test('pack corrupto lanza FormatException', () async {
      await expectLater(
        importarSemillaDelAsset(db, bundle: _BundleFalso('[1, 2, 3]')),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('arranque de la app con semillero (T2)', () {
    testWidgets('primer inicio importa el semillero del asset real',
        (tester) async {
      // El asset debe existir y ser válido (lo genera tools/semilla_api).
      final asset = File('assets/semilla/pack_semilla.json');
      expect(asset.existsSync(), isTrue,
          reason: 'falta app/assets/semilla/pack_semilla.json');
      final pack =
          jsonDecode(asset.readAsStringSync()) as Map<String, dynamic>;
      expect(pack['productos'], isNotEmpty,
          reason: 'el pack semilla no debe estar vacío');

      await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('campo-etiqueta')), 'Vale');
      await tester.tap(find.byKey(const ValueKey('btn-guardar-etiqueta')));
      // La importación corre en segundo plano: esperar a que termine.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)),
      );
      await tester.pumpAndSettle();

      final semilla = await (db.select(db.productos)
            ..where((p) => p.origen.equals('semilla')))
          .get();
      expect(semilla, isNotEmpty);
    });
  });
}
