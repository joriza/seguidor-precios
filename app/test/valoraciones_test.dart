import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/backup.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/valoraciones.dart';
import 'package:seguidor_precios/features/escaner/escaner_screen.dart';
import 'package:seguidor_precios/features/productos/producto_form_screen.dart';

void main() {
  late BaseDeDatos db;
  late String productoId;

  setUp(() async {
    db = BaseDeDatos.memoria();
    productoId = 'p1';
    await db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: productoId,
            nombre: 'Mayonesa',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('guardarValoracion / valoracionDe (v0.1.5)', () {
    test('crea la valoración con gusto y observación', () async {
      await guardarValoracion(
        db,
        productoId,
        gusto: 'si',
        observacion: 'Salió bueno, para repetir',
      );

      final v = await valoracionDe(db, productoId);
      expect(v, isNotNull);
      expect(v!.gusto, 'si');
      expect(v.observacion, 'Salió bueno, para repetir');
    });

    test('actualiza la valoración existente (upsert)', () async {
      await guardarValoracion(db, productoId, gusto: 'si', observacion: null);
      await guardarValoracion(
          db, productoId, gusto: 'no', observacion: 'No me gustó');

      final v = await valoracionDe(db, productoId);
      expect(v!.gusto, 'no');
      expect(v.observacion, 'No me gustó');
      expect(await db.select(db.valoraciones).get(), hasLength(1));
    });

    test('volver a neutro sin observación elimina la fila', () async {
      await guardarValoracion(db, productoId, gusto: 'si', observacion: 'x');
      await guardarValoracion(db, productoId, gusto: null, observacion: null);

      expect(await valoracionDe(db, productoId), isNull);
      expect(await db.select(db.valoraciones).get(), isEmpty);
    });

    test('observación sola (sin gusto) también se guarda', () async {
      await guardarValoracion(
          db, productoId, gusto: null, observacion: 'a probar');

      final v = await valoracionDe(db, productoId);
      expect(v!.gusto, isNull);
      expect(v.observacion, 'a probar');
    });

    test('el backup incluye y restaura valoraciones', () async {
      await guardarValoracion(
          db, productoId, gusto: 'si', observacion: 'para repetir');
      final backupJson = (await exportarBackup(db))['valoraciones'];
      expect(backupJson, hasLength(1));

      final db2 = BaseDeDatos.memoria();
      addTearDown(db2.close);
      // Restaura en otra instalación vacía (los productos viajan primero).
      await importarBackup(db2, backupFull(await exportarBackup(db)));
      final v = await valoracionDe(db2, productoId);
      expect(v!.gusto, 'si');
      expect(v.observacion, 'para repetir');
    });
  });

  group('formulario con valoración (v0.1.5)', () {
    testWidgets('editar producto: elegir Me gusta + observación guarda la fila',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProductoFormScreen(baseDeDatos: db, producto: productoActual()),
        ),
      ));
      await tester.pumpAndSettle();

      // El ListView es lazy: la sección de valoración queda bajo el pliegue y
      // no existe hasta arrastrar. Scroll hasta que cada widget se construya,
      // y recién entonces asegurar visibilidad y tocar/escribir.
      final Finder scrollable = find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(find.text('Me gusta 👍'), 200,
          scrollable: scrollable);
      await tester.ensureVisible(find.text('Me gusta 👍'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Me gusta 👍'));

      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Mi observación (opcional)'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mi observación (opcional)'),
        'Salió bueno',
      );

      await tester.scrollUntilVisible(find.text('Guardar cambios'), 200,
          scrollable: scrollable);
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      final v = await valoracionDe(db, productoId);
      expect(v!.gusto, 'si');
      expect(v.observacion, 'Salió bueno');
    });
  });

  group('escáner muestra la valoración (v0.1.5)', () {
    testWidgets('producto valorado muestra Mi valoración al encontrarlo',
        (tester) async {
      await guardarValoracion(
          db, productoId, gusto: 'no', observacion: 'No repito');
      await db.into(db.comercios).insert(ComerciosCompanion.insert(
            id: 'c1',
            nombre: 'Almacén',
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ));
      await db.into(db.precios).insert(PreciosCompanion.insert(
            id: 'pr1',
            productoId: productoId,
            comercioId: 'c1',
            precio: 1500,
            fechaToma: '2026-01-02',
            cargadoPor: 'u1',
            cargadoEn: '2026-01-02T10:00:00',
          ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EscanerScreen(baseDeDatos: db, mostrarCamara: false),
        ),
      ));
      await tester.enterText(find.byType(TextField), '7790001001001');
      // El producto del setUp no tiene código: insertar uno con código.
      await db.into(db.productos).insert(ProductosCompanion.insert(
            id: 'p2',
            codigoBarras: const Value('7790001001001'),
            nombre: 'Mayonesa con código',
            unidad: 'g',
            contenidoNeto: const Value(500),
            creadoPor: 'u1',
            creadoEn: '2026-01-01T00:00:00',
            actualizadoEn: '2026-01-01T00:00:00',
          ));
      await guardarValoracion(db, 'p2', gusto: 'no', observacion: 'No repito');
      await tester.tap(find.text('Buscar producto'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No me gusta'), findsOneWidget);
      expect(find.textContaining('No repito'), findsOneWidget);
    });
  });
}

/// La fila del producto del setUp (para abrir el formulario en edición).
Producto productoActual() {
  return Producto(
    id: 'p1',
    nombre: 'Mayonesa',
    unidad: 'g',
    contenidoNeto: 500,
    pack: 1,
    creadoPor: 'u1',
    creadoEn: '2026-01-01T00:00:00',
    actualizadoEn: '2026-01-01T00:00:00',
  );
}

/// Backup completo de [db] como texto JSON (para restaurar en otra base).
String backupFull(Map<String, dynamic> backup) => jsonEncode(backup);
