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

/// Detecta la conectividad actual enumerando las interfaces del sistema.
/// Nunca lanza: ante un error del sistema devuelve [TipoConexion.ninguna].
Future<TipoConexion> detectarConexion() async {
  try {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
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
    return TipoConexion.ninguna;
  }
}
