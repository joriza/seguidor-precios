import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';

void main() {
  testWidgets('muestra las 6 secciones y navega entre ellas', (WidgetTester tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);

    await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(6));
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Inicio')),
      findsOneWidget,
    );

    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Escanear')),
      findsOneWidget,
    );

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Buscar')),
      findsOneWidget,
    );

    await tester.tap(find.text('Comercios'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Comercios')),
      findsOneWidget,
    );
  });
}
