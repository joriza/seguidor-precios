import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/local/base_de_datos.dart';
import 'data/sync/cliente_supabase.dart';
import 'data/sync/config_backend.dart';
import 'features/sync/gestor_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final BaseDeDatos baseDeDatos = BaseDeDatos();

  // T4: la nube colaborativa solo se conecta con la configuración completa
  // (URL + anon key en data/sync/config_backend.dart; la completa el dueño
  // en T7). Mientras haya placeholders no se crea el gestor: la app es
  // 100% local (R3) y nada del arranque toca la red.
  GestorSync? gestorSync;
  if (configBackend.estaConfigurada) {
    try {
      gestorSync = GestorSync(
        baseDeDatos: baseDeDatos,
        cliente: ClienteSupabase(
          config: configBackend,
          directorio: await getApplicationDocumentsDirectory(),
        ),
      );
    } catch (_) {
      // Sin acceso al almacenamiento para la sesión anónima: se sigue solo
      // local, sin bloquear el uso de la app.
      gestorSync = null;
    }
  }

  runApp(SeguidorPreciosApp(baseDeDatos: baseDeDatos, gestorSync: gestorSync));
}
