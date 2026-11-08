import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/normalizacion.dart';
import 'package:seguidor_precios/features/historial/historial_producto_screen.dart';

/// v0.3.16 (T1/T2): piezas compartidas del historial compacto —
/// fecha corta (S2) y sparkline de tendencia (S4).
void main() {
  group('fechaCorta (S2)', () {
    test('mismo año: dd/mm sin año', () {
      expect(fechaCorta('2026-03-07', ahora: DateTime(2026, 11, 8)), '07/03');
    });

    test('año distinto: dd/mm/aaaa', () {
      expect(
        fechaCorta('2025-03-07', ahora: DateTime(2026, 11, 8)),
        '07/03/2025',
      );
    });

    test('día y mes con cero a la izquierda', () {
      expect(fechaCorta('2026-01-02', ahora: DateTime(2026, 1, 9)), '02/01');
    });

    test('sin `ahora` usa el año actual (mismo año → sin año)', () {
      final int anio = DateTime.now().year;
      expect(fechaCorta('$anio-03-07'), '07/03');
    });

    test('fecha con hora se recorta al día', () {
      expect(
        fechaCorta('2026-03-07T10:00:00', ahora: DateTime(2026, 5, 1)),
        '07/03',
      );
    });

    test('malformada o vacía se devuelve igual (defensivo)', () {
      expect(fechaCorta('sin-fecha'), 'sin-fecha');
      expect(fechaCorta(null), '');
    });
  });

  group('SparklineTendencia (S4)', () {
    Future<void> bombear(WidgetTester tester, Widget hijo) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: hijo)));
      await tester.pumpAndSettle();
    }

    Finder pinturaDelSparkline() => find.descendant(
          of: find.byType(SparklineTendencia),
          matching: find.byType(CustomPaint),
        );

    testWidgets('sin tomas no dibuja nada (degrada vacío)', (tester) async {
      await bombear(tester, const SparklineTendencia(valores: <double>[]));
      expect(pinturaDelSparkline(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('una sola toma se dibuja como punto sin romperse', (tester) async {
      await bombear(tester, const SparklineTendencia(valores: <double>[100]));
      expect(pinturaDelSparkline(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la serie completa llega al painter (N puntos)', (tester) async {
      const List<double> serie = <double>[100, 110, 99, 105, 120];
      await bombear(tester, const SparklineTendencia(valores: serie));

      final SparklineTendencia widget = tester.widget<SparklineTendencia>(
        find.byType(SparklineTendencia),
      );
      expect(widget.valores, same(serie));

      final CustomPaint pintura = tester.widget<CustomPaint>(
        pinturaDelSparkline(),
      );
      expect(pintura.painter, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}
