import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/sync/config_backend.dart';

void main() {
  group('config_backend — punto único de configuración (T2)', () {
    test('la configuración por defecto apunta al proyecto real (T7)', () {
      expect(configBackend.url, isNot(contains('<<')));
      expect(configBackend.claveAnonima, isNot(contains('<<')));
      expect(configBackend.url, endsWith('.supabase.co'));
      expect(configBackend.claveAnonima, isNotEmpty);
      expect(configBackend.estaConfigurada, isTrue);
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
