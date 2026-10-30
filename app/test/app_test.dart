import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';

void main() {
  testWidgets('muestra las 6 secciones y navega entre ellas', (WidgetTester tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);

    await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
    await tester.pumpAndSettle();

    // Primer inicio: pide la etiqueta de aportante (S14).
    await tester.enterText(find.byKey(const ValueKey('campo-etiqueta')), 'Vale');
    await tester.tap(find.byKey(const ValueKey('btn-guardar-etiqueta')));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(6));
    // S5 (v0.3.5): el uso principal es escanear — la app abre en Escanear.
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

  testWidgets('S1 v0.1.2: registrar precio y volver a Historial lo muestra (refresco)', (tester) async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);

    await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('campo-etiqueta')), 'Vale');
    await tester.tap(find.byKey(const ValueKey('btn-guardar-etiqueta')));
    await tester.pumpAndSettle();

    // Historial arranca vacío.
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Sin precios registrados todavía'), findsOneWidget);

    // Se registran datos "desde otra pestaña" (inserción directa = lo que
    // hace RegistroPrecioScreen).
    await db.into(db.comercios).insert(ComerciosCompanion.insert(
          id: 'c1',
          nombre: 'Almacén',
          creadoPor: 'u1',
          creadoEn: '2026-01-01T00:00:00',
          actualizadoEn: '2026-01-01T00:00:00',
        ));
    await db.into(db.productos).insert(ProductosCompanion.insert(
          id: 'p1',
          nombre: 'Mayonesa',
          unidad: 'g',
          contenidoNeto: const Value(500),
          creadoPor: 'u1',
          creadoEn: '2026-01-01T00:00:00',
          actualizadoEn: '2026-01-01T00:00:00',
        ));
    await db.into(db.precios).insert(PreciosCompanion.insert(
          id: 'pr1',
          productoId: 'p1',
          comercioId: 'c1',
          precio: 1500,
          fechaToma: '2026-01-02',
          cargadoPor: 'u1',
          cargadoEn: '2026-01-02T10:00:00',
        ));

    // Cambiar de pestaña y volver: debe refrescar (antes quedaba vacío).
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Mayonesa'), findsOneWidget);
    expect(find.textContaining('1 precio(s)'), findsOneWidget);
  });
}
