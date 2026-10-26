import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/normalizacion.dart';

void main() {
  group('factorConversion', () {
    test('g → kg es 0.001', () => expect(factorConversion('g'), 0.001));
    test('kg → kg es 1', () => expect(factorConversion('kg'), 1.0));
    test('mL → L es 0.001', () => expect(factorConversion('mL'), 0.001));
    test('unidad → unidad es 1', () => expect(factorConversion('unidad'), 1.0));
    test('unidad desconocida da null', () => expect(factorConversion('litrona'), isNull));
  });

  group('precioPorUnidad', () {
    test('mayonesa 500 g a 1500 → 3000 por kg', () {
      expect(
        precioPorUnidad(precio: 1500, unidad: 'g', unidadBase: 'kg', contenidoNeto: 500),
        closeTo(3000, 0.01),
      );
    });

    test('granel sin contenido neto: el precio ya es por unidad (AD-014)', () {
      expect(
        precioPorUnidad(precio: 4200, unidad: 'kg', unidadBase: 'kg'),
        4200,
      );
      expect(
        precioPorUnidad(precio: 900, unidad: 'm', unidadBase: 'm'),
        900,
      );
    });

    test('unidad → unidad sin contenido: 1 implícito', () {
      expect(
        precioPorUnidad(precio: 350, unidad: 'unidad', unidadBase: 'unidad'),
        350,
      );
    });

    test('sin contenido neto y unidades mezcladas → no comparable (null)', () {
      expect(
        precioPorUnidad(precio: 100, unidad: 'g', unidadBase: 'kg'),
        isNull,
      );
    });

    test('contenido neto <= 0 → no comparable (null)', () {
      expect(
        precioPorUnidad(precio: 100, unidad: 'g', unidadBase: 'kg', contenidoNeto: 0),
        isNull,
      );
    });

    test('unidad incompatible con la base del artículo → null', () {
      expect(
        precioPorUnidad(precio: 100, unidad: 'L', unidadBase: 'kg', contenidoNeto: 1),
        isNull,
      );
    });
  });
}
