import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:seguidor_precios/data/identidad.dart';
import 'package:seguidor_precios/data/local/base_de_datos.dart';
import 'package:seguidor_precios/data/sync/cola_saliente.dart';
import 'package:seguidor_precios/data/sync/servicio_sync.dart';

import 'cliente_remoto_falso.dart';

/// Tests del núcleo de sync (T2): push por lotes en orden de dependencias,
/// pull incremental con LWW y borrado lógico, dedup por EAN con re-apunte
/// local de precios. Todo contra un cliente falso: sin red.
void main() {
  late BaseDeDatos db;
  late ClienteRemotoFalso cliente;
  late String usuarioId;

  const t1 = '2026-01-01T10:00:00.000Z';
  const t2 = '2026-01-02T10:00:00.000Z';
  const t3 = '2026-01-03T10:00:00.000Z';
  const t4 = '2026-01-04T10:00:00.000Z';
  const t5 = '2026-01-05T10:00:00.000Z';
  const t9 = '2026-01-09T10:00:00.000Z';

  setUp(() async {
    db = BaseDeDatos.memoria();
    cliente = ClienteRemotoFalso();
    usuarioId = (await crearUsuarioConEtiqueta(db, 'Nadia')).id;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertarProducto(
    String id, {
    String? codigoBarras,
    String? articuloId,
    String nombre = 'Producto',
    String actualizadoEn = t1,
  }) {
    return db.into(db.productos).insert(
          ProductosCompanion.insert(
            id: id,
            codigoBarras: Value(codigoBarras),
            articuloId: Value(articuloId),
            nombre: nombre,
            unidad: 'g',
            creadoPor: usuarioId,
            creadoEn: actualizadoEn,
            actualizadoEn: actualizadoEn,
          ),
        );
  }

  Future<void> insertarComercio(String id, {String actualizadoEn = t1}) {
    return db.into(db.comercios).insert(
          ComerciosCompanion.insert(
            id: id,
            nombre: 'Comercio $id',
            creadoPor: usuarioId,
            creadoEn: actualizadoEn,
            actualizadoEn: actualizadoEn,
          ),
        );
  }

  Future<void> insertarPrecio(
    String id, {
    required String productoId,
    String comercioId = 'c1',
    double valor = 1500,
    String fecha = '2026-01-02',
    String cargadoEn = t1,
  }) async {
    final comercio = await (db.select(db.comercios)
          ..where((c) => c.id.equals(comercioId)))
        .getSingleOrNull();
    if (comercio == null) await insertarComercio(comercioId);
    await db.into(db.precios).insert(
          PreciosCompanion.insert(
            id: id,
            productoId: productoId,
            comercioId: comercioId,
            precio: valor,
            fechaToma: fecha,
            cargadoPor: usuarioId,
            cargadoEn: cargadoEn,
          ),
        );
  }

  group('push — por lotes en orden de dependencias (regla de sync 2)', () {
    test(
        'sube las seis tablas en orden usuario→articulo→producto→comercio→precio→valoracion y vacía la cola',
        () async {
      await db.into(db.articulos).insert(
            ArticulosCompanion.insert(
              id: 'a1',
              nombre: 'Mayonesas',
              unidadBase: 'kg',
              creadoPor: usuarioId,
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      await insertarProducto('p1', codigoBarras: '7791234567890', articuloId: 'a1');
      await insertarComercio('c1');
      await insertarPrecio('pr1', productoId: 'p1');
      await db.into(db.valoraciones).insert(
            ValoracionesCompanion.insert(
              id: 'v1',
              usuarioId: usuarioId,
              productoId: 'p1',
              gusto: const Value('si'),
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      for (final par in [
        ('usuario', usuarioId),
        ('articulo', 'a1'),
        ('producto', 'p1'),
        ('comercio', 'c1'),
        ('precio', 'pr1'),
        ('valoracion', 'v1'),
      ]) {
        await encolarUpsert(db, par.$1, par.$2);
      }

      final resultado = await sincronizarAhora(db, cliente);

      expect(cliente.ordenSubidas, const [
        'usuario',
        'articulo',
        'producto',
        'comercio',
        'precio',
        'valoracion',
      ]);
      expect(cliente.remoto['usuario']!.single['id'], usuarioId);
      expect(cliente.remoto['producto']!.single['id'], 'p1');
      expect(cliente.remoto['precio']!.single['id'], 'pr1');
      expect(cliente.remoto['valoracion']!.single['id'], 'v1');
      expect(await cambiosPendientes(db), 0);
      expect(resultado.filasSubidas, 6);
      expect(await ultimoSyncExitoso(db), isNotNull);
    });

    test('respeta el tamaño de lote', () async {
      for (var i = 1; i <= 5; i++) {
        await insertarProducto('p$i');
        await encolarUpsert(db, 'producto', 'p$i');
      }

      await sincronizarAhora(db, cliente, tamanoLote: 2);

      // El usuario encolado por la sesión anónima se sube primero; los
      // productos ocupan tres lotes de 2, 2 y 1.
      expect(cliente.ordenSubidas.where((t) => t == 'producto'),
          ['producto', 'producto', 'producto']);
      expect(cliente.lotesSubidos.where((l) => l.first['id'] != null && (l.first['id'] as String).startsWith('p')).map((l) => l.length),
          [2, 2, 1]);
    });

    test('el payload usa los nombres de columna del esquema remoto',
        () async {
      await db.into(db.articulos).insert(
            ArticulosCompanion.insert(
              id: 'a1',
              nombre: 'Mayonesas',
              unidadBase: 'kg',
              creadoPor: usuarioId,
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      await insertarProducto('p1', codigoBarras: '7791234567890', articuloId: 'a1');
      await insertarPrecio('pr1', productoId: 'p1');
      await encolarUpsert(db, 'producto', 'p1');
      await encolarUpsert(db, 'precio', 'pr1');

      await sincronizarAhora(db, cliente);

      final producto = cliente.remoto['producto']!.single;
      expect(
        producto.keys,
        containsAll(const [
          'id',
          'codigo_barras',
          'articulo_id',
          'nombre',
          'marca',
          'categoria',
          'unidad',
          'contenido_neto',
          'notas',
          'creado_por',
          'creado_en',
          'actualizado_en',
          'borrado_en',
        ]),
      );
      expect(producto['origen'], isNull); // campo solo local, no viaja
      final precio = cliente.remoto['precio']!.single;
      expect(
        precio.keys,
        containsAll(const [
          'id',
          'producto_id',
          'comercio_id',
          'precio',
          'fecha_toma',
          'cargado_por',
          'cargado_en',
        ]),
      );
    });

    test('la baja de valoración se propaga al servidor (borrado físico)',
        () async {
      await insertarProducto('p1');
      await db.into(db.valoraciones).insert(
            ValoracionesCompanion.insert(
              id: 'v1',
              usuarioId: usuarioId,
              productoId: 'p1',
              gusto: const Value('si'),
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      cliente.sembrar('valoracion', [
        {
          'id': 'v1',
          'usuario_id': usuarioId,
          'producto_id': 'p1',
          'gusto': 'si',
          'observacion': null,
          'creado_en': t1,
          'actualizado_en': t1,
        },
      ]);
      await encolarBaja(db, 'valoracion', 'v1');

      await sincronizarAhora(db, cliente);

      expect(cliente.bajasPedidas, ['valoracion:v1']);
      expect(
        cliente.remoto['valoracion']!.where((f) => f['id'] == 'v1'),
        isEmpty,
      );
      expect(await cambiosPendientes(db), 0);
    });
  });

  group('pull — incremental, LWW y borrado lógico (reglas de sync 3, 4, 5)',
      () {
    test(
        'primera descarga inserta en orden de dependencias y guarda el cursor por tabla',
        () async {
      cliente.sembrar('usuario', [
        {
          'id': 'u2',
          'etiqueta': 'Otros',
          'auth_uid': 'uid-otro',
          'creado_en': t1,
          'actualizado_en': t1,
        },
      ]);
      cliente.sembrar('articulo', [
        {
          'id': 'a2',
          'nombre': 'Harinas',
          'categoria': null,
          'unidad_base': 'kg',
          'creado_por': 'u2',
          'creado_en': t2,
          'actualizado_en': t2,
          'borrado_en': null,
        },
      ]);
      cliente.sembrar('producto', [
        {
          'id': 'p2',
          'codigo_barras': '7790000000001',
          'articulo_id': 'a2',
          'nombre': 'Harina 000',
          'marca': 'Marca B',
          'categoria': null,
          'unidad': 'kg',
          'contenido_neto': 1,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t3,
          'actualizado_en': t3,
          'borrado_en': null,
        },
      ]);
      cliente.sembrar('comercio', [
        {
          'id': 'c2',
          'nombre': 'Verdulería',
          'tipo': 'verduleria',
          'direccion': null,
          'creado_por': 'u2',
          'creado_en': t3,
          'actualizado_en': t3,
          'borrado_en': null,
        },
      ]);
      cliente.sembrar('precio', [
        {
          'id': 'pr2',
          'producto_id': 'p2',
          'comercio_id': 'c2',
          'precio': 900,
          'fecha_toma': '2026-01-04',
          'cargado_por': 'u2',
          'cargado_en': t4,
        },
      ]);
      cliente.sembrar('valoracion', [
        {
          'id': 'v2',
          'usuario_id': 'u2',
          'producto_id': 'p2',
          'gusto': 'no',
          'observacion': 'se cortó',
          'creado_en': t5,
          'actualizado_en': t5,
        },
      ]);

      final resultado = await sincronizarAhora(db, cliente);

      // Orden de dependencias también en el pull.
      expect(cliente.descargasPedidas.first, startsWith('usuario:actualizado_en:1970'));
      final orden = cliente.descargasPedidas.map((d) => d.split(':').first).toList();
      expect(orden.indexOf('articulo'), lessThan(orden.indexOf('producto')));
      expect(orden.indexOf('producto'), lessThan(orden.indexOf('precio')));

      expect(await db.select(db.usuarios).get(), hasLength(2)); // local + u2
      expect((await leerFilaProductoLocal(db, 'p2'))!.nombre, 'Harina 000');
      expect((await leerFilaProductoLocal(db, 'p2'))!.contenidoNeto, 1.0);
      final precio = await (db.select(db.precios)..where((p) => p.id.equals('pr2'))).getSingle();
      expect(precio.precio, 900);

      // Cursor por tabla: precio usa su cargado_en (regla de sync 3).
      // El usuario local (subido con su auth_uid) también avanza su cursor;
      // las demás tablas no tienen filas propias en el servidor.
      expect(await leerCursor(db, 'usuario'), isNotNull);
      expect(await leerCursor(db, 'articulo'), t2);
      expect(await leerCursor(db, 'producto'), t3);
      expect(await leerCursor(db, 'precio'), t4);
      expect(await leerCursor(db, 'valoracion'), t5);
      // El usuario local (con auth_uid) es la única subida: la sesión anónima
      // lo encola (regla de sync 9).
      expect(resultado.filasSubidas, 1);
      // 6 filas sembradas + nuestro propio usuario eco del push (7).
      expect(resultado.filasDescargadas, 7);
    });

    test('la segunda descarga es incremental desde el cursor guardado',
        () async {
      cliente.sembrar('producto', [
        {
          'id': 'p2',
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Harina 000',
          'marca': null,
          'categoria': null,
          'unidad': 'kg',
          'contenido_neto': 1,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t3,
          'actualizado_en': t3,
          'borrado_en': null,
        },
      ]);
      await sincronizarAhora(db, cliente);

      cliente.sembrar('producto', [
        {
          'id': 'p3',
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Fideos',
          'marca': null,
          'categoria': null,
          'unidad': 'unidad',
          'contenido_neto': null,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t9,
          'actualizado_en': t9,
          'borrado_en': null,
        },
      ]);
      await sincronizarAhora(db, cliente);

      final pedidoProducto = cliente.descargasPedidas.lastWhere(
        (d) => d.startsWith('producto:'),
      );
      expect(pedidoProducto, 'producto:actualizado_en:$t3');
      expect((await leerFilaProductoLocal(db, 'p3'))!.nombre, 'Fideos');
      expect(await leerCursor(db, 'producto'), t9);
    });

    test('LWW: una fila del servidor más nueva pisa la local', () async {
      await insertarProducto('p1', nombre: 'Viejo', actualizadoEn: t1);
      cliente.sembrar('producto', [
        {
          'id': 'p1',
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Corregido por otro',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': 500,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t2,
          'borrado_en': null,
        },
      ]);

      await sincronizarAhora(db, cliente);

      expect((await leerFilaProductoLocal(db, 'p1'))!.nombre,
          'Corregido por otro');
      expect((await leerFilaProductoLocal(db, 'p1'))!.actualizadoEn, t2);
    });

    test('LWW: lo local más nuevo se conserva y queda encolado para el push',
        () async {
      await insertarProducto('p1', nombre: 'Edité yo', actualizadoEn: t5);
      cliente.sembrar('producto', [
        {
          'id': 'p1',
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Versión vieja',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': null,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t2,
          'borrado_en': null,
        },
      ]);

      await sincronizarAhora(db, cliente);

      expect((await leerFilaProductoLocal(db, 'p1'))!.nombre, 'Edité yo');
      final entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('producto') & e.filaId.equals('p1')))
          .get();
      expect(entradas, hasLength(1));
      expect(entradas.single.operacion, operacionAlta);
    });

    test('el borrado lógico del servidor se aplica sin borrar la fila local',
        () async {
      await insertarProducto('p2', actualizadoEn: t1);
      cliente.sembrar('producto', [
        {
          'id': 'p2',
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Producto',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': null,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t2,
          'borrado_en': t2,
        },
      ]);

      await sincronizarAhora(db, cliente);

      expect(await leerFilaProductoLocal(db, 'p2'), isNotNull);
      expect((await leerFilaProductoLocal(db, 'p2'))!.borradoEn, t2);
    });

    test('precio es append-only: el pull no pisa un precio existente',
        () async {
      await insertarComercio('c1');
      await insertarProducto('p1');
      await insertarPrecio('pr1', productoId: 'p1', valor: 1500, cargadoEn: t1);
      cliente.sembrar('precio', [
        {
          'id': 'pr1',
          'producto_id': 'p1',
          'comercio_id': 'c1',
          'precio': 999,
          'fecha_toma': '2026-01-02',
          'cargado_por': 'u2',
          'cargado_en': t1,
        },
      ]);

      await sincronizarAhora(db, cliente);

      final precio = await (db.select(db.precios)..where((p) => p.id.equals('pr1'))).getSingle();
      expect(precio.precio, 1500);
    });

    test(
        'si el pull falla en una tabla, no se marca la sync exitosa ni se avanza el cursor de esa tabla',
        () async {
      cliente.sembrar('articulo', [
        {
          'id': 'a2',
          'nombre': 'Harinas',
          'categoria': null,
          'unidad_base': 'kg',
          'creado_por': 'u2',
          'creado_en': t2,
          'actualizado_en': t2,
          'borrado_en': null,
        },
      ]);
      cliente.errorAlDescargar = 'precio';

      await expectLater(
        sincronizarAhora(db, cliente),
        throwsA(anything),
      );

      expect(await ultimoSyncExitoso(db), isNull);
      expect(await leerCursor(db, 'articulo'), t2); // esa tabla sí terminó
      expect(await leerCursor(db, 'precio'), isNull);
    });
  });

  group('críticos del juicio fase-2 (C1 paginación, C2 colisión de EAN)', () {
    test(
        'C1: pull con ≥100 filas de igual actualizado_en baja todo el catálogo y el cursor solo avanza sobre datos guardados',
        () async {
      // Un cargador masivo sube en lotes de 100 y el trigger del servidor
      // estampa el mismo now() a todo el lote: quedan bloques de 100+ filas
      // con actualizado_en idéntico (caso real del juicio: 424 productos,
      // un dispositivo nuevo solo bajaba los primeros 100).
      const tLote = '2026-01-05T10:00:00.000Z';
      final cargador = List.generate(250, (i) {
        final id = 'p-${i.toString().padLeft(3, '0')}';
        return {
          'id': id,
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Producto $id',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': null,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': tLote,
          'actualizado_en': tLote,
          'borrado_en': null,
        };
      });
      cliente.sembrar('producto', cargador);
      cliente.sembrar('producto', [
        {
          'id': 'p-posterior',
          'codigo_barras': null,
          'articulo_id': null,
          'nombre': 'Subido después',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': null,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t9,
          'actualizado_en': t9,
          'borrado_en': null,
        },
      ]);

      final resultado = await sincronizarAhora(db, cliente, tamanoLote: 100);

      // Todo el catálogo aterrizó, no solo la primera página.
      expect(await db.select(db.productos).get(), hasLength(251));
      // 251 del servidor + el eco del usuario propio que subió el push.
      expect(resultado.filasDescargadas, 252);
      // El cursor quedó en el último dato efectivamente guardado, no
      // atascado en el bloque de timestamps iguales.
      expect(await leerCursor(db, 'producto'), t9);
      // Tres páginas de producto (100 + 100 + 51): la ventana de descarga
      // avanzó en lugar de re-descargar siempre la misma página.
      expect(
        cliente.descargasPedidas.where((d) => d.startsWith('producto')),
        hasLength(3),
      );
    });

    test(
        'C2: el pull de un EAN semilla converge al id del servidor sin violar el UNIQUE, guarda el cursor y conserva precios y valoraciones',
        () async {
      // Semilla local (importar_semilla usa id sem-<ean>) con precio y
      // valoración apuntados; el servidor tiene el mismo EAN bajo uuid5.
      await insertarProducto('sem-7791234567890',
          codigoBarras: '7791234567890', nombre: 'Semilla', actualizadoEn: t1);
      await insertarPrecio('pr1',
          productoId: 'sem-7791234567890', valor: 1500, cargadoEn: t1);
      await db.into(db.valoraciones).insert(
            ValoracionesCompanion.insert(
              id: 'v1',
              usuarioId: usuarioId,
              productoId: 'sem-7791234567890',
              gusto: const Value('si'),
              creadoEn: t1,
              actualizadoEn: t1,
            ),
          );
      cliente.sembrar('producto', [
        {
          'id': 'p-servidor-uuid5',
          'codigo_barras': '7791234567890',
          'articulo_id': null,
          'nombre': 'Del servidor',
          'marca': 'Marca S',
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': 500,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t2,
          'borrado_en': null,
        },
      ]);

      // Hoy esto crashea con la violación de UNIQUE antes de guardarCursor:
      // el teléfono del dueño sube pero nunca baja.
      await sincronizarAhora(db, cliente);

      // Converge: la identidad local pasa a ser la del servidor.
      expect(await leerFilaProductoLocal(db, 'sem-7791234567890'), isNull);
      final convergida = await leerFilaProductoLocal(db, 'p-servidor-uuid5');
      expect(convergida, isNotNull);
      expect(convergida!.codigoBarras, '7791234567890');
      expect(convergida.nombre, 'Del servidor'); // el servidor es más nuevo
      expect(convergida.actualizadoEn, t2);
      // Precios y valoraciones siguen vinculados e intactos.
      final precio =
          await (db.select(db.precios)..where((p) => p.id.equals('pr1'))).getSingle();
      expect(precio.productoId, 'p-servidor-uuid5');
      expect(precio.precio, 1500);
      final valoracion = await (db.select(db.valoraciones)
            ..where((v) => v.id.equals('v1')))
          .getSingle();
      expect(valoracion.productoId, 'p-servidor-uuid5');
      // El pull terminó: cursor guardado y sync marcada exitosa (R15).
      expect(await leerCursor(db, 'producto'), t2);
      expect(await ultimoSyncExitoso(db), isNotNull);
    });

    test(
        'C2: si la semilla local es más nueva, su contenido gana bajo el id del servidor y vuelve a subir',
        () async {
      await insertarProducto('sem-7791234567890',
          codigoBarras: '7791234567890', nombre: 'Edité yo', actualizadoEn: t5);
      cliente.sembrar('producto', [
        {
          'id': 'p-servidor-uuid5',
          'codigo_barras': '7791234567890',
          'articulo_id': null,
          'nombre': 'Versión vieja del servidor',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': null,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t2,
          'borrado_en': null,
        },
      ]);

      await sincronizarAhora(db, cliente);

      expect(await leerFilaProductoLocal(db, 'sem-7791234567890'), isNull);
      final convergida = await leerFilaProductoLocal(db, 'p-servidor-uuid5');
      expect(convergida!.nombre, 'Edité yo');
      expect(convergida.codigoBarras, '7791234567890');
      // El contenido local ganó: queda encolado bajo el id canónico para
      // que el servidor también converja (regla 4).
      final entradas = await (db.select(db.outbox)
            ..where((e) => e.tabla.equals('producto')))
          .get();
      expect(entradas.map((e) => e.filaId), ['p-servidor-uuid5']);
      expect(await leerCursor(db, 'producto'), t2);
    });
  });

  group('dedup por EAN — re-apunte local de precios (regla de sync 6)', () {
    test(
        'el push de un duplicado re-apunta precios y valoraciones al id canónico',
        () async {
      await insertarProducto('pLocal',
          codigoBarras: '7791234567890', nombre: 'Cargué yo', actualizadoEn: t2);
      await insertarPrecio('pr1',
          productoId: 'pLocal', valor: 1500, fecha: '2026-01-02', cargadoEn: t2);
      await db.into(db.valoraciones).insert(
            ValoracionesCompanion.insert(
              id: 'v1',
              usuarioId: usuarioId,
              productoId: 'pLocal',
              gusto: const Value('si'),
              creadoEn: t2,
              actualizadoEn: t2,
            ),
          );
      // Otro usuario ya subió el mismo EAN con otro id.
      cliente.sembrar('producto', [
        {
          'id': 'pCanonico',
          'codigo_barras': '7791234567890',
          'articulo_id': null,
          'nombre': 'Canónico',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': 500,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t1,
          'borrado_en': null,
        },
      ]);
      await encolarUpsert(db, 'producto', 'pLocal');
      await encolarUpsert(db, 'precio', 'pr1');

      final resultado = await sincronizarAhora(db, cliente);

      // El duplicado local desaparece; el canónico conserva SUS datos
      // (regla 6 literal: el backend devuelve el id existente y el
      // dispositivo re-apunta; sin merge de campos entre filas).
      expect(await leerFilaProductoLocal(db, 'pLocal'), isNull);
      final canonico = await leerFilaProductoLocal(db, 'pCanonico');
      expect(canonico, isNotNull);
      expect(canonico!.nombre, 'Canónico');
      expect(canonico.actualizadoEn, t1);

      // Precios y valoraciones apuntan al canónico; los datos del precio no
      // cambian (inmutabilidad, regla de integridad 1).
      final precio = await (db.select(db.precios)..where((p) => p.id.equals('pr1'))).getSingle();
      expect(precio.productoId, 'pCanonico');
      expect(precio.precio, 1500);
      expect(precio.comercioId, 'c1');
      expect(precio.fechaToma, '2026-01-02');
      final valoracion = await (db.select(db.valoraciones)..where((v) => v.id.equals('v1'))).getSingle();
      expect(valoracion.productoId, 'pCanonico');
      expect(resultado.reApuntados, 2);

      // La entrada de producto ya no está pendiente bajo el id viejo.
      final pendientes = await (db.select(db.outbox)..where((e) => e.tabla.equals('producto'))).get();
      expect(pendientes, isEmpty);

      // El precio pendiente se subió ya re-apuntado al id canónico.
      final precioSubido = cliente.remoto['precio']!.single;
      expect(precioSubido['producto_id'], 'pCanonico');
    });

    test('un EAN nuevo para el servidor se sube con su id intacto', () async {
      await insertarProducto('p1', codigoBarras: '7799999999999');
      await encolarUpsert(db, 'producto', 'p1');

      final resultado = await sincronizarAhora(db, cliente);

      expect(cliente.remoto['producto']!.single['id'], 'p1');
      expect(await leerFilaProductoLocal(db, 'p1'), isNotNull);
      expect(resultado.reApuntados, 0);
    });

    test(
        'el push consulta dedup_ean y nunca sube el duplicado (contrato T1)',
        () async {
      await insertarProducto('pDup',
          codigoBarras: '7791234567890', nombre: 'Cargué yo', actualizadoEn: t2);
      await insertarPrecio('pr2',
          productoId: 'pDup', valor: 900, fecha: '2026-01-03', cargadoEn: t2);
      // El servidor ya tiene el canónico con ese EAN (otro usuario, antes).
      cliente.sembrar('producto', [
        {
          'id': 'pCanonico',
          'codigo_barras': '7791234567890',
          'articulo_id': null,
          'nombre': 'Canónico',
          'marca': null,
          'categoria': null,
          'unidad': 'g',
          'contenido_neto': 500,
          'notas': null,
          'creado_por': 'u2',
          'creado_en': t1,
          'actualizado_en': t1,
          'borrado_en': null,
        },
      ]);
      await encolarUpsert(db, 'producto', 'pDup');
      await encolarUpsert(db, 'precio', 'pr2');

      final resultado = await sincronizarAhora(db, cliente);

      // El push consultó el RPC de dedup para ese EAN.
      expect(cliente.idsDedupConsultados, ['7791234567890']);
      // El duplicado jamás llegó al servidor: no hay lote que lo contenga.
      final duplicadoSubido = cliente.lotesSubidos
          .expand((lote) => lote)
          .any((f) => f['id'] == 'pDup');
      expect(duplicadoSubido, isFalse);

      // Local: re-apunte completo a la fila canónica del servidor (regla 6
      // literal: el backend devuelve el id existente; sin merge de datos).
      expect(await leerFilaProductoLocal(db, 'pDup'), isNull);
      final canonico = await leerFilaProductoLocal(db, 'pCanonico');
      expect(canonico, isNotNull);
      expect(canonico!.nombre, 'Canónico');
      final precio = await (db.select(db.precios)..where((p) => p.id.equals('pr2'))).getSingle();
      expect(precio.productoId, 'pCanonico');
      expect(resultado.reApuntados, 1);
      final pendientes = await (db.select(db.outbox)..where((e) => e.tabla.equals('producto'))).get();
      expect(pendientes, isEmpty);
    });
  });
}

/// Fila local del producto con ese id, o null si no existe.
Future<Producto?> leerFilaProductoLocal(BaseDeDatos db, String id) =>
    (db.select(db.productos)..where((p) => p.id.equals(id))).getSingleOrNull();
