import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/comercios/alta_comercio_dialog.dart';
import 'package:seguidor_precios/features/comercios/comercios_screen.dart';

/// Anfitrión mínimo que abre el diálogo y muestra el resultado devuelto.
class _Anfitrion extends StatefulWidget {
  const _Anfitrion({required this.db});

  final BaseDeDatos db;

  @override
  State<_Anfitrion> createState() => _AnfitrionState();
}

class _AnfitrionState extends State<_Anfitrion> {
  String _resultado = 'sin abrir';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FilledButton(
              onPressed: () async {
                final comercio = await mostrarAltaComercio(context, widget.db);
                setState(() {
                  _resultado = comercio == null
                      ? 'cancelado'
                      : 'creado: ${comercio.nombre} / ${comercio.tipo ?? 'sin tipo'}';
                });
              },
              child: const Text('Abrir alta'),
            ),
            Text('resultado: $_resultado'),
          ],
        ),
      ),
    );
  }
}

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  testWidgets('alta de comercio: guarda y devuelve el comercio creado', (tester) async {
    await tester.pumpWidget(envolver(_Anfitrion(db: db)));

    await tester.tap(find.text('Abrir alta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del comercio *'),
      'El Almacén',
    );
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Tipo (opcional)'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('almacen').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('creado: El Almacén / almacen'), findsOneWidget);

    final filas = await db.select(db.comercios).get();
    expect(filas, hasLength(1));
    expect(filas.single.nombre, 'El Almacén');
    expect(filas.single.tipo, 'almacen');
    expect(filas.single.direccion, isNull);
  });

  testWidgets('cancelar no crea nada y devuelve null', (tester) async {
    await tester.pumpWidget(envolver(_Anfitrion(db: db)));

    await tester.tap(find.text('Abrir alta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del comercio *'),
      'No va',
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('resultado: cancelado'), findsOneWidget);
    expect(await db.select(db.comercios).get(), isEmpty);
  });

  testWidgets('exige el nombre', (tester) async {
    await tester.pumpWidget(envolver(_Anfitrion(db: db)));

    await tester.tap(find.text('Abrir alta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá el nombre'), findsOneWidget);
    expect(await db.select(db.comercios).get(), isEmpty);
  });

  testWidgets('la pantalla Comercios lista los cargados', (tester) async {
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: 'c1',
            nombre: 'El Almacén',
            tipo: const Value('almacen'),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
    await db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: 'c2',
            nombre: 'La Carnicería',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );

    await tester.pumpWidget(envolver(ComerciosScreen(baseDeDatos: db)));
    await tester.pumpAndSettle();

    expect(find.text('El Almacén'), findsOneWidget);
    expect(find.text('La Carnicería'), findsOneWidget);
    expect(find.text('almacen'), findsOneWidget);
    expect(find.text('Sin tipo'), findsOneWidget);
  });
}
