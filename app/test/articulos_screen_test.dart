import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/articulos/articulos_screen.dart';
import 'package:seguidor_precios/features/articulos/sin_clasificar_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Widget envolver(ArticulosScreen pantalla) => MaterialApp(
        home: Scaffold(body: pantalla),
      );

  testWidgets('crea un artículo con unidad base desde el diálogo', (tester) async {
    await tester.pumpWidget(envolver(ArticulosScreen(baseDeDatos: db)));
    await tester.pumpAndSettle(); // espera _cargar(): el botón aún no existe durante la carga

    await tester.tap(find.text('Nuevo artículo'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del artículo *'),
      'Mayonesa',
    );
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Unidad base'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('L').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Mayonesa'), findsOneWidget);

    final filas = await db.select(db.articulos).get();
    expect(filas, hasLength(1));
    expect(filas.single.nombre, 'Mayonesa');
    expect(filas.single.unidadBase, 'L');
  });

  testWidgets('renombra un artículo existente', (tester) async {
    await db.into(db.articulos).insert(
          ArticulosCompanion.insert(
            id: 'a1',
            nombre: 'Nombre viejo',
            unidadBase: 'kg',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await tester.pumpWidget(envolver(ArticulosScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del artículo *'),
      'Nombre nuevo',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre nuevo'), findsOneWidget);

    final fila = await (db.select(db.articulos)
          ..where((t) => t.id.equals('a1')))
        .getSingle();
    expect(fila.nombre, 'Nombre nuevo');
    expect(fila.unidadBase, 'kg'); // la unidad base no cambia al renombrar
  });

  testWidgets('muestra la cantidad de productos por artículo', (tester) async {
    await db.into(db.articulos).insert(
          ArticulosCompanion.insert(
            id: 'a1',
            nombre: 'Mayonesa',
            unidadBase: 'kg',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    for (final String id in <String>['p1', 'p2']) {
      await db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: id,
              nombre: 'Producto $id',
              unidad: 'g',
              contenidoNeto: const Value(500),
              articuloId: const Value('a1'),
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );
    }

    await tester.pumpWidget(envolver(ArticulosScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 producto(s)'), findsOneWidget);
  });

  // v0.3.9 (S2): entrada desde Artículos con el conteo N de productos sin
  // artículo (sin borrados).
  testWidgets('muestra la entrada Sin clasificar (N) sin contar borrados',
      (tester) async {
    await db.into(db.articulos).insert(
          ArticulosCompanion.insert(
            id: 'a1',
            nombre: 'Mayonesa',
            unidadBase: 'kg',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p1',
            nombre: 'Clasificado',
            unidad: 'g',
            articuloId: const Value('a1'),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p2',
            nombre: 'Sin clasificar',
            unidad: 'g',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: 'p3',
            nombre: 'Borrado sin clasificar',
            unidad: 'g',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
            borradoEn: const Value('2026-01-02T00:00:00'),
          ),
        );

    await tester.pumpWidget(envolver(ArticulosScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.text('Sin clasificar (1)'), findsOneWidget);
  });

  testWidgets('la entrada Sin clasificar abre la pantalla de clasificación',
      (tester) async {
    await tester.pumpWidget(envolver(ArticulosScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Sin clasificar'));
    await tester.pumpAndSettle();

    expect(find.byType(SinClasificarScreen), findsOneWidget);
    expect(find.text('No hay productos sin clasificar'), findsOneWidget);
  });
}
