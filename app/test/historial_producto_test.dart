import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/historial/historial_producto_screen.dart';

/// v0.3.16 (T1/T2, S2-S4): filas densas de 1 línea y encabezado de tendencia
/// en el historial cronológico. Solo presentación (S6): nada escribe a la base.
void main() {
  late BaseDeDatos db;
  int numeroPrecio = 0;

  setUp(() async {
    db = BaseDeDatos.memoria();
    numeroPrecio = 0;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertarProducto({
    String unidad = 'g',
    double? contenidoNeto = 500,
  }) async =>
      db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: 'p1',
              nombre: 'Mayonesa',
              unidad: unidad,
              contenidoNeto: Value(contenidoNeto),
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );

  Future<void> insertarComercio() =>
      db.into(db.comercios).insert(
            ComerciosCompanion.insert(
              id: 'c1',
              nombre: 'Almacén',
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );

  Future<void> insertarPrecio(double precio, String fechaToma) {
    numeroPrecio += 1;
    return db.into(db.precios).insert(
          PreciosCompanion.insert(
            id: 'pr$numeroPrecio',
            productoId: 'p1',
            comercioId: 'c1',
            precio: precio,
            fechaToma: fechaToma,
            cargadoPor: 'u1',
            cargadoEn: '2026-01-01T10:00:00',
          ),
        );
  }

  Future<void> bombear(WidgetTester tester) async {
    // Superficie alta: encabezado de tendencia + todas las filas a la vista.
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: HistorialProductoScreen(
        baseDeDatos: db,
        productoId: 'p1',
        nombre: 'Mayonesa',
      ),
    ));
    await tester.pumpAndSettle();
  }

  List<String> titulosDe(List<Widget> filas) => filas
      .map((w) => ((w as ListTile).title as Text).data!)
      .toList();

  testWidgets(
      'filas densas de 1 línea: precio · comercio · fecha corta, variación al final (S2/S3)',
      (tester) async {
    await insertarProducto();
    await insertarComercio();
    await insertarPrecio(100, '2020-01-01');
    await insertarPrecio(110, '2020-01-02');
    await insertarPrecio(99, '2020-01-03');
    await bombear(tester);

    final List<Widget> filas = tester.widgetList(find.byType(ListTile)).toList();
    expect(filas, hasLength(3));

    // Año distinto al actual → dd/mm/aaaa (S2).
    final List<String> titulos = titulosDe(filas);
    expect(titulos[0], '\$99.00 · Almacén · 03/01/2020');
    expect(titulos[1], '\$110.00 · Almacén · 02/01/2020');
    expect(titulos[2], '\$100.00 · Almacén · 01/01/2020');

    // Densas: una sola línea, sin subtítulo (S3).
    for (final Widget fila in filas) {
      expect((fila as ListTile).subtitle, isNull);
    }

    // Variación % al final, semántica R8 intacta.
    final List<String?> variaciones = filas
        .map((w) => (w as ListTile).trailing)
        .map((t) => t is Text ? t.data : null)
        .toList();
    expect(variaciones, <String?>['-10.0%', '+10.0%', null]);
  });

  testWidgets('fecha del año actual se muestra sin año (S2)', (tester) async {
    await insertarProducto();
    await insertarComercio();
    final int anio = DateTime.now().year;
    await insertarPrecio(100, '$anio-03-07');
    await bombear(tester);

    final String titulo =
        titulosDe(tester.widgetList(find.byType(ListTile)).toList()).single;
    expect(titulo, '\$100.00 · Almacén · 07/03');
    expect(titulo.contains('/$anio'), isFalse);
  });

  testWidgets(
      'tap expande el detalle completo de la toma y tap de nuevo lo cierra (S3)',
      (tester) async {
    await insertarProducto(); // 500 g → 99 / 0.5 = 198.00 / kg
    await insertarComercio();
    await insertarPrecio(99, '2020-01-03');
    await bombear(tester);

    // Cerrado: la fecha completa no se ve.
    expect(find.textContaining('Fecha completa: 2020-01-03'), findsNothing);

    await tester.tap(find.text('\$99.00 · Almacén · 03/01/2020'));
    await tester.pumpAndSettle();

    // Abierto: detalle completo, nada se borra (S3).
    // (La tarjeta de tendencia también muestra 198.00 / kg: con una sola
    // toma mín = prom = máx, por eso se acota al detalle de la toma.)
    expect(find.textContaining('Fecha completa: 2020-01-03'), findsOneWidget);
    expect(
        find.textContaining('Precio por unidad: 198.00 / kg'), findsOneWidget);

    await tester.tap(find.text('\$99.00 · Almacén · 03/01/2020'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fecha completa: 2020-01-03'), findsNothing);
  });

  testWidgets(
      'encabezado de tendencia: mín/prom/máx por unidad base, Δ% vs toma anterior y sparkline (S4)',
      (tester) async {
    await insertarProducto(); // 500 g → 200, 220, 198 / kg
    await insertarComercio();
    await insertarPrecio(100, '2020-01-01');
    await insertarPrecio(110, '2020-01-02');
    await insertarPrecio(99, '2020-01-03');
    await bombear(tester);

    expect(find.byKey(const ValueKey('tarjeta-tendencia')), findsOneWidget);
    // Agregados por unidad base (agregados.dart).
    expect(find.text('198.00 / kg'), findsOneWidget); // Mínimo
    expect(find.text('206.00 / kg'), findsOneWidget); // Promedio
    expect(find.text('220.00 / kg'), findsOneWidget); // Máximo
    // Δ% de la última toma (99) vs la anterior (110).
    expect(find.text('-10.0% vs toma anterior'), findsOneWidget);
    // Sparkline en línea (CustomPaint) con la serie de tomas.
    expect(
      find.descendant(
        of: find.byType(SparklineTendencia),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'una sola toma: agregados = el precio, sin Δ%, sparkline degrada a punto (S4)',
      (tester) async {
    await insertarProducto();
    await insertarComercio();
    await insertarPrecio(100, '2020-01-01');
    await bombear(tester);

    expect(find.text('200.00 / kg'), findsNWidgets(3)); // Mín = Prom = Máx
    expect(find.textContaining('vs toma anterior'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SparklineTendencia),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'producto sin unidad reconocible: agregados sobre el precio absoluto',
      (tester) async {
    await insertarProducto(unidad: 'pesado', contenidoNeto: null);
    await insertarComercio();
    await insertarPrecio(100, '2020-01-01');
    await insertarPrecio(99, '2020-01-02');
    await bombear(tester);

    expect(find.text(r'$99.00'), findsOneWidget); // Mínimo
    expect(find.text(r'$99.50'), findsOneWidget); // Promedio
    expect(find.text(r'$100.00'), findsOneWidget); // Máximo
    expect(find.text('-1.0% vs toma anterior'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
