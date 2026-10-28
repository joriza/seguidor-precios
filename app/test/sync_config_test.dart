import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/sync/config_backend.dart';

void main() {
  group('config_backend — punto único de configuración (T2)', () {
    test('la configuración por defecto trae placeholders, no credenciales', () {
      expect(configBackend.url, contains('<<'));
      expect(configBackend.claveAnonima, contains('<<'));
      expect(configBackend.estaConfigurada, isFalse);
    });

    test('con credenciales reales queda configurada', () {
      const ConfigBackend lista = ConfigBackend(
        url: 'https://ejemplo.supabase.co',
        claveAnonima: 'clave-anonima-de-ejemplo',
      );
      expect(lista.estaConfigurada, isTrue);
    });
  });
}
