import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase/supabase.dart' show AuthException;

import 'local/base_de_datos.dart';
import 'sync/cliente_remoto.dart';
import 'sync/config_backend.dart';
import 'sync/servicio_sync.dart';

/// S3 (R17/AD-003): cuenta opcional multi-dispositivo por email con
/// enlace mágico.
///
/// La vinculación convierte la identidad anónima de la instalación en
/// cuenta real SIN migrar datos: Supabase envía el email con el enlace y
/// el código de 6 dígitos, y al completarlo `usuario.auth_uid` pasa al uid
/// de la cuenta (misma fila local, regla de sync 9). La restauración de
/// esos datos en OTRA instalación es T4 y no entra acá.
///
/// La cuenta es siempre opcional (R3, R15): sin nube configurada o sin
/// conexión la app funciona igual; estos métodos solo explican el error.

/// Error de la cuenta con mensaje ya pensado para mostrar al usuario
/// (español rioplatense, AD-007). La UI lo muestra tal cual.
class AccountError implements Exception {
  const AccountError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fachada de la UI hacia la cuenta opcional (espejo de [GestorSync] para
/// sync): valida entrada, habla con el [ClienteRemoto] y vincula la
/// identidad local. Nunca toca la red si no hay nube configurada.
class AccountService {
  AccountService({
    required this.baseDeDatos,
    this.cliente,
    this.config = configBackend,
  });

  final BaseDeDatos baseDeDatos;

  /// Cliente remoto inyectado; null = sin nube (la cuenta queda oculta).
  final ClienteRemoto? cliente;
  final ConfigBackend config;

  /// ¿Hay nube configurada para pedir el enlace? Sin backend el ingreso a
  /// la cuenta no se ofrece: es opcional (R17).
  bool get isEnabled => config.estaConfigurada && cliente != null;

  /// Email de la cuenta vinculada, o null si la identidad sigue anónima.
  Future<String?> linkedEmail() async => cliente?.accountEmail();

  /// Pide el enlace mágico: Supabase envía el email con el enlace y el
  /// código de 6 dígitos. [email] se normaliza (trim + minúsculas).
  Future<void> requestMagicLink(String email) async {
    _asegurarHabilitado();
    final emailNormalizado = normalizeEmail(email);
    if (!isValidEmail(emailNormalizado)) {
      throw const AccountError('Ingresá un email válido.');
    }
    try {
      await cliente!.requestMagicLink(emailNormalizado);
    } catch (e) {
      // El detalle crudo queda en consola (flutter run / adb logcat) para
      // diagnosticar en campo lo que el mapeador no clasifique.
      debugPrint('Cuenta: error al pedir el enlace: $e');
      // El error llega con mensaje humano (accountErrorMessage): el cliente
      // de la UI lo muestra tal cual.
      throw AccountError(accountErrorMessage(e));
    }
  }

  /// Completa la vinculación con el código de 6 dígitos del email: verifica
  /// el OTP, deja la sesión guardada y pone `auth_uid` de la cuenta en el
  /// usuario local EXISTENTE (sin duplicar identidad, regla de sync 9).
  Future<void> completeMagicLink({
    required String email,
    required String code,
  }) async {
    _asegurarHabilitado();
    final emailNormalizado = normalizeEmail(email);
    final codigo = code.trim();
    if (!isValidEmail(emailNormalizado)) {
      throw const AccountError('Ingresá un email válido.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      throw const AccountError('Ingresá el código de 6 dígitos del email.');
    }
    try {
      final uidCuenta = await cliente!.completeMagicLink(
        email: emailNormalizado,
        code: codigo,
      );
      await linkLocalIdentity(baseDeDatos, uidCuenta);
    } catch (e) {
      // Si la verificación falla, la identidad local queda exactamente como
      // estaba: la vinculación solo ocurre con el OTP verificado.
      debugPrint('Cuenta: error al completar la vinculación: $e');
      throw AccountError(accountErrorMessage(e));
    }
  }

  void _asegurarHabilitado() {
    if (!isEnabled) {
      throw const AccountError(
        'La cuenta necesita la nube configurada; la app funciona igual sin '
        'ella.',
      );
    }
  }
}

/// Normaliza el email como lo hace Supabase: sin espacios y en minúsculas.
String normalizeEmail(String email) => email.trim().toLowerCase();

/// Validación liviana de formato (el servidor revalida de verdad).
bool isValidEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

/// Mensaje humano en español para cualquier error de la vinculación
/// (red caída, código vencido, límite de envío, error del servidor).
String accountErrorMessage(Object error) {
  if (error is AccountError) return error.message;
  if (error is SocketException) {
    return 'Sin conexión: para la cuenta hace falta internet; el resto de '
        'la app funciona igual sin conexión.';
  }
  if (error is StateError) {
    // El servidor verificó el código pero no devolvió sesión (cliente
    // supabase): error determinado, no de red.
    return 'El servidor verificó el código pero no devolvió sesión. Pedí '
        'el enlace de nuevo y probá otra vez.';
  }
  if (error is AuthException) {
    switch (error.code) {
      case 'otp_expired':
        return 'El código ya venció. Pedí uno nuevo y probá de nuevo.';
      case 'over_email_send_rate_limit':
        return 'Se enviaron muchos emails seguidos. Esperá un rato y volvé '
            'a intentar.';
      case 'validation_failed':
        return 'Ingresá un email y el código como te los pide la app.';
    }
    final detalle = error.message.toLowerCase();
    if (detalle.contains('signups not allowed') ||
        detalle.contains('signup disabled')) {
      return 'El servidor no permite crear cuentas nuevas por ahora.';
    }
    if (error.statusCode == null || _pareceErrorDeRed(detalle)) {
      return 'Sin conexión: para la cuenta hace falta internet; el resto de '
          'la app funciona igual sin conexión.';
    }
    return 'No se pudo conectar con el servidor de cuentas. Probá de nuevo '
        'en un rato.';
  }
  // En el teléfono los cortes de red pueden llegar como ClientException de
  // package:http u otros errores con texto de red, no solo SocketException.
  if (_pareceErrorDeRed(error.toString().toLowerCase())) {
    return 'Sin conexión: para la cuenta hace falta internet; el resto de '
        'la app funciona igual sin conexión.';
  }
  // El tipo entre paréntesis permite diagnosticar desde la pantalla un
  // error que el mapeador aún no clasifica (se reporta tal cual).
  return 'Algo salió mal con la cuenta (${error.runtimeType}). Probá de '
      'nuevo.';
}

bool _pareceErrorDeRed(String detalleMensaje) =>
    detalleMensaje.contains('failed host lookup') ||
    detalleMensaje.contains('connection') ||
    detalleMensaje.contains('network') ||
    detalleMensaje.contains('socket');
