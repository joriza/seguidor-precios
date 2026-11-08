import 'dart:io';

/// Tipo de conexión activa, con el nivel de detalle que piden R14 y R15:
/// al ping (R14) le sirve cualquier conectividad; el aviso de sync solo
/// aparece con WiFi (R15).
enum TipoConexion {
  /// Sin interfaces de red utilizables (modo avión, sin señal).
  ninguna,

  /// Conectividad que no es WiFi: datos móviles, cable, VPN u otra. No
  /// habilita el aviso de sync (R15); para el ping (R14) alcanza.
  movil,

  /// Conectividad WiFi: la única que habilita el aviso de sync (R15).
  wifi,

  /// v0.3.14 (S7): la detección falló (excepción del sistema). NO es
  /// «ninguna»: el gate de consulta NO bloquea (la consulta ya tiene su
  /// propio timeout de 6 s); el aviso de sync automático sigue exigiendo
  /// WiFi explícito (R15).
  desconocida,
}

/// Clasifica una interfaz de red por su nombre. Heurística sin dependencias
/// nuevas (pubspec intocable en esta tarea): la app corre en Android, donde
/// `wlan0` es WiFi y `rmnet_data0`/`ccmni0` son datos móviles; `en0`/`en1`
/// cubren iOS y los nombres de escritorio el modo dev. Todo lo no reconocido
/// como WiFi se trata como datos móviles: para R15 es mejor no preguntar
/// antes que avisar de más (la sync manual sigue disponible igual).
TipoConexion conexionDesdeNombreInterfaz(String nombre) {
  final String n = nombre.toLowerCase().replaceAll(RegExp('[ -]'), '');
  const List<String> prefijosWifi = <String>['wlan', 'wifi', 'en0', 'en1'];
  for (final String prefijo in prefijosWifi) {
    if (n.startsWith(prefijo)) return TipoConexion.wifi;
  }
  return TipoConexion.movil;
}

/// Firma de la enumeración de interfaces, inyectable para las pruebas (con
/// [NetworkInterface.list] no se pueden fabricar interfaces falsas).
typedef ListadorInterfaces = Future<List<NetworkInterface>> Function({
  bool includeLoopback,
  bool includeLinkLocal,
});

/// Detecta la conectividad actual enumerando las interfaces del sistema.
/// Nunca lanza. v0.3.14 (S7): ante un error del sistema devuelve
/// [TipoConexion.desconocida] — una excepción de detección no es «sin red»:
/// la consulta OFF consulta igual (tiene su propio timeout) y el aviso de
/// sync automático sigue requiriendo WiFi explícito (R15).
/// [listarInterfaces] inyecta la enumeración (pruebas); null = la real.
Future<TipoConexion> detectarConexion({ListadorInterfaces? listarInterfaces}) async {
  final ListadorInterfaces listar = listarInterfaces ?? NetworkInterface.list;
  try {
    final List<NetworkInterface> interfaces = await listar(
      includeLoopback: false,
      includeLinkLocal: false,
    );
    var resultado = TipoConexion.ninguna;
    for (final NetworkInterface interfaz in interfaces) {
      if (interfaz.addresses.isEmpty) continue;
      if (conexionDesdeNombreInterfaz(interfaz.name) == TipoConexion.wifi) {
        return TipoConexion.wifi;
      }
      resultado = TipoConexion.movil;
    }
    return resultado;
  } catch (_) {
    return TipoConexion.desconocida; // S7: desconocido ≠ ninguna
  }
}

/// v0.3.14 (S7): gate de conectividad para la consulta OFF (R14: cualquier
/// tipo alcanza; sólo «ninguna» — cero interfaces — bloquea). La excepción
/// de detección se clasifica como desconocida: se consulta igual. Heurística
/// única compartida por el escáner y «Completar desde OFF».
Future<bool> hayConexionParaConsulta({ListadorInterfaces? listarInterfaces}) async =>
    await detectarConexion(listarInterfaces: listarInterfaces) !=
    TipoConexion.ninguna;
