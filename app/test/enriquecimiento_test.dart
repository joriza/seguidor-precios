import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seguidor_precios/data/enriquecimiento.dart';

/// T5 (S3): cliente OFF sin red — el `http.Client` es un mock y la
/// conectividad es un gate inyectable; nunca sale a internet.
void main() {
  const String ean = '7790001001999';

  /// Mock que graba la URI consultada y responde con el cuerpo dado.
  (http.Client, List<Uri>) clienteQueResponde(
    int statusCode,
    String cuerpo,
  ) {
    final List<Uri> consultas = <Uri>[];
    final http.Client cliente = MockClient((http.Request request) async {
      consultas.add(request.url);
      return http.Response(cuerpo, statusCode);
    });
    return (cliente, consultas);
  }

  String cuerpoOFF({
    int status = 1,
    Map<String, dynamic>? product,
  }) =>
      jsonEncode(<String, dynamic>{
        'status': status,
        'status_verbose': status == 1 ? 'product found' : 'product not found',
        'code': ean,
        'product': ?product,
      });

  test('mapea product_name, brands y quantity a nombre, marca y contenido',
      () async {
    final (http.Client cliente, List<Uri> consultas) =
        clienteQueResponde(200, cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Dulce de leche',
          'brands': 'La Salteña, Otra Marca',
          'quantity': '500 g',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos, isNotNull);
    expect(datos!.nombre, 'Dulce de leche');
    expect(datos.marca, 'La Salteña'); // primera de la lista, sin espacios
    expect(datos.contenidoNeto, 500);
    expect(datos.unidad, 'g');
    // API v2 de OFF, endpoint product/{ean}.json.
    expect(consultas, hasLength(1));
    expect(
      consultas.single.toString(),
      'https://world.openfoodfacts.org/api/v2/product/$ean.json',
    );
  });

  test('prefiere product_name_es y normaliza unidades mL y L', () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Milk caramel',
          'product_name_es': 'Dulce de leche',
          'quantity': '1,5 L',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos!.nombre, 'Dulce de leche');
    expect(datos.contenidoNeto, 1.5);
    expect(datos.unidad, 'L');
  });

  test('quantity en mL usa la unidad de venta mL', () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Agua saborizada',
          'brands': 'Levité',
          'quantity': '500 mL',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos!.contenidoNeto, 500);
    expect(datos.unidad, 'mL');
  });

  test('quantity con formato raro toma el número con unidad (mejor esfuerzo)',
      () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Pack de cervezas',
          'quantity': '6 x 355 ml',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos!.contenidoNeto, 355);
    expect(datos.unidad, 'mL');
  });

  test('quantity sin unidad precarga el número y deja la unidad en null',
      () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Queso cremoso',
          'quantity': '500',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos!.contenidoNeto, 500);
    expect(datos.unidad, isNull);
  });

  test('sin nombre utilizable no hay nada que precargar', () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'brands': 'Marca sin nombre',
          'quantity': '500 g',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos, isNull);
  });

  test('sin resultado (status 0 o HTTP 404) devuelve null', () async {
    final (http.Client sinProducto, _) = clienteQueResponde(
        200, cuerpoOFF(status: 0));
    final (http.Client noEncontrado, _) =
        clienteQueResponde(404, '{"status": 0, "status_verbose": "not found"}');

    final servicio = ServicioEnriquecimientoOFF.new;
    expect(await servicio(cliente: sinProducto).consultar(ean), isNull);
    expect(await servicio(cliente: noEncontrado).consultar(ean), isNull);
  });

  test('respuestas malformadas devuelven null (sin lanzar)', () async {
    for (final String cuerpo in <String>[
      'no-es-json',
      '{"status": 1}', // sin product
      '[]', // no es un objeto
    ]) {
      final (http.Client cliente, _) = clienteQueResponde(200, cuerpo);
      final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
        cliente: cliente,
      ).consultar(ean);
      expect(datos, isNull, reason: 'cuerpo: $cuerpo');
    }
  });

  test('timeout devuelve null (nunca cuelga el flujo)', () async {
    final http.Client cliente =
        MockClient((http.Request request) async {
      throw TimeoutException('OFF no responde');
    });

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos, isNull);
  });

  test('OFF caído (error de red) devuelve null', () async {
    final http.Client cliente = MockClient((http.Request request) async {
      throw Exception('sin conexión al servidor');
    });

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos, isNull);
  });

  test('sin conectividad no consulta la API', () async {
    final (http.Client cliente, List<Uri> consultas) =
        clienteQueResponde(200, cuerpoOFF());

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
      hayConexion: () async => false,
    ).consultar(ean);

    expect(datos, isNull);
    expect(consultas, isEmpty);
  });

  test('con conectividad consulta la API', () async {
    final (http.Client cliente, List<Uri> consultas) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Dulce de leche',
          'quantity': '500 g',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
      hayConexion: () async => true,
    ).consultar(ean);

    expect(datos, isNotNull);
    expect(consultas, hasLength(1));
  });

  test('un EAN inválido no consulta la API', () async {
    for (final String invalido in <String>['', 'abc', '123', 'x' * 20]) {
      final (http.Client cliente, List<Uri> consultas) =
          clienteQueResponde(200, cuerpoOFF());
      final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
        cliente: cliente,
      ).consultar(invalido);
      expect(datos, isNull, reason: 'EAN: $invalido');
      expect(consultas, isEmpty, reason: 'EAN: $invalido');
    }
  });

  test('mapea categories a categorias (string crudo de OFF, v0.3.9 S1)',
      () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Pepas de membrillo',
          'brands': 'Bagley',
          'categories': 'Snacks, Sweet snacks, Biscuits, Cookies',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos!.categorias, 'Snacks, Sweet snacks, Biscuits, Cookies');
  });

  test('sin categories en OFF: categorias es null', () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Dulce de leche',
          'quantity': '500 g',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos!.categorias, isNull);
  });

  test('categories vacío: categorias es null', () async {
    final (http.Client cliente, _) = clienteQueResponde(
        200,
        cuerpoOFF(product: <String, dynamic>{
          'product_name': 'Dulce de leche',
          'categories': '',
        }));

    final DatosEnriquecidos? datos = await ServicioEnriquecimientoOFF(
      cliente: cliente,
    ).consultar(ean);

    expect(datos!.categorias, isNull);
  });

  test('ServicioEnriquecimientoNulo nunca consulta ni devuelve datos',
      () async {
    expect(await const ServicioEnriquecimientoNulo().consultar(ean), isNull);
  });
}
