import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/backup.dart';
import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/sync/cola_saliente.dart';
import 'package:seguidor_precios/data/valoraciones.dart';

void main() {
  late BaseDeDatos db;

  setUp(() {
    db = BaseDeDatos.memoria();
  });

  tearDown(() async {
    await db.close();
  });

  group('cola saliente, cursores y marca global (esquema v3)', () {
    test('la base nueva crea las tres tablas de sync', () async {
      expect(await db.select(db.outbox).get(), isEmpty);
      expect(await db.select(db.cursoresSync).get(), isEmpty);
      expect(await db.select(db.estadoSync).get(), isEmpty);
    });

    test('encolarUpsert deja una sola entrada por (tabla, fila)', () async {
      await encolarUpsert(db, 'producto', 'p1', ahora: DateTime.utc(2026, 1, 1));
      await encolarUpsert(db, 'producto', 'p1', ahora: DateTime.utc(2026, 1, 2));

      final entradas = await db.select(db.outbox).get();
      expect(entradas, hasLength(1));
      expect(entradas.single.tabla, 'producto');
      expect(entradas.single.filaId, 'p1');
      expect(entradas.single.operacion, operacionAlta);
      expect(entradas.single.encoladoEn, '2026-01-02T00:00:00.000Z');
      expect(await cambiosPendientes(db), 1);
    });

    test('encolarBaja reemplaza el intento pendiente por una baja', () async {
      await encolarUpsert(db, 'valoracion', 'v1');
      await encolarBaja(db, 'valoracion', 'v1');

      final entradas = await db.select(db.outbox).get();
      expect(entradas, hasLength(1));
      expect(entradas.single.operacion, operacionBaja);
    });

    test('tabla desconocida es rechazada (orden de dependencias único)',
        () async {
      expect(
        () => encolarUpsert(db, 'no_existe', 'x1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cursores por tabla independientes', () async {
      expect(await leerCursor(db, 'precio'), isNull);
      await guardarCursor(db, 'precio', '2026-03-01T00:00:00.000Z');
      await guardarCursor(db, 'articulo', '2026-03-02T00:00:00.000Z');

      expect(await leerCursor(db, 'precio'), '2026-03-01T00:00:00.000Z');
      expect(await leerCursor(db, 'articulo'), '2026-03-02T00:00:00.000Z');
      expect(await leerCursor(db, 'usuario'), isNull);
    });

    test('cursor desconocido es rechazado', () async {
      expect(
        () => guardarCursor(db, 'no_existe', 'x'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('marca global de última sync exitosa', () async {
      expect(await ultimoSyncExitoso(db), isNull);

      await marcarSyncExitosa(db, DateTime.utc(2026, 3, 1, 10, 30));
      expect(await ultimoSyncExitoso(db), DateTime.utc(2026, 3, 1, 10, 30));

      await marcarSyncExitosa(db, DateTime.utc(2026, 3, 2, 9, 0));
      expect(await ultimoSyncExitoso(db), DateTime.utc(2026, 3, 2, 9, 0));
    });

    test('el backup no incluye las tablas de sync (estado local, regla 8)',
        () async {
      await encolarUpsert(db, 'producto', 'p1');
      await guardarCursor(db, 'precio', '2026-03-01T00:00:00.000Z');
      await marcarSyncExitosa(db, DateTime.utc(2026, 3, 1));

      final backup = await exportarBackup(db);
      for (final clave in const ['outbox', 'cursores_sync', 'estado_sync']) {
        expect(backup.containsKey(clave), isFalse, reason: clave);
      }
    });
  });

  group('escrituras locales que encolan (PRESERVE + regla de sync 2)', () {
    test('guardar valoración encola su alta; volver a neutro encola la baja',
        () async {
      final usuario = await crearUsuarioConEtiqueta(db, 'Nadia');
      await db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: 'p1',
              nombre: 'Mayonesa',
              unidad: 'g',
              creadoPor: usuario.id,
              creadoEn: '2026-01-01T00:00:00.000Z',
              actualizadoEn: '2026-01-01T00:00:00.000Z',
            ),
          );

      await guardarValoracion(db, 'p1', gusto: 'si', observacion: 'rica');

      var entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('valoracion')))
          .get();
      expect(entradas, hasLength(1));
      expect(entradas.single.operacion, operacionAlta);
      final filaAlta = await db.select(db.valoraciones).getSingle();
      expect(entradas.single.filaId, filaAlta.id);

      // PRESERVE: volver a neutro sigue eliminando la fila (cero datos).
      await guardarValoracion(db, 'p1', gusto: null, observacion: '');
      expect(await db.select(db.valoraciones).get(), isEmpty);

      entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('valoracion')))
          .get();
      expect(entradas, hasLength(1));
      expect(entradas.single.operacion, operacionBaja);
      expect(entradas.single.filaId, filaAlta.id);
    });

    test('cambiar la etiqueta encola al usuario y conserva la etiqueta nueva',
        () async {
      final usuario = await crearUsuarioConEtiqueta(db, 'Nadia');
      await cambiarEtiqueta(db, 'Otra vez Nadia');

      final etiquetado = await leerUsuario(db);
      // PRESERVE: la etiqueta elegida queda guardada (R17).
      expect(etiquetado!.etiqueta, 'Otra vez Nadia');

      final entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('usuario')))
          .get();
      expect(entradas, hasLength(1));
      expect(entradas.single.filaId, usuario.id);
      expect(entradas.single.operacion, operacionAlta);
    });
  });
}
