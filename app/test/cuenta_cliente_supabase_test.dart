import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:seguidor_precios/data/sync/cliente_supabase.dart';
import 'package:seguidor_precios/data/sync/config_backend.dart';
import 'package:supabase/supabase.dart' show AuthException;

// Correctivo v0.3.3: el flujo PKCE por defecto de supabase-dart exige un
// GotrueAsyncStorage para guardar el code_verifier y esta app no lo
// provee; signInWithOtp rompía con AssertionError (assert de gotrue,
// visible solo en debug) ANTES de tocar la red. El error legítimo contra
// una URL local sin servidor es de conexión, nunca de aserción.
void main() {
  test(
    'requestMagicLink llega a la red en vez de romper por el flujo PKCE',
    () async {
      final directorio = await Directory.systemTemp.createTemp(
        'cuenta_cliente_test',
      );
      addTearDown(() => directorio.delete(recursive: true));
      final cliente = ClienteSupabase(
        config: const ConfigBackend(
          // Puerto 9 (discard) sin servidor: la conexión se rechaza en el
          // momento, sin red externa ni esperas.
          url: 'http://127.0.0.1:9',
          claveAnonima: 'clave-de-prueba',
        ),
        directorio: directorio,
      );
      await expectLater(
        cliente.requestMagicLink('prueba@example.com'),
        throwsA(
          predicate<Object>(
            (error) =>
                error is SocketException ||
                error is ClientException ||
                error is AuthException,
            'error de red o del servidor, no AssertionError',
          ),
        ),
      );
    },
  );
}
