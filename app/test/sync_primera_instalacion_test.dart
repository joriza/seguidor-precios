import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/local/importar_semilla.dart';
import 'package:seguidor_precios/data/sync/servicio_sync.dart';

import 'cliente_remoto_falso.dart';

/// Reproducción del fallo de campo (v0.3.3, equipo nuevo): la primera sync
/// de una instalación nueva con semilla local y el catálogo ya cargado en
/// el servidor aborta con FOREIGN KEY al insertar precios.
///
/// Forma real del estado (dump del servidor 2026-10-30): 428 productos con
/// EAN (en su mayoría = pack semilla bajo id uuid5 en el servidor),
/// 2 comercios, 7 precios (un par duplicado), 3 usuarios. La semilla se
/// importa HOY: su actualizado_en es más nuevo que todo el servidor.
void main() {
  late BaseDeDatos db;
  late ClienteRemotoFalso cliente;

  const semillaTs = '2026-10-30T16:00:00.000+00:00';
  const servidorTs = '2026-10-28T17:01:00+00:00';
  const comercios = 2;
  const productos = 428;
  const enSemilla = 424; // 4 del servidor no están en el pack (alta manual)
  const precios = 7;

  setUp(() async {
    db = BaseDeDatos.memoria();
    cliente = ClienteRemotoFalso();
    await crearUsuarioConEtiqueta(db, 'Equipo nuevo');
  });

  tearDown(() async {
    await db.close();
  });

  String ean(int n) => '7791234567${n.toString().padLeft(3, '0')}';

  Map<String, dynamic> packSemilla() => {
        'formato': 'seguidor-precios-pack-semilla',
        'productos': [
          for (var n = 0; n < enSemilla; n++)
            {
              'codigo_barras': ean(n),
              'nombre': 'Producto semilla $n',
              'unidad': 'g',
              'contenido_neto': 500,
              'marca': 'Marca $n',
            }
        ],
      };

  Map<String, dynamic> productoServidor(int n) => {
        // uuid5 como los ids de la carga de semilla al servidor.
        'id': 'ba1${n.toString().padLeft(8, '0')}-0000-5abc-ade0-00000000000$n',
        'codigo_barras': ean(n),
        'articulo_id': null,
        'nombre': 'Producto servidor $n',
        'marca': 'Marca $n',
        'categoria': null,
        'unidad': 'g',
        'contenido_neto': 500.0,
        'origen': null,
        'notas': null,
        'creado_por': 'c823199d-0000-5a32-91cf-70616561f143',
        'creado_en': servidorTs,
        'actualizado_en': servidorTs,
        'borrado_en': null,
      };

  test(
      'primera sync de instalación nueva baja el catálogo completo sin romper FK',
      () async {
    // Instalación nueva: semilla importada hoy (sin outbox de productos).
    final semilla = await importarPackSemilla(
      db,
      pack: packSemilla(),
      usuarioId: 'local-1',
      ahora: DateTime.parse(semillaTs),
    );
    expect(semilla.importados, enSemilla);

    // Servidor: catálogo ya cargado (uuid5) + 2 manuales + comercios + precios.
    cliente.sembrar('producto', [
      for (var n = 0; n < productos - 4; n++) productoServidor(n),
      // 4 productos de alta manual: EAN que NO está en la semilla.
      for (var n = enSemilla; n < productos; n++)
        (productoServidor(n)
          ..['id'] = 'manual-${n.toString().padLeft(4, '0')}'
          ..['codigo_barras'] = ean(n)),
    ]);
    cliente.sembrar('usuario', [
      {
        'id': 'c823199d-0000-5a32-91cf-70616561f143',
        'etiqueta': 'semilla',
        'auth_uid': 'uid-servicio',
        'creado_en': servidorTs,
        'actualizado_en': servidorTs,
      },
      {
        'id': 'fa1d6877-0000-4c7c-b181-e38159c3e16f',
        'etiqueta': 'Dueño',
        'auth_uid': 'auth-dueno',
        'creado_en': servidorTs,
        'actualizado_en': servidorTs,
      },
    ]);
    cliente.sembrar('comercio', [
      for (var c = 0; c < comercios; c++)
        {
          'id': 'com-$c',
          'nombre': 'Comercio $c',
          'tipo': null,
          'direccion': null,
          'creado_por': 'fa1d6877-0000-4c7c-b181-e38159c3e16f',
          'creado_en': servidorTs,
          'actualizado_en': servidorTs,
          'borrado_en': null,
        },
    ]);
    cliente.sembrar('precio', [
      for (var p = 0; p < precios; p++)
        {
          'id': 'pre-$p',
          // El precio 6 es el par duplicado del 0 (como en el dump real),
          // siempre sobre un producto uuid5 de semilla.
          'producto_id':
              'ba1${(p % 2).toString().padLeft(8, '0')}-0000-5abc-ade0-00000000000${p % 2}',
          'comercio_id': 'com-${p % comercios}',
          'precio': 899.99,
          'fecha_toma': '2026-10-27',
          'cargado_por': 'fa1d6877-0000-4c7c-b181-e38159c3e16f',
          'cargado_en': '2026-10-28T19:36:24.051723+00:00',
        },
    ]);

    final resumen = await sincronizarAhora(db, cliente);

    // +3 usuarios: los 2 del servidor MÁS el eco propio del dispositivo
    // (la identidad se sube al inicio de la sesión y vuelve en el pull;
    // re-aplicarla es un no-op idempotente y cuenta como descargada).
    expect(resumen.filasDescargadas, productos + comercios + precios + 3);
    final preciosLocales = await db.select(db.precios).get();
    expect(preciosLocales.length, precios);
    final productosLocales = {for (final p in await db.select(db.productos).get()) p.id: p};
    // Todo precio apunta a un producto y comercio presentes.
    for (final precio in preciosLocales) {
      expect(productosLocales[precio.productoId], isNotNull,
          reason: 'precio ${precio.id} sin producto ${precio.productoId}');
    }
  });
}
