import 'dart:io';

import 'package:drift/drift.dart' hide Column, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart' show AuthException;

import 'package:seguidor_precios/data/cuenta.dart';
import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/sync/config_backend.dart';

import 'cliente_remoto_falso.dart';
import 'sync_arranque_test.dart';

/// S3 (R17/AD-003): cuenta opcional por email con enlace mágico. La
/// vinculación convierte la identidad anónima en cuenta real SIN migrar
/// datos: `auth_uid` del usuario local pasa al uid de la cuenta (misma
/// fila). La restauración en otra instalación es T4, fuera de este alcance.
void main() {
  late BaseDeDatos db;
  late ClienteRemotoFalso cliente;

  setUp(() async {
    db = BaseDeDatos.memoria();
    cliente = ClienteRemotoFalso();
  });

  tearDown(() async {
    await db.close();
  });

  AccountService servicio({ConfigBackend config = configDePrueba}) =>
      AccountService(
        baseDeDatos: db,
        cliente: cliente,
        config: config,
      );

  group('requestMagicLink — pedir el enlace mágico', () {
    test('normaliza el email y llama a la API de auth de Supabase', () async {
      await servicio().requestMagicLink('  Nadia@Example.COM ');

      expect(cliente.enlacesPedidos, ['nadia@example.com']);
    });

    test('con email inválido rechaza sin llamar a la API', () async {
      await expectLater(
        servicio().requestMagicLink('nadia-sin-arroba'),
        throwsA(isA<AccountError>()),
      );

      expect(cliente.enlacesPedidos, isEmpty);
    });

    test('sin nube configurada explica el error y no llama a la API',
        () async {
      await expectLater(
        servicio(config: sinConfigurar).requestMagicLink('nadia@example.com'),
        throwsA(isA<AccountError>()),
      );

      expect(cliente.enlacesPedidos, isEmpty);
    });
  });

  group('completeMagicLink — vincular la identidad local a la cuenta', () {
    test(
        'verifica el código y pone auth_uid en el usuario EXISTENTE sin '
        'duplicarlo', () async {
      // Instalación con identidad anónima ya resuelta (regla de sync 9).
      final usuarioId = (await crearUsuarioConEtiqueta(db, 'Nadia')).id;
      await (db.update(db.usuarios)..where((t) => t.id.equals(usuarioId)))
          .write(const UsuariosCompanion(authUid: Value('uid-anon-1')));
      cliente.uidSesion = 'uid-anon-1';
      cliente.uidCuentaEmail = 'uid-email-9';

      await servicio()
          .completeMagicLink(email: 'Nadia@Example.COM', code: '123456');

      // La identidad local NO se duplica: una sola fila de usuario, ahora
      // con el uid de la cuenta.
      final filas = await db.select(db.usuarios).get();
      expect(filas, hasLength(1));
      expect(filas.single.id, usuarioId);
      expect(filas.single.authUid, 'uid-email-9');

      // El código viajó a la API con el email normalizado.
      expect(cliente.codigosVerificados,
          [('nadia@example.com', '123456')]);

      // El cambio viaja en la próxima sync (regla de sync 9): una sola
      // entrada del usuario en el outbox.
      final entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('usuario')))
          .get();
      expect(entradas, hasLength(1));
      expect(entradas.single.filaId, usuarioId);
    });

    test('es idempotente si ya está vinculado a la misma cuenta', () async {
      final usuarioId = (await crearUsuarioConEtiqueta(db, 'Nadia')).id;
      await (db.update(db.usuarios)..where((t) => t.id.equals(usuarioId)))
          .write(const UsuariosCompanion(authUid: Value('uid-email-9')));
      cliente.uidCuentaEmail = 'uid-email-9';

      await servicio().completeMagicLink(email: 'nadia@example.com', code: '123456');
      await servicio().completeMagicLink(email: 'nadia@example.com', code: '123456');

      final filas = await db.select(db.usuarios).get();
      expect(filas, hasLength(1));
      expect(filas.single.authUid, 'uid-email-9');
      final entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('usuario')))
          .get();
      expect(entradas, hasLength(1));
    });

    test('con código inválido rechaza sin tocar la identidad local',
        () async {
      final usuarioId = (await crearUsuarioConEtiqueta(db, 'Nadia')).id;
      await (db.update(db.usuarios)..where((t) => t.id.equals(usuarioId)))
          .write(const UsuariosCompanion(authUid: Value('uid-anon-1')));
      cliente.errorAlCompletarEnlace =
          const AuthException('otp expired', code: 'otp_expired');

      await expectLater(
        servicio().completeMagicLink(email: 'nadia@example.com', code: '000000'),
        throwsA(isA<AccountError>()),
      );

      final filas = await db.select(db.usuarios).get();
      expect(filas.single.authUid, 'uid-anon-1');
    });
  });

  group('linkedEmail — estado visible para la UI', () {
    test('muestra el email de la cuenta; null si la identidad es anónima',
        () async {
      expect(await servicio().linkedEmail(), isNull);

      cliente.emailSesion = 'nadia@example.com';
      expect(await servicio().linkedEmail(), 'nadia@example.com');
    });
  });

  group('accountErrorMessage — errores humanos en español', () {
    test('sin conexión explica que la app funciona igual offline', () {
      final mensaje =
          accountErrorMessage(const SocketException('red caída'));
      expect(mensaje, contains('Sin conexión'));
    });

    test('código vencido pide uno nuevo', () {
      final mensaje = accountErrorMessage(
          const AuthException('otp expired', code: 'otp_expired'));
      expect(mensaje, contains('venció'));
    });

    test('error desconocido da un mensaje español no vacío', () {
      final mensaje =
          accountErrorMessage(const AuthException('boom', code: 'raro'));
      expect(mensaje, isNotEmpty);
    });

    test('corte de red no-socket (ClientException) también explica offline', () {
      // En el teléfono los cortes de red llegan como ClientException de
      // package:http, no como SocketException: mismo mensaje humano.
      final mensaje = accountErrorMessage(Exception(
          'ClientException: Connection closed before full header was '
          'received, uri = https://pipoladhxwuhcfjsuzkx.supabase.co'));
      expect(mensaje, contains('Sin conexión'));
    });
  });
}
