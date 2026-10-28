import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase/supabase.dart';

import 'cliente_remoto.dart';
import 'config_backend.dart';

/// Adapter real del puerto [ClienteRemoto] sobre el paquete `supabase`.
///
/// La sesión anónima se persiste en un archivo local para que
/// `signInAnonymously` ocurra una sola vez por instalación (AD-003): al
/// reabrir la app se recupera la sesión con `recoverSession`. El uid también
/// queda en `usuario.auth_uid` a nivel de datos (regla de sync 9), así la
/// identidad sobrevive incluso si se pierde el archivo de sesión.
///
/// Nunca se instancia en tests: el núcleo de sync se prueba con un
/// [ClienteRemoto] falso, sin red.
class ClienteSupabase implements ClienteRemoto {
  ClienteSupabase({
    required ConfigBackend config,
    required Directory directorio,
  })  : assert(
          config.estaConfigurada,
          'Falta configurar la URL o la clave del backend en '
          'data/sync/config_backend.dart',
        ),
        _cliente = SupabaseClient(config.url, config.claveAnonima),
        _archivoSesion =
            File(p.join(directorio.path, 'supabase_sesion.json'));

  final SupabaseClient _cliente;
  final File _archivoSesion;

  @override
  Future<String?> uidSesionActual() async {
    var sesion = _cliente.auth.currentSession;
    sesion ??= await _recuperarSesion();
    return sesion?.user.id;
  }

  @override
  Future<String> iniciarSesionAnonima() async {
    final respuesta = await _cliente.auth.signInAnonymously();
    final sesion = respuesta.session ?? _cliente.auth.currentSession;
    if (sesion == null) {
      throw StateError('Supabase no devolvió sesión anónima');
    }
    await _guardarSesion(sesion);
    return sesion.user.id;
  }

  @override
  Future<void> ping() async {
    await _cliente.rpc('ping');
  }

  @override
  Future<String?> idCanonicoPorEan(String codigoBarras) async {
    return await _cliente.rpc(
      'dedup_ean',
      params: {'p_codigo_barras': codigoBarras},
    );
  }

  @override
  Future<Map<String, dynamic>?> traerFila({
    required String tabla,
    required String id,
  }) async {
    final fila = await _cliente.from(tabla).select().eq('id', id).maybeSingle();
    return fila as Map<String, dynamic>?;
  }

  @override
  Future<List<Map<String, dynamic>>> subirLote({
    required String tabla,
    required List<Map<String, dynamic>> filas,
  }) async {
    final filasNuevas = await _cliente.from(tabla).upsert(filas).select();
    return filasNuevas.cast<Map<String, dynamic>>().toList();
  }

  @override
  Future<void> borrarFila({
    required String tabla,
    required String id,
  }) async {
    await _cliente.from(tabla).delete().eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> descargarCambios({
    required String tabla,
    required String columnaCursor,
    required String desde,
    required int limite,
  }) async {
    final filas = await _cliente
        .from(tabla)
        .select()
        .gte(columnaCursor, desde)
        .order(columnaCursor)
        .limit(limite);
    return filas.cast<Map<String, dynamic>>().toList();
  }

  Future<Session?> _recuperarSesion() async {
    if (!await _archivoSesion.exists()) return null;
    try {
      await _cliente.auth.recoverSession(await _archivoSesion.readAsString());
      return _cliente.auth.currentSession;
    } catch (_) {
      // Sesión guardada corrupta o vencida: se descarta sin fallar; la
      // identidad sigue en usuario.auth_uid.
      try {
        await _archivoSesion.delete();
      } catch (_) {}
      return null;
    }
  }

  Future<void> _guardarSesion(Session sesion) async {
    await _archivoSesion.parent.create(recursive: true);
    await _archivoSesion.writeAsString(jsonEncode(sesion.toJson()));
  }
}
