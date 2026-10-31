import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/clasificacion.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';

/// v0.3.9 (S1): motor de sugerencia de artículo — función pura, sin I/O.
/// Match de tokens (categoria + nombre + marca del producto) contra el
/// nombre del artículo, case-insensitive y sin acentos, ordenado por
/// cantidad de tokens coincidentes (decisión L3: SIN tabla fija EN→ES).
Articulo articuloDePrueba(
  String id,
  String nombre, {
  String? borradoEn,
}) =>
    Articulo(
      id: id,
      nombre: nombre,
      unidadBase: 'kg',
      creadoPor: 'u1',
      creadoEn: '2026-01-01T00:00:00',
      actualizadoEn: '2026-01-01T00:00:00',
      borradoEn: borradoEn,
    );

void main() {
  group('tokensDeClasificacion', () {
    test('normaliza: minúsculas, sin acentos, separa por no-alfanumérico',
        () {
      expect(
        tokensDeClasificacion('Galletitas, Dulce de Leche (Chocolate)!'),
        <String>['galletitas', 'dulce', 'de', 'leche', 'chocolate'],
      );
      expect(
        tokensDeClasificacion('Café Ñoquis Azúcar'),
        <String>['cafe', 'noquis', 'azucar'],
      );
    });

    test('texto nulo, vacío o solo separadores no da tokens', () {
      expect(tokensDeClasificacion(null), isEmpty);
      expect(tokensDeClasificacion(''), isEmpty);
      expect(tokensDeClasificacion('  ,  '), isEmpty);
    });
  });

  group('sugerirArticulos', () {
    test('matchea por token común (Galletitas ↔ «Galletitas de chocolate»)',
        () {
      final sugerencias = sugerirArticulos(
        categoria: null,
        nombre: 'Galletitas de chocolate',
        articulos: <Articulo>[articuloDePrueba('a1', 'Galletitas')],
      );

      expect(sugerencias, hasLength(1));
      expect(sugerencias.single.articulo.id, 'a1');
      expect(sugerencias.single.coincidencias, 1);
    });

    test('los tokens de la categoría de OFF participan del match', () {
      final sugerencias = sugerirArticulos(
        categoria: 'Snacks, Sweet snacks, Biscuits, Cookies',
        nombre: 'Pepas de membrillo',
        articulos: <Articulo>[articuloDePrueba('a1', 'Cookies')],
      );

      expect(sugerencias.single.articulo.id, 'a1');
    });

    test('el token de la marca coincide también (S1)', () {
      final sugerencias = sugerirArticulos(
        categoria: null,
        nombre: 'Producto X',
        marca: 'Arcor',
        articulos: <Articulo>[articuloDePrueba('a1', 'Arcor')],
      );

      expect(sugerencias.single.articulo.id, 'a1');
      expect(sugerencias.single.coincidencias, 1);
    });

    test('case-insensitive y sin acentos en ambos lados del match', () {
      final sugerencias = sugerirArticulos(
        categoria: 'CafÉ, TE',
        nombre: 'CAFE molido',
        articulos: <Articulo>[articuloDePrueba('a1', 'Café')],
      );

      expect(sugerencias.single.articulo.id, 'a1');
      expect(sugerencias.single.coincidencias, 1);
    });

    test('ordena por cantidad de tokens coincidentes, descendente', () {
      final sugerencias = sugerirArticulos(
        categoria: null,
        nombre: 'Dulce de leche repostero',
        articulos: <Articulo>[
          articuloDePrueba('a1', 'Leche'),
          articuloDePrueba('a2', 'Dulce de leche'),
        ],
      );

      expect(sugerencias, hasLength(2));
      expect(sugerencias.first.articulo.id, 'a2'); // 3 tokens: dulce, de, leche
      expect(sugerencias.first.coincidencias, 3);
      expect(sugerencias.last.articulo.id, 'a1');
      expect(sugerencias.last.coincidencias, 1);
    });

    test('empate: orden determinista por nombre normalizado', () {
      final sugerencias = sugerirArticulos(
        categoria: null,
        nombre: 'Azúcar morena',
        articulos: <Articulo>[
          articuloDePrueba('a2', 'Azúcar negra'),
          articuloDePrueba('a1', 'Azúcar'),
        ],
      );

      expect(sugerencias.map((s) => s.articulo.id).toList(),
          <String>['a1', 'a2']); // «azucar» < «azucar negra»
    });

    test('empate total de nombre: desempate por id (determinismo)', () {
      final sugerencias = sugerirArticulos(
        categoria: null,
        nombre: 'Leche entera',
        articulos: <Articulo>[
          articuloDePrueba('b2', 'Leche'),
          articuloDePrueba('a1', 'Leche'),
        ],
      );

      expect(sugerencias.map((s) => s.articulo.id).toList(),
          <String>['a1', 'b2']);
    });

    test('sin tokens en común no sugiere nada (S1: alta manual)', () {
      final sugerencias = sugerirArticulos(
        categoria: 'Snacks, Biscuits',
        nombre: 'Papas fritas',
        articulos: <Articulo>[articuloDePrueba('a1', 'Galletitas')],
      );

      expect(sugerencias, isEmpty);
    });

    test('producto sin tokens útiles → lista vacía', () {
      final sugerencias = sugerirArticulos(
        categoria: null,
        nombre: '   ',
        articulos: <Articulo>[articuloDePrueba('a1', 'Galletitas')],
      );

      expect(sugerencias, isEmpty);
    });

    test('lista de artículos vacía → sin sugerencias', () {
      final sugerencias = sugerirArticulos(
        categoria: 'Biscuits',
        nombre: 'Galletitas',
        articulos: <Articulo>[],
      );

      expect(sugerencias, isEmpty);
    });

    test('tokens repetidos del producto cuentan una sola vez', () {
      final sugerencias = sugerirArticulos(
        categoria: 'Leche',
        nombre: 'Leche leche',
        articulos: <Articulo>[articuloDePrueba('a1', 'Leche')],
      );

      expect(sugerencias.single.coincidencias, 1);
    });

    test('nunca sugiere artículos borrados (S3)', () {
      final sugerencias = sugerirArticulos(
        categoria: null,
        nombre: 'Galletitas de chocolate',
        articulos: <Articulo>[
          articuloDePrueba('a1', 'Galletitas', borradoEn: '2026-01-02T00:00:00'),
        ],
      );

      expect(sugerencias, isEmpty);
    });
  });
}
