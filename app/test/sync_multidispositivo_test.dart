import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/sync/cola_saliente.dart';
import 'package:seguidor_precios/data/sync/servicio_sync.dart';

import 'cliente_remoto_falso.dart';

/// Tests de multi-dispositivo (T4, S3 de fase 3): restaurar la identidad en
/// una instalación nueva o segunda. La misma cuenta debe CONVERGER a la
/// fila de usuario del servidor en lugar de bifurcar la identidad (el
/// servidor la rechazaría con 23505 contra uq_usuario_auth_uid). Es el
/// espejo de la convergencia por EAN de C2, pero por auth_uid de usuario.
/// Todo contra un cliente falso que aplica esa restricción del servidor.
void main() {
  late BaseDeDatos db;
  late ClienteRemotoFalso cliente;
  late String usuarioId;

  const t1 = '2026-01-01T10:00:00.000Z';
  const t2 = '2026-01-02T10:00:00.000Z';
  const t5 = '2026-01-05T10:00:00.000Z';
  const uidCuenta = 'uid-email-1';
  const idServidor = 'u-instalacion-1';

  setUp(() async {
    db = BaseDeDatos.memoria();
    cliente = ClienteRemotoFalso();
    usuarioId = (await crearUsuarioConEtiqueta(db, 'Nadia')).id;
  });

  tearDown(() async {
    await db.close();
  });

  /// Deja la identidad local vinculada a [authUid] con timestamp fijo
  /// (determinista para el LWW), como la deja [linkLocalIdentity].
  Future<void> vincularIdentidadLocal(
    String id, {
    required String authUid,
    String etiqueta = 'Nadia',
    String actualizadoEn = t1,
  }) async {
    await (db.update(db.usuarios)..where((t) => t.id.equals(id))).write(
      UsuariosCompanion(
        authUid: Value(authUid),
        etiqueta: Value(etiqueta),
        actualizadoEn: Value(actualizadoEn),
      ),
    );
    await encolarUpsert(db, 'usuario', id);
  }

  Map<String, dynamic> usuarioRemoto(
    String id, {
    required String authUid,
    required String etiqueta,
    String creadoEn = t1,
    String actualizadoEn = t1,
  }) =>
      {
        'id': id,
        'etiqueta': etiqueta,
        'auth_uid': authUid,
        'creado_en': creadoEn,
        'actualizado_en': actualizadoEn,
      };

  Future<Usuario?> usuarioLocal(String id) =>
      (db.select(db.usuarios)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<Usuario>> usuariosLocales() => db.select(db.usuarios).get();

  group('convergencia multi-dispositivo (T4: la misma cuenta no bifurca)', () {
    test(
        'instalación nueva que entra con la cuenta ya sincronizada converge a la fila del servidor',
        () async {
      // (a) Instalación fresca: la identidad local quedó vinculada a la
      // cuenta (linkLocalIdentity) y el servidor YA tiene esa cuenta bajo
      // el id de la instalación 1, con etiqueta más nueva (t2 > t1).
      cliente.uidSesion = uidCuenta;
      await vincularIdentidadLocal(usuarioId,
          authUid: uidCuenta, etiqueta: 'Anónimo', actualizadoEn: t1);
      cliente.sembrar('usuario', [
        usuarioRemoto(idServidor,
            authUid: uidCuenta, etiqueta: 'Nadia', actualizadoEn: t2),
      ]);

      final resultado = await sincronizarAhora(db, cliente);

      // La identidad local pasa a ser la fila del servidor; su etiqueta es
      // más nueva y gana por LWW.
      expect(await usuarioLocal(usuarioId), isNull);
      final adoptada = await usuarioLocal(idServidor);
      expect(adoptada, isNotNull);
      expect(adoptada!.etiqueta, 'Nadia');
      expect(adoptada.authUid, uidCuenta);
      expect(adoptada.actualizadoEn, t2);
      // Nada se subió: converger no es duplicar.
      expect(resultado.filasSubidas, 0);
      expect(await ultimoSyncExitoso(db), isNotNull);
    });

    test(
        'segunda instalación que sincronizó anónima converge al vincular la cuenta',
        () async {
      // (b) Primera sync anónima: la identidad local sube y la fila de la
      // cuenta (instalación 1) baja como fila de otro aportante. También
      // baja u2 con SU valoración (FK contra su fila de usuario) para
      // probar que la convergencia convive con datos de colaboradores.
      cliente.uidSesion = 'uid-anon-2';
      await vincularIdentidadLocal(usuarioId,
          authUid: 'uid-anon-2', etiqueta: 'Instalación 2', actualizadoEn: t1);
      cliente.sembrar('usuario', [
        usuarioRemoto('u2', authUid: 'uid-otro', etiqueta: 'Otros'),
        usuarioRemoto(idServidor,
            authUid: uidCuenta, etiqueta: 'Nadia', actualizadoEn: t2),
      ]);
      cliente.sembrar('producto', [
        {
          'id': 'p-u2',
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Fideos de u2',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': null,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t1,
          'borrado_en': null,
        },
      ]);
      cliente.sembrar('valoracion', [
        {
          'id': 'v-u2',
          'usuario_id': 'u2',
          'producto_id': 'p-u2',
          'gusto': 'no',
          'observacion': null,
          'creado_en': t1,
          'actualizado_en': t1,
        },
      ]);
      await sincronizarAhora(db, cliente);
      expect(await usuarioLocal(idServidor), isNotNull);

      // Vincula la cuenta: la identidad local pasa a llevar el auth_uid de
      // la cuenta, que el servidor YA tiene bajo otro id.
      await (db.update(db.usuarios)..where((t) => t.id.equals(usuarioId)))
          .write(const UsuariosCompanion(
        authUid: Value(uidCuenta),
        actualizadoEn: Value(t1),
      ));
      await encolarUpsert(db, 'usuario', usuarioId);
      cliente.uidSesion = uidCuenta;

      await sincronizarAhora(db, cliente);

      // Converge a la fila del servidor; su etiqueta (t2) es más nueva que
      // la del vínculo (t1) y gana por LWW.
      expect(await usuarioLocal(usuarioId), isNull);
      final adoptada = await usuarioLocal(idServidor);
      expect(adoptada!.etiqueta, 'Nadia');
      expect(adoptada.authUid, uidCuenta);
      // La identidad propia queda primera: la resolución local
      // (usuarioActual/leerUsuario) devuelve la primera fila de la tabla.
      // El re-anclaje convive con la FK de la valoración de u2 hacia SU
      // fila de usuario (se restaura con los ids exactos).
      final locales = await usuariosLocales();
      expect(locales.map((u) => u.id), containsAll(['u2', idServidor]));
      expect(locales.first.id, idServidor);
      // La valoración del colaborador no se toca: solo se re-apuntan los
      // aportes de la identidad que converge.
      final valoracionU2 = await (db.select(db.valoraciones)
            ..where((v) => v.id.equals('v-u2')))
          .getSingle();
      expect(valoracionU2.usuarioId, 'u2');
      // Sin residuos en la cola: el duplicado se descartó y el servidor
      // ya tiene la versión ganadora.
      expect(await cambiosPendientes(db), 0);
      expect(await ultimoSyncExitoso(db), isNotNull);
    });

    test(
        'LWW: si la etiqueta local es más nueva, gana bajo el id del servidor y vuelve a subir',
        () async {
      cliente.uidSesion = uidCuenta;
      await vincularIdentidadLocal(usuarioId,
          authUid: uidCuenta, etiqueta: 'Elegí acá', actualizadoEn: t5);
      cliente.sembrar('usuario', [
        usuarioRemoto(idServidor,
            authUid: uidCuenta,
            etiqueta: 'Del servidor',
            actualizadoEn: t2),
      ]);

      await sincronizarAhora(db, cliente);

      expect(await usuarioLocal(usuarioId), isNull);
      final adoptada = await usuarioLocal(idServidor);
      expect(adoptada!.etiqueta, 'Elegí acá');
      expect(adoptada.actualizadoEn, t5);
      // El contenido local ganó: queda encolado bajo el id del servidor
      // para que el servidor también converja (regla 4).
      final entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('usuario')))
          .get();
      expect(entradas.map((e) => e.filaId), [idServidor]);
      expect(await leerCursor(db, 'usuario'), t2);
    });

    test('los aportes del dispositivo se re-apuntan a la identidad adoptada',
        () async {
      cliente.uidSesion = uidCuenta;
      await vincularIdentidadLocal(usuarioId, authUid: uidCuenta);
      await db.into(db.productos).insert(
            ProductosCompanion.insert(
              id: 'p1',
              nombre: 'Harina',
              unidad: 'kg',
              creadoPor: usuarioId,
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      await db.into(db.comercios).insert(
            ComerciosCompanion.insert(
              id: 'c1',
              nombre: 'Verdulería',
              creadoPor: usuarioId,
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      await db.into(db.precios).insert(
            PreciosCompanion.insert(
              id: 'pr1',
              productoId: 'p1',
              comercioId: 'c1',
              precio: 1500,
              fechaToma: '2026-01-02',
              cargadoPor: usuarioId,
              cargadoEn: t1,
            ),
          );
      await db.into(db.valoraciones).insert(
            ValoracionesCompanion.insert(
              id: 'v1',
              usuarioId: usuarioId,
              productoId: 'p1',
              gusto: const Value('si'),
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      cliente.sembrar('usuario', [
        usuarioRemoto(idServidor,
            authUid: uidCuenta, etiqueta: 'Nadia', actualizadoEn: t2),
      ]);

      final resultado = await sincronizarAhora(db, cliente);

      // Los punteros siguen a la identidad adoptada; el dato del precio no
      // cambia (inmutabilidad, regla de integridad 1).
      final precio = await (db.select(db.precios)
            ..where((p) => p.id.equals('pr1')))
          .getSingle();
      expect(precio.cargadoPor, idServidor);
      expect(precio.precio, 1500);
      final valoracion = await (db.select(db.valoraciones)
            ..where((v) => v.id.equals('v1')))
          .getSingle();
      expect(valoracion.usuarioId, idServidor);
      final producto = await (db.select(db.productos)
            ..where((p) => p.id.equals('p1')))
          .getSingle();
      expect(producto.creadoPor, idServidor);
      final comercio = await (db.select(db.comercios)
            ..where((c) => c.id.equals('c1')))
          .getSingle();
      expect(comercio.creadoPor, idServidor);
      expect(resultado.reApuntados, 4);
    });

    test(
        'el duplicado local y su entrada de outbox se descartan; el servidor queda con una sola fila de la cuenta',
        () async {
      cliente.uidSesion = uidCuenta;
      await vincularIdentidadLocal(usuarioId, authUid: uidCuenta);
      cliente.sembrar('usuario', [
        usuarioRemoto(idServidor,
            authUid: uidCuenta, etiqueta: 'Nadia', actualizadoEn: t2),
      ]);

      await sincronizarAhora(db, cliente);

      // Local: quedó una sola identidad, la adoptada.
      final locales = await usuariosLocales();
      expect(locales.map((u) => u.id), [idServidor]);
      // Remoto: la fila duplicada NUNCA llegó; una sola fila por auth_uid.
      final remotas = cliente.remoto['usuario']!;
      expect(remotas.map((f) => f['id']), [idServidor]);
      // Sin residuos en la cola.
      expect(await cambiosPendientes(db), 0);
    });

    test('el push consulta la identidad existente y nunca sube el duplicado',
        () async {
      cliente.uidSesion = uidCuenta;
      await vincularIdentidadLocal(usuarioId, authUid: uidCuenta);
      cliente.sembrar('usuario', [
        usuarioRemoto(idServidor,
            authUid: uidCuenta, etiqueta: 'Nadia', actualizadoEn: t2),
      ]);

      await sincronizarAhora(db, cliente);

      // Consultó el puerto de identidad con el auth_uid de la cuenta.
      expect(cliente.idsUsuarioConsultados, [uidCuenta]);
      // El duplicado jamás llegó al servidor: ningún lote lo contiene y no
      // hubo lote de usuario alguno.
      final duplicadoSubido = cliente.lotesSubidos
          .expand((lote) => lote)
          .any((f) => f['id'] == usuarioId);
      expect(duplicadoSubido, isFalse);
      expect(cliente.ordenSubidas, isNot(contains('usuario')));
    });

    test(
        'el pull converge cuando baja la fila del servidor que ya lleva el auth_uid local',
        () async {
      // La identidad local ya lleva la cuenta pero sin entrada de outbox
      // (p. ej. cola perdida): el pull es la red de seguridad. Bajan u2
      // (otro aportante, t1) y la fila de la cuenta (t2).
      cliente.uidSesion = uidCuenta;
      await vincularIdentidadLocal(usuarioId,
          authUid: uidCuenta, etiqueta: 'Nueva', actualizadoEn: t1);
      await (db.delete(db.outbox)..where((e) => e.tabla.equals('usuario')))
          .go();
      cliente.sembrar('usuario', [
        usuarioRemoto('u2', authUid: 'uid-otro', etiqueta: 'Otros'),
        usuarioRemoto(idServidor,
            authUid: uidCuenta, etiqueta: 'Nadia', actualizadoEn: t2),
      ]);

      await sincronizarAhora(db, cliente);

      expect(await usuarioLocal(usuarioId), isNull);
      final adoptada = await usuarioLocal(idServidor);
      expect(adoptada!.etiqueta, 'Nadia');
      // u2 baja como cualquier otro aportante; la propia queda primera
      // aunque el pull la insertó después (re-anclaje de la identidad).
      expect((await usuariosLocales()).map((u) => u.id),
          containsAll(['u2', idServidor]));
      expect((await usuariosLocales()).first.id, idServidor);
      expect(await leerCursor(db, 'usuario'), t2);
      expect(await ultimoSyncExitoso(db), isNotNull);
    });

    test('la fila de otro usuario baja y se inserta normal (auth_uid distinto)',
        () async {
      // Comportamiento previo que no debe cambiar: solo converge cuando el
      // auth_uid remoto es el de la identidad local.
      cliente.uidSesion = 'uid-anon-1';
      await vincularIdentidadLocal(usuarioId, authUid: 'uid-anon-1');
      await (db.delete(db.outbox)..where((e) => e.tabla.equals('usuario')))
          .go();
      cliente.sembrar('usuario', [
        usuarioRemoto('u2', authUid: 'uid-otro', etiqueta: 'Otros'),
      ]);

      await sincronizarAhora(db, cliente);

      final locales = await usuariosLocales();
      expect(locales, hasLength(2));
      expect(locales.first.id, usuarioId); // la propia sigue primera
      expect(locales.last.id, 'u2'); // la ajena se insertó normal
      // Sin entrada de outbox, el push ni siquiera consultó la identidad.
      expect(cliente.idsUsuarioConsultados, isEmpty);
    });
  });
}
