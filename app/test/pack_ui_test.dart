import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/precios/producto_comparacion_screen.dart';

/// S5 (v0.3.8): las presentaciones se desambiguan con la marca «Pack ×N»
/// cuando N > 1. Un producto con pack = 1 renderiza exactamente igual que
/// hoy (S6: compatibilidad visual).
void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Producto> insertarProducto(String id, String nombre, int pack) {
    return db.into(db.productos).insertReturning(
          ProductosCompanion.insert(
            id: id,
            nombre: nombre,
            unidad: 'g',
            contenidoNeto: const Value(500),
            pack: Value(pack),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  }

  testWidgets('el encabezado de comparación marca Pack ×10 cuando N > 1',
      (tester) async {
    final producto = await insertarProducto('p1', 'Fideos Marca', 10);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProductoComparacionScreen(baseDeDatos: db, producto: producto),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Fideos Marca · Pack ×10'), findsOneWidget);
  });

  testWidgets('pack = 1 no agrega marca (render idéntico al actual)',
      (tester) async {
    final producto = await insertarProducto('p2', 'Fideos Marca', 1);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProductoComparacionScreen(baseDeDatos: db, producto: producto),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Fideos Marca'), findsOneWidget);
    expect(find.textContaining('Pack ×'), findsNothing);
  });
}
