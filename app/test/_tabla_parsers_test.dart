import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seguidor_precios/data/enriquecimiento.dart';

/// v0.3.15 (#13): tabla de referencia compartida de las 7 cadenas del
/// diagnóstico (S2) + variantes multipack (S3/S4/S5), contra el parser
/// vivo `_cantidad`. La función es privada: se ejercita por la vía
/// pública [ServicioEnriquecimientoOFF.consultarConResultado] con un
/// MockClient (sin red real; la respuesta OFF inyecta la `quantity`).
///
/// Semántica esperada (S3/S4): multipack «N x M unidad» / «N unidades de
/// M unidad» métrica → pack = N y contenido por unidad = M en canónica
/// {g, mL}; 'cl' → mL (×10); '10 unidades' → (unidad, N); sufijos
/// informativos («e» del estiario) se toleran.
void main() {
  const String ean = '7790001001999';

  Future<DatosEnriquecidos> datosDe(String quantity) async {
    final http.Client cliente = MockClient((http.Request request) async =>
        http.Response(
            jsonEncode(<String, dynamic>{
              'status': 1,
              'product': <String, dynamic>{
                'product_name': 'Producto de prueba',
                'quantity': quantity,
              },
            }),
            200));
    final ResultadoEnriquecimiento resultado =
        await ServicioEnriquecimientoOFF(cliente: cliente)
            .consultarConResultado(ean);
    expect(resultado, isA<ResultadoDatos>(),
        reason: 'quantity "$quantity" debe mapear a datos');
    return (resultado as ResultadoDatos).datos;
  }

  /// (quantity, contenidoNeto, unidad, pack) — pack null si no es multipack.
  const List<(String, double?, String?, int?)> tabla = <
      (String, double?, String?, int?)>[
    // Las 7 cadenas del diagnóstico (S2).
    ('35 cl', 350, 'mL', null), // S4: antes 35 sin unidad (×350 errado).
    ('10 unidades', 10, 'unidad', null),
    ('2 x 475 ml', 475, 'mL', 2), // S3: antes 475 ml sin el ×2.
    ('1,5 L', 1.5, 'L', null),
    ('500 g e', 500, 'g', null), // sufijo informativo tolerado.
    ('6 unidades de 500 ml', 500, 'mL', 6), // S3: antes «6 unidades».
    ('1 kg', 1, 'kg', null),
  ];

  test('tabla de las 7 cadenas del diagnóstico contra el parser vivo', () async {
    for (final (
          String quantity,
          double? neto,
          String? unidad,
          int? pack
        ) in tabla) {
      final DatosEnriquecidos datos = await datosDe(quantity);
      expect(datos.contenidoNeto, neto, reason: 'contenido: "$quantity"');
      expect(datos.unidad, unidad, reason: 'unidad: "$quantity"');
      expect(datos.pack, pack, reason: 'pack: "$quantity"');
    }
  });

  test('variantes multipack (S3): formatos compactos y canónicas', () async {
    const List<(String, double?, String?, int?)> variantes = <
        (String, double?, String?, int?)>[
      ('2x475ml', 475, 'mL', 2), // sin espacios
      ('6 x 1,5 l', 1500, 'mL', 6), // L → mL canónica por unidad
      ('4 unidades de 125 g', 125, 'g', 4),
      ('2 x 1 kg', 1000, 'g', 2), // kg → g canónica por unidad
    ];
    for (final (
          String quantity,
          double? neto,
          String? unidad,
          int? pack
        ) in variantes) {
      final DatosEnriquecidos datos = await datosDe(quantity);
      expect(datos.contenidoNeto, neto, reason: 'contenido: "$quantity"');
      expect(datos.unidad, unidad, reason: 'unidad: "$quantity"');
      expect(datos.pack, pack, reason: 'pack: "$quantity"');
    }
  });

  test('sin multipack el pack queda en null (no confunde con pack 1)',
      () async {
    final DatosEnriquecidos datos = await datosDe('500 g');
    expect(datos.pack, isNull);
  });
}
