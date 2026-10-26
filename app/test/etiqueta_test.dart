import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/app.dart';
import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/features/inicio/inicio_screen.dart';
import 'package:seguidor_precios/features/precios/registro_precio_screen.dart';

void main() {
  late BaseDeDatos db;

  setUp(() async {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  group('usuarioActual / etiqueta (S14, R17)', () {
    test('crea usuario anónimo si no hay y no duplica al reconsultar',
        () async {
      final u1 = await usuarioActual(db);
      final u2 = await usuarioActual(db);

      expect(u1.etiqueta, 'Anónimo');
      expect(u2.id, u1.id);
      expect(await hayUsuario(db), isTrue);
    });

    test('cambiarEtiqueta actualiza la etiqueta del aportante', () async {
      await crearUsuarioConEtiqueta(db, 'Vale');
      await cambiarEtiqueta(db, 'Valentina');

      final u = await usuarioActual(db);
      expect(u.etiqueta, 'Valentina');
    });
  });

  group('primer inicio', () {
    testWidgets('pide la etiqueta, la guarda y no vuelve a preguntar',
        (tester) async {
      await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenida/o'), findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('campo-etiqueta')), 'Vale');
      await tester.tap(find.byKey(const ValueKey('btn-guardar-etiqueta')));
      await tester.pumpAndSettle();

      final u = await usuarioActual(db);
      expect(u.etiqueta, 'Vale');

      // Reinicio de la app: el usuario ya existe, no hay diálogo.
      await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenida/o'), findsNothing);
    });

    testWidgets('etiqueta vacía cae en Anónimo', (tester) async {
      await tester.pumpWidget(SeguidorPreciosApp(baseDeDatos: db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn-guardar-etiqueta')));
      await tester.pumpAndSettle();

      final u = await usuarioActual(db);
      expect(u.etiqueta, 'Anónimo');
    });
  });

  group('atribución (R17: la etiqueta viaja con cada dato)', () {
    testWidgets('el precio registrado queda atribuido al usuario local',
        (tester) async {
      final usuario = await crearUsuarioConEtiqueta(db, 'Vale');
      final producto = await db.into(db.productos).insertReturning(
            ProductosCompanion.insert(
              id: 'p1',
              nombre: 'Mayonesa',
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
              nombre: 'Almacén',
              creadoPor: 'u1',
              creadoEn: '2026-01-01T00:00:00',
              actualizadoEn: '2026-01-01T00:00:00',
            ),
          );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RegistroPrecioScreen(baseDeDatos: db, producto: producto),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '1500');
      await tester.tap(
          find.widgetWithText(FilledButton, 'Registrar precio'));
      await tester.pumpAndSettle();

      final precios = await db.select(db.precios).get();
      expect(precios, hasLength(1));
      expect(precios.single.cargadoPor, usuario.id);
    });

    testWidgets('cambiar la etiqueta desde Inicio actualiza y avisa',
        (tester) async {
      await crearUsuarioConEtiqueta(db, 'Vale');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: InicioScreen(baseDeDatos: db)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Vale'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('btn-etiqueta')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('campo-cambiar-etiqueta')), 'Valen');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Etiqueta actualizada'), findsOneWidget);
      final u = await usuarioActual(db);
      expect(u.etiqueta, 'Valen');
    });
  });
}
