import 'package:flutter/foundation.dart';

import '../../data/local/base_de_datos.dart';
import '../../data/sync/cliente_remoto.dart';
import '../../data/sync/config_backend.dart';
import '../../data/sync/cola_saliente.dart';
import '../../data/sync/servicio_sync.dart';
import 'red.dart';

/// Umbral del aviso R15: "más de 7 días" desde la última sync exitosa.
const int diasParaAvisarSync = 7;

/// Resultado del arranque de red (T4): qué se hizo sin abrir ningún
/// diálogo. [pingEnviado] alimenta R14; [avisoPendiente] pide a la UI que
/// muestre la confirmación de R15. La sync nunca corre acá adentro.
class ArranqueRed {
  bool pingEnviado = false;
  bool avisoPendiente = false;
  TipoConexion conexion = TipoConexion.ninguna;
}

/// Estado de sync visible en la UI (indicador y diálogos), leído siempre
/// desde el núcleo de sync (outbox y marca global, regla de sync 8).
class EstadoSync {
  const EstadoSync({
    required this.habilitado,
    this.pendientes,
    this.ultimoSyncExitoso,
  });

  /// ¿Hay backend colaborativo configurado y conectable?
  final bool habilitado;

  /// Cambios en el outbox; null mientras se está cargando.
  final int? pendientes;

  /// Marca global de la última sesión de sync exitosa (R15).
  final DateTime? ultimoSyncExitoso;
}

/// Condición del aviso R15: SOLO con WiFi y (outbox pendiente o más de 7
/// días desde la última sync exitosa). "Nunca sincronizó" con outbox vacío
/// no cuenta como "hace más de 7 días": una instalación nueva sin cambios
/// propios no molesta al iniciar (y con pendientes ya avisa por otro lado).
Future<bool> convieneAvisarSync(
  BaseDeDatos db,
  TipoConexion conexion, {
  DateTime? ahora,
}) async {
  if (conexion != TipoConexion.wifi) return false;
  if (await cambiosPendientes(db) > 0) return true;
  final DateTime? ultimo = await ultimoSyncExitoso(db);
  if (ultimo == null) return false;
  return (ahora ?? DateTime.now())
      .toUtc()
      .isAfter(ultimo.add(const Duration(days: diasParaAvisarSync)));
}

/// Fachada de la UI hacia el núcleo de sync (T4): ping y aviso del
/// arranque (R14/R15), sync manual siempre disponible y estado para el
/// indicador. Nunca lanza hacia la UI y nunca sincroniza por su cuenta:
/// la sincronización requiere acción del usuario (R15).
///
/// Sin backend configurado (o sin cliente) todo es un no-op silencioso:
/// la app se usa igual, 100% local (R3).
class GestorSync {
  GestorSync({
    required this.baseDeDatos,
    this.cliente,
    this.config = configBackend,
    Future<TipoConexion> Function()? conexion,
  }) : _conexion = conexion ?? detectarConexion;

  final BaseDeDatos baseDeDatos;

  /// Cliente remoto inyectado; null = sin nube (la app funciona igual).
  final ClienteRemoto? cliente;
  final ConfigBackend config;
  final Future<TipoConexion> Function() _conexion;

  /// Último error de sincronización (para que la UI muestre el detalle
  /// real en lugar de un mensaje genérico); null si la última sync no
  /// falló. Nunca contiene datos del usuario, solo la excepción.
  Object? ultimoError;

  /// El colaborativo solo se activa con la configuración completa (T7 la
  /// completa el dueño); mientras tanto, cero llamadas de red.
  bool get habilitado => config.estaConfigurada && cliente != null;

  /// Arranque de la app (R14 + R15), sin datos en juego:
  /// 1. sin backend configurado → no-op;
  /// 2. sin conectividad → no-op;
  /// 3. con cualquier conectividad → ping mínimo (R14);
  /// 4. solo con WiFi y condición de R15 → pedir confirmación a la UI.
  Future<ArranqueRed> alIniciar({DateTime? ahora}) async {
    final arranque = ArranqueRed();
    if (!habilitado) return arranque;

    try {
      arranque.conexion = await _conexion();
    } catch (_) {
      return arranque;
    }
    if (arranque.conexion == TipoConexion.ninguna) return arranque;

    try {
      await cliente!.ping();
      arranque.pingEnviado = true;
    } catch (_) {
      // El ping es una mitigación (R14), no un requisito: si falla, el
      // arranque y el aviso siguen igual.
    }

    arranque.avisoPendiente = await convieneAvisarSync(
      baseDeDatos,
      arranque.conexion,
      ahora: ahora,
    );
    return arranque;
  }

  /// Sesión completa de sync (identidad → push → pull → marca). Devuelve
  /// null si no hay backend o si algo falla: los datos siguen en el
  /// dispositivo (R3) y el outbox conserva lo pendiente. El detalle del
  /// fallo queda en [ultimoError] para la UI y la consola.
  Future<ResultadoSync?> sincronizar() async {
    if (!habilitado) return null;
    try {
      return await sincronizarAhora(baseDeDatos, cliente!);
    } catch (e) {
      ultimoError = e;
      debugPrint('GestorSync: la sincronización falló: $e');
      return null;
    }
  }

  /// Estado actual para el indicador y los diálogos.
  Future<EstadoSync> estado() async => EstadoSync(
        habilitado: habilitado,
        pendientes: await cambiosPendientes(baseDeDatos),
        ultimoSyncExitoso: await ultimoSyncExitoso(baseDeDatos),
      );
}
