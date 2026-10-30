import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/local/importar_semilla.dart';
import 'package:seguidor_precios/data/sync/cola_saliente.dart';
import 'package:seguidor_precios/data/sync/servicio_sync.dart';

import 'cliente_remoto_falso.dart';

/// Auto-reparación de padres en el pull (FK 787 de campo, v0.3.3): el pull
/// de precio corrió con el cursor de producto YA pasando la ventana de un
/// padre (el cargador del dueño aterrizó la fila entre el pull de producto
/// y el de precio; los reintentos con gte(cursor) la saltean para siempre)
/// y el insert del precio falló con FOREIGN KEY. El pull ahora trae por id
/// los padres ausentes (regla de sync 3: el dato efectivamente guardado es
/// el que manda) antes de insertar precio/valoración.
void main() {
  late BaseDeDatos db;
  late ClienteObservador cliente;

  const tsSemilla = '2026-10-30T19:11:34.850617+00:00';
  const tsServidor = '2026-10-28T17:01:00+00:00';
  const eanBa = '7792200000159';
  const productoBa = 'ba129b10-c9f7-53f7-bfeb-d4890af65c03';
  const comercioTino = '4e1614be-c175-47fe-99da-a670d9e9fa71';

  setUp(() async {
    db = BaseDeDatos.memoria();
    cliente = ClienteObservador();
    await crearUsuarioConEtiqueta(db, 'Equipo nuevo');
  });

  tearDown(() async {
    await db.close();
  });

  String ean(int n) => '7791234567${n.toString().padLeft(3, '0')}';

  Map<String, dynamic> productoServidor(String id, String codigo) => {
        'id': id,
        'codigo_barras': codigo,
        'articulo_id': null,
        'nombre': 'Producto servidor $id',
        'marca': null,
        'categoria': null,
        'unidad': 'g',
        'contenido_neto': 500.0,
        'origen': null,
        'notas': null,
        'creado_por': 'c823199d-2d1c-5a32-91cf-70616561f143',
        'creado_en': tsServidor,
        'actualizado_en': tsServidor,
        'borrado_en': null,
      };

  Map<String, dynamic> precioServidor(String id, String productoId) => {
        'id': id,
        'producto_id': productoId,
        'comercio_id': comercioTino,
        'precio': 899.99,
        'fecha_toma': '2026-10-27',
        'cargado_por': 'fa1d6877-8553-4c7c-b181-e38159c3e16f',
        'cargado_en': '2026-10-28T19:36:24.051723+00:00',
      };

  /// Estado de campo: el dispositivo ya sincronizó producto (cursor alto,
  /// ba129b10 aún no aterrizado en el servidor) y el precio apunta a él.
  Future<void> instalarEstadoDeCampo({bool conBa129b10 = false}) async {
    cliente.sembrar('producto', [
      productoServidor('p-1', ean(0)),
      productoServidor('p-2', ean(1)),
      if (conBa129b10) productoServidor(productoBa, eanBa),
    ]);
    cliente.sembrar('comercio', [
      {
        'id': comercioTino,
        'nombre': 'Tino Market',
        'tipo': 'almacen',
        'direccion': null,
        'creado_por': 'fa1d6877-8553-4c7c-b181-e38159c3e16f',
        'creado_en': tsServidor,
        'actualizado_en': tsServidor,
        'borrado_en': null,
      },
    ]);
    cliente.sembrar('precio', [
      precioServidor('pre-1', 'p-1'),
      precioServidor('pre-2', productoBa), // gemelo, sorts antes
      precioServidor('pre-3', productoBa), // el último del grupo
    ]);
    await importarPackSemilla(
      db,
      pack: {
        'formato': 'seguidor-precios-pack-semilla',
        'productos': [
          {'codigo_barras': ean(0), 'nombre': 'P0', 'unidad': 'g'},
          {'codigo_barras': ean(1), 'nombre': 'P1', 'unidad': 'g'},
          {'codigo_barras': eanBa, 'nombre': 'Nueve de oro', 'unidad': 'g'},
        ],
      },
      usuarioId: (await usuarioActual(db)).id,
      ahora: DateTime.parse(tsSemilla),
    );
    await encolarFilasExistentes(db);
  }

  test('el pull trae del servidor el padre ausente antes de insertar el precio',
      () async {
    await instalarEstadoDeCampo();
    // El cargador del dueño aterriza ba129b10 justo cuando el teléfono pide
    // el pull de precio (después de que su pull de producto terminó).
    cliente.alDescargar('precio', ejecutar: () {
      cliente.sembrar(
          'producto', [productoServidor(productoBa, eanBa)]);
    });

    await sincronizarAhora(db, cliente);

    final precios = await db.select(db.precios).get();
    expect(precios.length, 3,
        reason: 'los 3 precios quedan locales, sin abortar por FK');
    final productos = {
      for (final p in await db.select(db.productos).get()) p.id: p
    };
    expect(productos[productoBa], isNotNull,
        reason: 'ba129b10 quedó local: lo trajo la auto-reparación por id');
    for (final precio in precios) {
      expect(productos[precio.productoId], isNotNull);
    }
    // El padre traído por id pasa por la MISMA convergencia que el pull:
    // el EAN del duplicado semilla se liberó y el canónico quedó único.
    final conEan = productos.values.where((p) => p.codigoBarras == eanBa);
    expect(conEan.length, 1, reason: 'sin duplicados de EAN');
  });

  test('con los padres presentes el pull no consulta traerFila de más',
      () async {
    await instalarEstadoDeCampo(conBa129b10: true);
    await sincronizarAhora(db, cliente);
    // Sin padres ausentes, la reparación no consulta comercios por id
    // (las únicas llamadas de traerFila legítimas son las del dedup del
    // push, siempre de producto).
    expect(
        cliente.traerFilaPedidos.where((t) => t.startsWith('comercio:')),
        isEmpty);
    expect((await db.select(db.precios).get()).length, 3);
  });

  test('si el padre tampoco existe en el servidor, la sesión aborta sin '
      'guardar el cursor de precio', () async {
    await instalarEstadoDeCampo(); // ba129b10 nunca aterriza
    await expectLater(
      sincronizarAhora(db, cliente),
      throwsA(isA<Exception>()),
    );
    // El cursor de precio no quedó guardado: el próximo intento re-pide
    // el grupo completo (R15: el cursor queda solo en datos guardados).
    // Las filas aplicadas antes del fallo persisten (autocommit por fila:
    // el reintento las re-pide y las deja como no-op).
    expect(await leerCursor(db, 'precio'), isNull);
    expect((await db.select(db.precios).get()).length, 1,
        reason: 'sólo pre-1 (padres presentes) quedó aplicado');
  });

  test('la valoración también repara sus padres (usuario y producto)',
      () async {
    await instalarEstadoDeCampo(conBa129b10: true);
    cliente.sembrar('valoracion', [
      {
        'id': 'val-1',
        'usuario_id': 'fa1d6877-8553-4c7c-b181-e38159c3e16f',
        'producto_id': productoBa,
        'gusto': 'si',
        'observacion': null,
        'creado_en': tsServidor,
        'actualizado_en': tsServidor,
      },
    ]);
    // El usuario dueño nunca bajó por el pull (no está sembrado al inicio):
    // aterriza en el servidor justo cuando el teléfono pide valoraciones,
    // y la reparación lo trae por id.
    cliente.sembrar('usuario', const []);
    cliente.alDescargar('valoracion', ejecutar: () {
      cliente.sembrar('usuario', [
        {
          'id': 'fa1d6877-8553-4c7c-b181-e38159c3e16f',
          'etiqueta': 'joriza',
          'auth_uid': 'auth-dueno',
          'creado_en': tsServidor,
          'actualizado_en': tsServidor,
        },
      ]);
    });
    await sincronizarAhora(db, cliente);
    final valoraciones = await db.select(db.valoraciones).get();
    expect(valoraciones.length, 1);
    expect(
        cliente.traerFilaPedidos,
        contains('usuario:fa1d6877-8553-4c7c-b181-e38159c3e16f'),
        reason: 'el usuario ausente se pidió por id');
    final usuarios = {
      for (final u in await db.select(db.usuarios).get()) u.id: u
    };
    expect(usuarios['fa1d6877-8553-4c7c-b181-e38159c3e16f'], isNotNull);
    final productos = {
      for (final p in await db.select(db.productos).get()) p.id: p
    };
    expect(productos[productoBa], isNotNull,
        reason: 'el producto padre llegó por el pull normal');
  });
}

/// ClienteRemotoFalso que graba las llamadas de traerFila (traza de la
/// auto-reparación) y permite colgar escrituras de servidor a mitad de
/// sesión (la ventana del cargador concurrente).
class ClienteObservador extends ClienteRemotoFalso {
  final List<String> traerFilaPedidos = [];
  final Map<String, void Function()> _alDescargar = {};

  void alDescargar(String tabla, {required void Function() ejecutar}) {
    _alDescargar[tabla] = ejecutar;
  }

  @override
  Future<Map<String, dynamic>?> traerFila({
    required String tabla,
    required String id,
  }) async {
    traerFilaPedidos.add('$tabla:$id');
    return super.traerFila(tabla: tabla, id: id);
  }

  @override
  Future<List<Map<String, dynamic>>> descargarCambios({
    required String tabla,
    required String columnaCursor,
    required String desde,
    String? desdeId,
    required int limite,
  }) async {
    _alDescargar.remove(tabla)?.call();
    return super.descargarCambios(
      tabla: tabla,
      columnaCursor: columnaCursor,
      desde: desde,
      desdeId: desdeId,
      limite: limite,
    );
  }
}
