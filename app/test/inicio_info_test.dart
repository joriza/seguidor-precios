import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/inicio/inicio_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
    PackageInfo.setMockInitialValues(
      appName: 'Seguidor de Precios',
      packageName: 'com.seguidorprecios.app',
      version: '0.1.2',
      buildNumber: '3',
      buildSignature: 'prueba',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  testWidgets('S2 v0.1.2: muestra la versión de la app', (tester) async {
    await tester.pumpWidget(envolver(InicioScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.text('Versión'), findsOneWidget);
    expect(find.text('0.1.2+3'), findsOneWidget);
  });

  testWidgets('S3 v0.1.2: catálogo base informa la cantidad de productos semilla',
      (tester) async {
    await db.into(db.productos).insert(ProductosCompanion.insert(
          id: 'sem-7790001112223',
          codigoBarras: const Value('7790001112223'),
          nombre: 'Arroz',
          unidad: 'g',
          contenidoNeto: const Value(500),
          origen: const Value('semilla'),
          creadoPor: 'u1',
          creadoEn: '2026-01-01T00:00:00',
          actualizadoEn: '2026-01-01T00:00:00',
        ));

    await tester.pumpWidget(envolver(InicioScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.text('Catálogo base'), findsOneWidget);
    expect(
      find.textContaining('1 productos incluidos en la app'),
      findsOneWidget,
    );
  });

  testWidgets('sin semillero informa cero (y que no se descarga nada)',
      (tester) async {
    await tester.pumpWidget(envolver(InicioScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 productos incluidos'), findsOneWidget);
    expect(find.textContaining('no se descarga nada'), findsOneWidget);
  });
}
