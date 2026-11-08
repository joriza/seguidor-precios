import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:seguidor_precios/data/categorias.dart';
import 'package:seguidor_precios/data/enriquecimiento.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/local/importar_semilla.dart';

/// v0.3.17 (S1/S2): diccionario de categorías canónicas curado por el
/// dueño y su aplicación en dos de los tres puntos de entrada (parser de
/// enriquecimiento e import de semilla). El tercero (generación de
/// semilla) vive en otro paquete y se prueba en tools/seed/test.
void main() {
  group('categoriaCanonica (S1: diccionario del dueño)', () {
    test('semilla del diccionario: guisantes → arvejas (case-insensitive)',
        () {
      expect(categoriaCanonica('guisantes'), 'arvejas');
      expect(categoriaCanonica('Guisantes'), 'arvejas');
      expect(categoriaCanonica('GUISANTES'), 'arvejas');
    });

    test('semilla del diccionario: chícharos → arvejas (sin acento también)',
        () {
      expect(categoriaCanonica('chícharos'), 'arvejas');
      expect(categoriaCanonica('Chícharos'), 'arvejas');
      expect(categoriaCanonica('chicharos'), 'arvejas');
    });

    test('desconocida pasa tal cual, sin cambios (S6: texto libre)', () {
      expect(categoriaCanonica('Galletitas dulces'), 'Galletitas dulces');
      expect(categoriaCanonica('Snacks, Sweet snacks'), 'Snacks, Sweet snacks');
    });

    test('null y vacío no cambian', () {
      expect(categoriaCanonica(null), isNull);
      expect(categoriaCanonica(''), '');
    });

    test('quita el prefijo de tag en:/xx: como transformar.dart', () {
      expect(categoriaCanonica('en:guisantes'), 'arvejas');
      expect(categoriaCanonica('en:Guisantes'), 'arvejas');
      expect(categoriaCanonica('xx:chícharos'), 'arvejas');
      // Desconocida con tag: el prefijo se limpia, el resto queda igual.
      expect(categoriaCanonica('en:snap peas'), 'snap peas');
    });

    test('matchea el término completo o cada segmento separado por coma',
        () {
      expect(categoriaCanonica('Guisantes, Legumbres'), 'arvejas, Legumbres');
      expect(categoriaCanonica('Legumbres, chícharos'), 'Legumbres, arvejas');
      expect(categoriaCanonica('Guisantes, Chícharos'), 'arvejas, arvejas');
    });
  });

  group('punto de entrada (a): parser de enriquecimiento (S2)', () {
    Future<DatosEnriquecidos?> datosDeOFF(Map<String, dynamic> product) async {
      final http.Client cliente = MockClient((http.Request request) async =>
          http.Response(
              jsonEncode(<String, dynamic>{
                'status': 1,
                'product': product,
              }),
              200));
      return ServicioEnriquecimientoOFF(cliente: cliente).consultar(
        '7790001001999',
      );
    }

    test('DatosEnriquecidos.categorias queda canónica', () async {
      final DatosEnriquecidos? datos = await datosDeOFF(
        <String, dynamic>{
          'product_name': 'Arvejas congeladas',
          'categories': 'Guisantes, Chícharos, Legumbres',
        },
      );

      expect(datos, isNotNull);
      expect(datos!.categorias, 'arvejas, arvejas, Legumbres');
    });

    test('categoría desconocida de OFF no se toca (S6)', () async {
      final DatosEnriquecidos? datos = await datosDeOFF(
        <String, dynamic>{
          'product_name': 'Galletitas',
          'categories': 'Snacks, Sweet snacks, Biscuits',
        },
      );

      expect(datos!.categorias, 'Snacks, Sweet snacks, Biscuits');
    });
  });

  group('punto de entrada (b): import de semilla (S2)', () {
    late BaseDeDatos db;

    setUp(() {
      db = BaseDeDatos.memoria();
    });

    tearDown(() => db.close());

    Map<String, dynamic> packCon(String ean, String? categoria) =>
        <String, dynamic>{
          'version': '1.0.0',
          'productos': <Map<String, dynamic>>[
            <String, dynamic>{
              'codigo_barras': ean,
              'nombre': 'Producto $ean',
              'unidad': 'g',
              'contenido_neto': 500,
              'categoria': categoria,
            },
          ],
        };

    Future<String?> categoriaGuardada(String ean) async {
      final fila = await (db.select(db.productos)
            ..where((t) => t.codigoBarras.equals(ean)))
          .getSingle();
      return fila.categoria;
    }

    test('persiste producto.categoria canónica', () async {
      await importarPackSemilla(
        db,
        pack: packCon('7790001001001', 'guisantes'),
        usuarioId: 'u1',
        ahora: DateTime.utc(2026, 1, 1),
      );
      await importarPackSemilla(
        db,
        pack: packCon('7790001001002', 'Chícharos'),
        usuarioId: 'u1',
        ahora: DateTime.utc(2026, 1, 1),
      );

      expect(await categoriaGuardada('7790001001001'), 'arvejas');
      expect(await categoriaGuardada('7790001001002'), 'arvejas');
    });

    test('categoría desconocida del pack se guarda tal cual (S6)', () async {
      await importarPackSemilla(
        db,
        pack: packCon('7790001001003', 'mayonnaises'),
        usuarioId: 'u1',
        ahora: DateTime.utc(2026, 1, 1),
      );

      expect(await categoriaGuardada('7790001001003'), 'mayonnaises');
    });
  });
}
