import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';

void main() {
  testWidgets('muestra las 5 secciones y navega entre ellas', (WidgetTester tester) async {
    await tester.pumpWidget(const SeguidorPreciosApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
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

    await tester.tap(find.text('Comercios'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Comercios')),
      findsOneWidget,
    );
  });
}
