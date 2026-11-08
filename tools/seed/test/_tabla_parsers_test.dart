import 'package:seed_builder/src/transformar.dart';
import 'package:test/test.dart';

/// v0.3.15 (#13): tabla de referencia compartida de las 7 cadenas del
/// diagnóstico (S2) contra el parser de semilla Dart [parsearCantidad],
/// más variantes multipack. Semántica (S5): multipack «N x M unidad» /
/// «N unidades de M unidad» métrica → contenido TOTAL (N×M) en unidad
/// canónica {g, mL} — la semilla no tiene campo pack (el JSON v1 no lo
/// lleva); '10 unidades' → (unidad, N); '500 g e' → (g, 500): sufijos
/// informativos como la «e» del estiario europeo se toleran.
void main() {
  /// (quantity, esperado (contenido, unidad) o null).
  const List<(String, (double, String)?)> tabla = <
      (String, (double, String)?)>[
    // Las 7 cadenas del diagnóstico (S2).
    ('35 cl', (350.0, 'mL')),
    ('10 unidades', (10.0, 'unidad')),
    ('2 x 475 ml', (950.0, 'mL')), // total N×M (antes se descartaba)
    ('1,5 L', (1500.0, 'mL')),
    ('500 g e', (500.0, 'g')), // antes descartada por el anclado
    ('6 unidades de 500 ml', (3000.0, 'mL')), // antes descartada
    ('1 kg', (1000.0, 'g')),
    // Variantes multipack (S5).
    ('2x475ml', (950.0, 'mL')), // sin espacios
    ('3 x 1,5 l', (4500.0, 'mL')),
    ('4 unidades de 125 g', (500.0, 'g')),
    ('2 x 1 kg', (2000.0, 'g')),
  ];

  test('tabla de las 7 cadenas del diagnóstico + variantes multipack', () {
    for (final (String quantity, (double, String)? esperado) in tabla) {
      expect(parsearCantidad(quantity), esperado,
          reason: 'quantity "$quantity"');
    }
  });

  test('multipack sin unidad interpretable sigue sin ser interpretable', () {
    expect(parsearCantidad('2 x 475'), isNull);
    expect(parsearCantidad('6 unidades de'), isNull);
  });

  test('comportamiento previo que se conserva (sin descartes nuevos)', () {
    expect(parsearCantidad('500 g'), (500.0, 'g'));
    expect(parsearCantidad('750ml'), (750.0, 'mL'));
    expect(parsearCantidad('25 CL'), (250.0, 'mL'));
    expect(parsearCantidad('1kg'), (1000.0, 'g'));
    expect(parsearCantidad('pote grande'), isNull);
    expect(parsearCantidad(null), isNull);
  });
}
