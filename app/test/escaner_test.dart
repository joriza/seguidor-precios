import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/escaner/escaner_screen.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  // En producción el shell (HomeShell) provee el Scaffold con el ancestro
  // Material que TextField necesita; el test replica esa estructura.
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

  testWidgets('búsqueda manual: producto existente muestra su nombre', (tester) async {
    await insertarProductoMayonesa();
    await tester.pumpWidget(envolver(
      EscanerScreen(baseDeDatos: db, mostrarCamara: false),
    ));

    await tester.enterText(find.byType(TextField), '7790001001001');
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mayonesa Marca A'), findsOneWidget);
  });

  testWidgets('búsqueda manual: producto inexistente lo informa', (tester) async {
    await tester.pumpWidget(envolver(
      EscanerScreen(baseDeDatos: db, mostrarCamara: false),
    ));

    await tester.enterText(find.byType(TextField), '7790001001999');
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No existe un producto con ese código'), findsOneWidget);
  });

  testWidgets('código vacío no dispara búsqueda', (tester) async {
    await tester.pumpWidget(envolver(
      EscanerScreen(baseDeDatos: db, mostrarCamara: false),
    ));

    await tester.tap(find.text('Buscar producto'));
    await tester.pump();

    expect(find.textContaining('No existe'), findsNothing);
    expect(find.textContaining('Producto encontrado'), findsNothing);
  });

  testWidgets('si el producto no existe, permite crearlo desde el escáner', (tester) async {
    // El formulario es más alto que el surface: ampliamos para que el
    // botón Guardar sea alcanzable (evita taps fuera de los límites).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(envolver(
      EscanerScreen(baseDeDatos: db, mostrarCamara: false),
    ));

    await tester.enterText(find.byType(TextField), '7790001001999');
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ProductoFormScreen),
        matching: find.text('7790001001999'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Nuevo desde escáner',
    );
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    // El formulario se cerró (guardó) y el escáner re-buscó: ahora encuentra.
    expect(find.byType(ProductoFormScreen), findsNothing);
    expect(
      find.textContaining('Producto encontrado: Nuevo desde escáner'),
      findsOneWidget,
    );
  });
}
