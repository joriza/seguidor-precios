import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/precios/producto_comparacion_screen.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';

/// Backlog #5 (v0.3.10): el EAN duplicado se descubre TEMPRANO — al abrir
/// el formulario de alta con un código que ya existe (o al tipearlo), la
/// app avisa y ofrece ir al producto existente en vez de llegar con toda
/// la carga hecha al error de guardado. La edición nunca muestra el aviso;
/// «Cargar de todos modos» lo cierra y el error de UNIQUE queda de red de
/// seguridad.
void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  void superficieGrande(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget envolver(ProductoFormScreen pantalla) => MaterialApp(
        key: UniqueKey(),
        home: Scaffold(body: pantalla),
      );

  Future<void> insertarProductoExistente() {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p1',
            codigoBarras: const Value('7790001001001'),
            nombre: 'Ya existe',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  testWidgets(
      'alta con EAN existente avisa temprano y ofrece ir al producto '
      '(S1/S2)', (tester) async {
    superficieGrande(tester);
    await insertarProductoExistente();

    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      codigoBarrasInicial: '7790001001001',
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('aviso-duplicado')), findsOneWidget);
    expect(find.textContaining('Ya existe'), findsWidgets);
    expect(find.byKey(const ValueKey('btn-ir-producto')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('btn-cargar-igual')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('btn-ir-producto')));
    await tester.pumpAndSettle();
    expect(find.byType(ProductoComparacionScreen), findsOneWidget);
  });

  testWidgets('alta con EAN nuevo no muestra aviso (S3)', (tester) async {
    superficieGrande(tester);
    await insertarProductoExistente();

    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      codigoBarrasInicial: '7790009999999',
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('aviso-duplicado')), findsNothing);
  });

  testWidgets('editar nunca muestra el aviso (S3)', (tester) async {
    superficieGrande(tester);
    await insertarProductoExistente();
    final producto =
        await (db.select(db.productos)..where((t) => t.id.equals('p1')))
            .getSingle();

    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      producto: producto,
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('aviso-duplicado')), findsNothing);
  });

  testWidgets('«Cargar de todos modos» cierra el aviso', (tester) async {
    superficieGrande(tester);
    await insertarProductoExistente();

    await tester.pumpWidget(envolver(ProductoFormScreen(
      baseDeDatos: db,
      codigoBarrasInicial: '7790001001001',
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('aviso-duplicado')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('btn-cargar-igual')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('aviso-duplicado')), findsNothing);
  });

  testWidgets(
      'alta manual: tipear un EAN existente dispara el aviso (S1, '
      're-chequeo en vivo)', (tester) async {
    superficieGrande(tester);
    await insertarProductoExistente();

    await tester.pumpWidget(envolver(ProductoFormScreen(baseDeDatos: db)));
    expect(find.byKey(const ValueKey('aviso-duplicado')), findsNothing);

    await tester.enterText(
        find.byKey(const ValueKey('campo-codigo')), '7790001001001');
    // Debounce de 500 ms: avanzar el reloj más allá y esperar el frame.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('aviso-duplicado')), findsOneWidget);
  });
}
