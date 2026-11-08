import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/precios/registro_precio_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  // El formulario es más alto que el surface por defecto: ampliamos para
  // que todos los campos y el botón sean alcanzables por tap().
  void superficieGrande(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<Producto> insertarProductoYComercio() async {
    final Producto producto = await db.into(db.productos).insertReturning(
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
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: 'c1',
            nombre: 'El Almacén',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    return producto;
  }

  String fechaDeHoy() {
    final DateTime hoy = DateTime.now();
    return '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
  }

  testWidgets('guarda el precio de hoy con el comercio preseleccionado', (tester) async {
    superficieGrande(tester);
    final Producto producto = await insertarProductoYComercio();
    await tester.pumpWidget(MaterialApp(
      home: RegistroPrecioScreen(baseDeDatos: db, producto: producto),
    ));

    await tester.enterText(find.byType(TextFormField).first, '1500');
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar precio'));
    await tester.pumpAndSettle();

    // El formulario se cerró tras guardar.
    expect(find.byType(RegistroPrecioScreen), findsNothing);

    final precios = await db.select(db.precios).get();
    expect(precios, hasLength(1));
    expect(precios.single.productoId, 'p1');
    expect(precios.single.comercioId, 'c1');
    expect(precios.single.precio, 1500);
    expect(precios.single.fechaToma, fechaDeHoy());
  });

  testWidgets('permite crear el comercio en el momento', (tester) async {
    superficieGrande(tester);
    final Producto producto = await insertarProductoYComercio();
    await (db.delete(db.comercios)..where((t) => t.id.equals('c1'))).go();

    await tester.pumpWidget(MaterialApp(
      home: RegistroPrecioScreen(baseDeDatos: db, producto: producto),
    ));

    await tester.tap(find.text('Crear comercio'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del comercio *'),
      'Kiosco de la esquina',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // El comercio creado queda seleccionado en el dropdown.
    expect(find.text('Kiosco de la esquina'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '900');
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar precio'));
    await tester.pumpAndSettle();

    final precios = await db.select(db.precios).get();
    expect(precios, hasLength(1));
    final comercios = await db.select(db.comercios).get();
    expect(precios.single.comercioId, comercios.single.id);
    expect(comercios.single.nombre, 'Kiosco de la esquina');
  });

  testWidgets('exige precio y comercio', (tester) async {
    superficieGrande(tester);
    final Producto producto = await insertarProductoYComercio();
    await (db.delete(db.comercios)..where((t) => t.id.equals('c1'))).go();

    await tester.pumpWidget(MaterialApp(
      home: RegistroPrecioScreen(baseDeDatos: db, producto: producto),
    ));

    await tester.tap(find.widgetWithText(FilledButton, 'Registrar precio'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá el precio'), findsOneWidget);
    expect(find.text('Elegí o creá un comercio'), findsOneWidget);
    expect(await db.select(db.precios).get(), isEmpty);
  });

  testWidgets('la fecha de toma es editable', (tester) async {
    superficieGrande(tester);
    final Producto producto = await insertarProductoYComercio();
    await tester.pumpWidget(MaterialApp(
      home: RegistroPrecioScreen(baseDeDatos: db, producto: producto),
    ));

    // El picker no admite fechas futuras (lastDate: hoy, sin fechas
    // futuras): el día a elegir debe ser hoy o anterior. Los primeros
    // 14 días del mes el '15' está deshabilitado y el tap no hace nada.
    // Elegimos un día determinista distinto de hoy siempre que se pueda:
    // el 15 si ya pasó; ayer si estamos entre el 2 y el 15; el propio 1
    // cuando hoy es día 1 (único día habilitado del mes: el flujo se
    // ejercita igual, aunque no cambia el valor visible).
    final hoy = DateTime.now();
    final int dia;
    if (hoy.day >= 16) {
      dia = 15;
    } else if (hoy.day >= 2) {
      dia = hoy.day - 1;
    } else {
      dia = 1;
    }
    final esperado = '-${dia.toString().padLeft(2, '0')}';
    // Los días 25..31 pueden duplicarse con los días "fuera de mes"
    // iniciales (antes del 1) y los días 1..6 con los finales (después
    // del 28..30); en la grilla los días corren en orden cronológico,
    // así que el elegido (del mes actual) es el primero si es chico y el
    // último si es grande. 7..24 nunca se duplican.
    final Finder celdaDia =
        dia >= 25 ? find.text('$dia').last : find.text('$dia').first;

    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();
    await tester.tap(celdaDia);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining(esperado), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '1800');
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar precio'));
    await tester.pumpAndSettle();

    final precios = await db.select(db.precios).get();
    expect(precios.single.fechaToma.endsWith(esperado), isTrue);
  });
}
