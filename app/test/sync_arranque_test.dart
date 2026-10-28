import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/productos.dart';
import 'package:seguidor_precios/data/sync/config_backend.dart';
import 'package:seguidor_precios/data/sync/cola_saliente.dart';
import 'package:seguidor_precios/features/sync/gestor_sync.dart';
import 'package:seguidor_precios/features/sync/red.dart';

import 'cliente_remoto_falso.dart';

/// Configuración válida de prueba (nada de esto pega contra la red: el
/// cliente es [ClienteRemotoFalso]).
const ConfigBackend configDePrueba = ConfigBackend(
  url: 'https://ejemplo.supabase.co',
  claveAnonima: 'clave-anonima-de-prueba',
);

/// Configuración con placeholders: simula el estado previo a T7 (el dueño
/// todavía no completó URL y clave). Los tests NO usan [configBackend]
/// real para esto: el dueño ya cargó credenciales válidas en el repo.
const ConfigBackend sinConfigurar = ConfigBackend(
  url: '<<URL_DEL_PROYECTO_SUPABASE>>',
  claveAnonima: '<<CLAVE_ANONIMA_SUPABASE>>',
);

GestorSync gestorDePrueba(
  BaseDeDatos db,
  ClienteRemotoFalso cliente, {
  ConfigBackend config = configDePrueba,
  required TipoConexion conexion,
}) {
  return GestorSync(
    baseDeDatos: db,
    cliente: cliente,
    config: config,
    conexion: () async => conexion,
  );
}

/// Cliente cuyo ping siempre falla (simula la red caída justo en el ping).
class ClientePingRoto extends ClienteRemotoFalso {
  @override
  Future<void> ping() async {
    throw Exception('la red se cayó en el ping');
  }
}

