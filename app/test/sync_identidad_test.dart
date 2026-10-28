import 'package:drift/drift.dart' hide Column;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/sync/servicio_sync.dart';

import 'cliente_remoto_falso.dart';

void main() {
  late BaseDeDatos db;
  late ClienteRemotoFalso cliente;
  late String usuarioId;

  setUp(() async {
    db = BaseDeDatos.memoria();
    cliente = ClienteRemotoFalso();
    usuarioId = (await crearUsuarioConEtiqueta(db, 'Nadia')).id;
  });

  tearDown(() async {
    await db.close();
  });

  Future<Usuario> leerUsuarioLocal() async =>
      (await db.select(db.usuarios).get()).single;

  group('asegurarSesionAnonima — identidad anónima (AD-003, regla 9)', () {
    test('inicia sesión anónima una sola vez y persiste auth_uid', () async {
      final uid = await asegurarSesionAnonima(db, cliente);

      expect(cliente.iniciosSesionAnonimos, 1);
      expect(uid, 'uid-anon-1');
      expect((await leerUsuarioLocal()).authUid, 'uid-anon-1');

      // El auth_uid viaja al servidor (regla 9): queda encolado el usuario.
      final entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('usuario')))
          .get();
      expect(entradas, hasLength(1));
      expect(entradas.single.filaId, usuarioId);

      // Segunda llamada: no inicia otra sesión (signInAnonymously una vez).
      final uid2 = await asegurarSesionAnonima(db, cliente);
      expect(cliente.iniciosSesionAnonimos, 1);
      expect(uid2, uid);
    });

    test('con auth_uid guardado y sin sesión no vuelve a iniciar sesión',
        () async {
      await (db.update(db.usuarios)
            ..where((t) => t.id.equals(usuarioId)))
          .write(const UsuariosCompanion(authUid: Value('uid-guardado')));

      final uid = await asegurarSesionAnonima(db, cliente);

      expect(cliente.iniciosSesionAnonimos, 0);
      expect(uid, 'uid-guardado');
    });

    test('reutiliza la sesión existente sin iniciar otra', () async {
      cliente.uidSesion = 'uid-sesion-activa';

      final uid = await asegurarSesionAnonima(db, cliente);

      expect(cliente.iniciosSesionAnonimos, 0);
      expect(uid, 'uid-sesion-activa');
      expect((await leerUsuarioLocal()).authUid, 'uid-sesion-activa');
    });
  });
}
