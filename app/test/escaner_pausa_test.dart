import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/escaner/escaner_screen.dart';

/// #11 (v0.3.12): la cámara se pausa tras una lectura válida y reanuda
/// con «Escanear de nuevo». Sin cámara (mostrarCamara: false) la pausa se
/// ejercita con [EscanerScreenState.simularDeteccion], el mismo camino que
/// usa MobileScanner.onDetect en producción.
void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Widget envolver(EscanerScreen pantalla) => MaterialApp(
        home: Scaffold(body: pantalla),
      );

  Future<void> insertarProductoMayonesa() {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p1',
            codigoBarras: const Value('7790001001001'),
            nombre: 'Mayonesa Marca A',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  testWidgets('una lectura de cámara pausa el escaneo y muestra «Escanear de nuevo»',
      (tester) async {
    await insertarProductoMayonesa();
    await tester.pumpWidget(envolver(
      EscanerScreen(baseDeDatos: db, mostrarCamara: false),
    ));

    tester
        .state<EscanerScreenState>(find.byType(EscanerScreen))
        .simularDeteccion('7790001001001');
    await tester.pumpAndSettle();

    expect(find.textContaining('Mayonesa Marca A'), findsOneWidget);
    expect(find.byKey(const ValueKey('btn-reanudar')), findsOneWidget);
  });

  testWidgets('mientras está pausada, una nueva lectura se ignora', (tester) async {
    await insertarProductoMayonesa();
    await tester.pumpWidget(envolver(
      EscanerScreen(baseDeDatos: db, mostrarCamara: false),
    ));

    final estado =
        tester.state<EscanerScreenState>(find.byType(EscanerScreen));
    estado.simularDeteccion('7790001001001');
    await tester.pumpAndSettle();

    // Lectura falsa de un segundo código mientras la cámara sigue apuntando:
    // hoy la procesaría (lectura falsa), tras la pausa debe ignorarse.
    estado.simularDeteccion('7790001002999');
    await tester.pumpAndSettle();

    expect(find.textContaining('Mayonesa Marca A'), findsOneWidget);
    expect(find.textContaining('No existe un producto'), findsNothing);
  });

  testWidgets('«Escanear de nuevo» reanuda: limpia resultado y oculta el botón',
      (tester) async {
    await insertarProductoMayonesa();
    await tester.pumpWidget(envolver(
      EscanerScreen(baseDeDatos: db, mostrarCamara: false),
    ));

    tester
        .state<EscanerScreenState>(find.byType(EscanerScreen))
        .simularDeteccion('7790001001001');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('btn-reanudar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('btn-reanudar')), findsNothing);
    expect(find.textContaining('Mayonesa Marca A'), findsNothing);
    // El campo de código queda vacío para la próxima lectura.
    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.controller!.text, isEmpty);
  });
}