void main() {
  test('sin backend configurado: el arranque es un no-op silencioso (R14/R15)',
      () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    // Cambio pendiente: aunque lo haya, sin configuración no se pregunta.
    await encolarUpsert(db, 'precio', 'pr-pendiente');

    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      // Configuración con placeholders: el camino de la app sin backend.
      config: sinConfigurar,
      conexion: () async => TipoConexion.wifi,
    );

    expect(gestor.habilitado, isFalse);
    final arranque = await gestor.alIniciar();

    expect(arranque.pingEnviado, isFalse);
    expect(arranque.avisoPendiente, isFalse);
    expect(cliente.pings, 0);
  });

  test('sin conectividad: no hay ping ni aviso', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    await encolarUpsert(db, 'precio', 'pr-pendiente');

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.ninguna)
        .alIniciar();

    expect(arranque.conexion, TipoConexion.ninguna);
    expect(arranque.pingEnviado, isFalse);
    expect(arranque.avisoPendiente, isFalse);
    expect(cliente.pings, 0);
  });

  test('R14: con datos móviles hay ping pero el aviso no aparece (R15)',
      () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    await encolarUpsert(db, 'precio', 'pr-pendiente');

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.movil)
        .alIniciar();

    expect(arranque.pingEnviado, isTrue);
    expect(cliente.pings, 1);
    expect(arranque.avisoPendiente, isFalse);
  });

  test('R14: el ping corre con WiFi aunque no haya nada para sincronizar',
      () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.wifi)
        .alIniciar();

    expect(arranque.pingEnviado, isTrue);
    expect(arranque.avisoPendiente, isFalse);
  });

  test('R14: un ping que falla no rompe el arranque ni el aviso', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClientePingRoto();
    await encolarUpsert(db, 'precio', 'pr-pendiente');

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.wifi)
        .alIniciar();

    expect(arranque.pingEnviado, isFalse);
    expect(arranque.avisoPendiente, isTrue);
  });

  test('R15: con WiFi y outbox pendiente pide confirmación', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    await encolarUpsert(db, 'precio', 'pr-pendiente');

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.wifi)
        .alIniciar();

    expect(arranque.avisoPendiente, isTrue);
  });

  test('R15: con WiFi, sin pendientes y sin sync previa no pregunta', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();

    // Decisión de diseño: "nunca sincronizó" no cuenta como "hace más de 7
    // días" — una instalación nueva con outbox vacío no molesta al iniciar.
    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.wifi)
        .alIniciar();

    expect(arranque.avisoPendiente, isFalse);
  });

  test('R15: con WiFi y último sync hace más de 7 días pregunta', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final ahora = DateTime.utc(2026, 11, 5, 10);
    await marcarSyncExitosa(db, ahora.subtract(const Duration(days: 8)));

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.wifi)
        .alIniciar(ahora: ahora);

    expect(arranque.avisoPendiente, isTrue);
  });

  test('R15: al cumplirse 7 días exactos todavía no pregunta', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final ahora = DateTime.utc(2026, 11, 5, 10);
    await marcarSyncExitosa(db, ahora.subtract(const Duration(days: 7)));

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.wifi)
        .alIniciar(ahora: ahora);

    expect(arranque.avisoPendiente, isFalse);
  });

  test('R15: con WiFi y último sync hace 6 días no pregunta', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final ahora = DateTime.utc(2026, 11, 5, 10);
    await marcarSyncExitosa(db, ahora.subtract(const Duration(days: 6)));

    final arranque = await gestorDePrueba(db, cliente,
            conexion: TipoConexion.wifi)
        .alIniciar(ahora: ahora);

    expect(arranque.avisoPendiente, isFalse);
  });

  test('sincronizar: sesión completa sube el outbox y marca la sync exitosa',
      () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final gestor = gestorDePrueba(db, cliente, conexion: TipoConexion.wifi);

    await crearUsuarioConEtiqueta(db, 'Vale');
    final producto = await altaProducto(db, nombre: 'Dulce de leche', unidad: 'g');
    expect(await cambiosPendientes(db), 2); // usuario + producto

    final resultado = await gestor.sincronizar();

    expect(resultado, isNotNull);
    expect(resultado!.filasSubidas, 2);
    expect((cliente.remoto['producto'] ?? []).map((f) => f['id']),
        contains(producto.id));
    expect(await cambiosPendientes(db), 0);
    expect(await ultimoSyncExitoso(db), isNotNull);
  });

  test('sincronizar: si el servidor falla devuelve null y no marca la sesión',
      () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso()..errorAlSubir = 'usuario';
    final gestor = gestorDePrueba(db, cliente, conexion: TipoConexion.wifi);

    await crearUsuarioConEtiqueta(db, 'Vale');
    await altaProducto(db, nombre: 'Dulce de leche', unidad: 'g');

    final resultado = await gestor.sincronizar();

    expect(resultado, isNull);
    expect(await ultimoSyncExitoso(db), isNull);
    expect(await cambiosPendientes(db), 2); // nada se perdió
  });

  test('sincronizar sin backend configurado no hace nada', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final cliente = ClienteRemotoFalso();
    final gestor = GestorSync(
      baseDeDatos: db,
      cliente: cliente,
      config: sinConfigurar, // placeholders
      conexion: () async => TipoConexion.wifi,
    );

    expect(await gestor.sincronizar(), isNull);
    expect(cliente.iniciosSesionAnonimos, 0);
  });

  test('estado(): expone pendientes y última sync para la UI', () async {
    final db = BaseDeDatos.memoria();
    addTearDown(db.close);
    final gestor = gestorDePrueba(db, ClienteRemotoFalso(),
        conexion: TipoConexion.wifi);

    final vacio = await gestor.estado();
    expect(vacio.habilitado, isTrue);
    expect(vacio.pendientes, 0);
    expect(vacio.ultimoSyncExitoso, isNull);

    await crearUsuarioConEtiqueta(db, 'Vale');
    final conDatos = await gestor.estado();
    expect(conDatos.pendientes, 1);
  });

  test('heurística de interfaces: WiFi reconocible y el resto no es WiFi',
      () {
    expect(conexionDesdeNombreInterfaz('wlan0'), TipoConexion.wifi);
    expect(conexionDesdeNombreInterfaz('Wi-Fi'), TipoConexion.wifi);
    expect(conexionDesdeNombreInterfaz('wlan1'), TipoConexion.wifi);
    expect(conexionDesdeNombreInterfaz('en0'), TipoConexion.wifi);
    expect(conexionDesdeNombreInterfaz('rmnet_data0'), TipoConexion.movil);
    expect(conexionDesdeNombreInterfaz('ccmni0'), TipoConexion.movil);
    expect(conexionDesdeNombreInterfaz('eth0'), TipoConexion.movil);
    expect(conexionDesdeNombreInterfaz('tun0'), TipoConexion.movil);
    expect(conexionDesdeNombreInterfaz(''), TipoConexion.movil);
  });
}
