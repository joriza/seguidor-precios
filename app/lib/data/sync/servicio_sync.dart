import 'dart:math';

import 'package:drift/drift.dart';

import 'cliente_remoto.dart';
import 'cola_saliente.dart';
import '../identidad.dart';
import '../local/base_de_datos.dart';

/// Núcleo de sync offline-first (T2 de la fase): push por lotes en orden de
/// dependencias, pull incremental con merge última-escritura-gana, borrado
/// lógico, dedup por EAN con re-apunte local de precios e identidad
/// anónima. Sigue las reglas 1-9 de docs/arquitectura.md.
///
/// El servicio solo habla con [ClienteRemoto]: los tests corren contra un
/// cliente falso, sin red.

/// Resumen de una sesión de sync completa.
class ResultadoSync {
  const ResultadoSync({
    required this.filasSubidas,
    required this.bajasEnviadas,
    required this.filasDescargadas,
    required this.reApuntados,
  });

  final int filasSubidas;
  final int bajasEnviadas;
  final int filasDescargadas;
  final int reApuntados;

  @override
  String toString() =>
      'subidas=$filasSubidas bajas=$bajasEnviadas '
      'descargadas=$filasDescargadas reApuntados=$reApuntados';
}

/// Sesión completa de sync: identidad anónima → push → pull → marca global.
///
/// Lanza la primera excepción que encuentre; en ese caso no se marca la
/// sesión exitosa (R15) y los cursores quedan solo en las tablas cuyo pull
/// terminó (el próximo intento retoma desde ahí).
Future<ResultadoSync> sincronizarAhora(
  BaseDeDatos db,
  ClienteRemoto cliente, {
  int tamanoLote = 100,
}) async {
  await asegurarSesionAnonima(db, cliente);

  final (subidas, bajas, reApuntados) = await _pushTodo(db, cliente, tamanoLote);
  final descargadas = await _pullTodo(db, cliente, tamanoLote);

  await marcarSyncExitosa(db, DateTime.now().toUtc());
  return ResultadoSync(
    filasSubidas: subidas,
    bajasEnviadas: bajas,
    filasDescargadas: descargadas,
    reApuntados: reApuntados,
  );
}

/// Identidad anónima (AD-003, regla de sync 9): `signInAnonymously` una
/// sola vez por instalación y `auth_uid` persistido en el usuario local.
Future<String> asegurarSesionAnonima(
  BaseDeDatos db,
  ClienteRemoto cliente,
) async {
  final usuario = await usuarioActual(db);

  final uidSesion = await cliente.uidSesionActual();
  if (uidSesion != null) {
    if (usuario.authUid != uidSesion) {
      await _guardarAuthUid(db, usuario.id, uidSesion);
    }
    return uidSesion;
  }

  // Con identidad guardada nunca se inicia otra sesión anónima: crearía
  // un usuario nuevo y rompería la atribución de los aportes propios.
  final guardado = usuario.authUid;
  if (guardado != null) return guardado;

  final uid = await cliente.iniciarSesionAnonima();
  await _guardarAuthUid(db, usuario.id, uid);
  return uid;
}

Future<void> _guardarAuthUid(
  BaseDeDatos db,
  String usuarioId,
  String uid,
) async {
  await (db.update(db.usuarios)..where((t) => t.id.equals(usuarioId))).write(
    UsuariosCompanion(
      authUid: Value(uid),
      actualizadoEn: Value(DateTime.now().toUtc().toIso8601String()),
    ),
  );
  // El auth_uid viaja al servidor para resolver creado_por/cargado_por.
  await encolarUpsert(db, 'usuario', usuarioId);
}

// ---------------------------------------------------------------------------
// Push: outbox → lotes en orden de dependencias (reglas de sync 1, 2 y 6).
// ---------------------------------------------------------------------------

Future<(int, int, int)> _pushTodo(
  BaseDeDatos db,
  ClienteRemoto cliente,
  int tamanoLote,
) async {
  var subidas = 0;
  var bajas = 0;
  var reApuntados = 0;

  for (final tabla in tablasEnOrden) {
    final entradas = await (db.select(db.outbox)
          ..where((e) => e.tabla.equals(tabla))
          ..orderBy([(e) => OrderingTerm(expression: e.encoladoEn)]))
        .get();
    if (entradas.isEmpty) continue;

    final altas = <EntradaOutbox>[];
    for (final entrada in entradas) {
      if (entrada.operacion == operacionBaja) {
        await cliente.borrarFila(tabla: tabla, id: entrada.filaId);
        bajas++;
        await _descartarEntrada(db, tabla, entrada.filaId);
      } else {
        altas.add(entrada);
      }
    }

    for (var desde = 0; desde < altas.length; desde += tamanoLote) {
      final grupo =
          altas.sublist(desde, min(desde + tamanoLote, altas.length));
      final pares = <({EntradaOutbox entrada, Map<String, dynamic> fila})>[];
      for (final entrada in grupo) {
        final fila = await _leerFilaLocal(db, tabla, entrada.filaId);
        if (fila == null) {
          // La fila ya no existe localmente (p. ej., valoración vuelta a
          // neutro): se propaga como borrado para que no quede en el server.
          await cliente.borrarFila(tabla: tabla, id: entrada.filaId);
          bajas++;
          await _descartarEntrada(db, tabla, entrada.filaId);
          continue;
        }
        if (tabla == 'producto') {
          final codigo = fila['codigo_barras'] as String?;
          if (codigo != null && codigo.isNotEmpty) {
            final canonicoId = await cliente.idCanonicoPorEan(codigo);
            if (canonicoId != null && canonicoId != entrada.filaId) {
              final canonica =
                  await cliente.traerFila(tabla: tabla, id: canonicoId);
              if (canonica != null) {
                reApuntados += await _reApuntarProducto(
                  db,
                  desdeId: entrada.filaId,
                  filaCanonica: canonica,
                );
                await _descartarEntrada(db, tabla, entrada.filaId);
                continue;
              }
              // El canónico debería estar; si no lo está (carrera remota
              // rara), la entrada queda pendiente para el próximo intento
              // sin romper la sesión.
              continue;
            }
          }
        }
        pares.add((entrada: entrada, fila: fila));
      }
      if (pares.isEmpty) continue;

      await cliente.subirLote(
        tabla: tabla,
        filas: pares.map((p) => p.fila).toList(),
      );
      subidas += pares.length;
      for (final par in pares) {
        await _descartarEntrada(db, tabla, par.entrada.filaId);
      }
    }
  }

  return (subidas, bajas, reApuntados);
}

/// Re-apunte local tras dedup (regla de sync 6), en una transacción: la
/// fila canónica se copia al dispositivo (si no estaba), los precios y
/// valoraciones se re-apuntan al id canónico — solo el puntero, nunca el
/// dato del precio — y el duplicado local desaparece.
Future<int> _reApuntarProducto(
  BaseDeDatos db, {
  required String desdeId,
  required Map<String, dynamic> filaCanonica,
}) {
  final canonicoId = filaCanonica['id'] as String;
  return db.transaction(() async {
    // El duplicado libera su EAN primero: el índice único parcial es sobre
    // codigo_barras, y el canónico llega con el mismo código (todo dentro
    // de la misma transacción, regla de sync 6).
    await (db.update(db.productos)..where((t) => t.id.equals(desdeId)))
        .write(const ProductosCompanion(codigoBarras: Value(null)));

    final existente = await (db.select(db.productos)
          ..where((t) => t.id.equals(canonicoId)))
        .getSingleOrNull();
    if (existente == null) {
      await db.into(db.productos).insert(_companionProductoDesdeRemota(filaCanonica));
    } else if (_servidorGana(filaCanonica, existente.actualizadoEn)) {
      await (db.update(db.productos)..where((t) => t.id.equals(canonicoId)))
          .write(_companionProductoParaActualizar(filaCanonica));
    }

    var apuntados = 0;
    apuntados += await (db.update(db.precios)
          ..where((t) => t.productoId.equals(desdeId)))
        .write(PreciosCompanion(productoId: Value(canonicoId)));
    apuntados += await (db.update(db.valoraciones)
          ..where((t) => t.productoId.equals(desdeId)))
        .write(ValoracionesCompanion(productoId: Value(canonicoId)));

    await (db.delete(db.productos)..where((t) => t.id.equals(desdeId))).go();
    return apuntados;
  });
}

Future<void> _descartarEntrada(
  BaseDeDatos db,
  String tabla,
  String filaId,
) async {
  await (db.delete(db.outbox)
        ..where((e) => e.tabla.equals(tabla) & e.filaId.equals(filaId)))
      .go();
}

// ---------------------------------------------------------------------------
// Pull: incremental por tabla con merge LWW (reglas de sync 3, 4 y 5).
// ---------------------------------------------------------------------------

Future<int> _pullTodo(
  BaseDeDatos db,
  ClienteRemoto cliente,
  int tamanoLote,
) async {
  var descargadas = 0;

  for (final tabla in tablasEnOrden) {
    final columna = _columnaCursor(tabla);
    var cursor = await leerCursor(db, tabla) ?? cursorInicial;

    while (true) {
      final cursorAntes = cursor;
      final lote = await cliente.descargarCambios(
        tabla: tabla,
        columnaCursor: columna,
        desde: cursor,
        limite: tamanoLote,
      );
      if (lote.isEmpty) break;

      for (final fila in lote) {
        await _aplicarFilaRemota(db, tabla, fila);
        descargadas++;
        final ts = fila[columna] as String?;
        if (ts != null && momentoMasReciente(ts, cursor)) cursor = ts;
      }
      await guardarCursor(db, tabla, cursor);

      // `>= cursor` re-descarga empates de una sola vez; si el cursor no
      // avanzó con un lote lleno, seguiría repitiendo: se corta.
      if (lote.length < tamanoLote || cursor == cursorAntes) break;
    }
  }

  return descargadas;
}

/// `actualizado_en` para todas las tablas salvo precio (append-only): su
/// cursor de pull es `cargado_en`, normalizado por el servidor (regla 3).
String _columnaCursor(String tabla) =>
    tabla == 'precio' ? 'cargado_en' : 'actualizado_en';

/// Merge última-escritura-gana por fila (regla 4), con la marca de tiempo
/// del servidor como árbitro. El borrado es lógico (regla 5): `borrado_en`
/// se copia, la fila nunca se quita. Precio es append-only: si existe, no
/// se toca. Si la fila local es más nueva, se conserva y queda encolada.
Future<void> _aplicarFilaRemota(
  BaseDeDatos db,
  String tabla,
  Map<String, dynamic> fila,
) async {
  final id = fila['id'] as String;
  final remota = fila['actualizado_en'] as String?;

  switch (tabla) {
    case 'usuario':
      final local = await (db.select(db.usuarios)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local == null) {
        await db.into(db.usuarios).insert(_companionUsuarioDesdeRemota(fila));
      } else if (_servidorGana(fila, local.actualizadoEn)) {
        await (db.update(db.usuarios)..where((t) => t.id.equals(id)))
            .write(_companionUsuarioParaActualizar(fila));
      } else if (_localGana(remota, local.actualizadoEn)) {
        await encolarUpsert(db, tabla, id);
      }
    case 'articulo':
      final local = await (db.select(db.articulos)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local == null) {
        await db.into(db.articulos).insert(_companionArticuloDesdeRemota(fila));
      } else if (_servidorGana(fila, local.actualizadoEn)) {
        await (db.update(db.articulos)..where((t) => t.id.equals(id)))
            .write(_companionArticuloParaActualizar(fila));
      } else if (_localGana(remota, local.actualizadoEn)) {
        await encolarUpsert(db, tabla, id);
      }
    case 'producto':
      final local = await (db.select(db.productos)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local == null) {
        await db.into(db.productos).insert(_companionProductoDesdeRemota(fila));
      } else if (_servidorGana(fila, local.actualizadoEn)) {
        await (db.update(db.productos)..where((t) => t.id.equals(id)))
            .write(_companionProductoParaActualizar(fila));
      } else if (_localGana(remota, local.actualizadoEn)) {
        await encolarUpsert(db, tabla, id);
      }
    case 'comercio':
      final local = await (db.select(db.comercios)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local == null) {
        await db.into(db.comercios).insert(_companionComercioDesdeRemota(fila));
      } else if (_servidorGana(fila, local.actualizadoEn)) {
        await (db.update(db.comercios)..where((t) => t.id.equals(id)))
            .write(_companionComercioParaActualizar(fila));
      } else if (_localGana(remota, local.actualizadoEn)) {
        await encolarUpsert(db, tabla, id);
      }
    case 'precio':
      final local = await (db.select(db.precios)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local == null) {
        await db.into(db.precios).insert(_companionPrecioDesdeRemota(fila));
      }
      // Append-only: un precio existente nunca se modifica (regla 4).
    case 'valoracion':
      final local = await (db.select(db.valoraciones)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local == null) {
        await db.into(db.valoraciones).insert(_companionValoracionDesdeRemota(fila));
      } else if (_servidorGana(fila, local.actualizadoEn)) {
        await (db.update(db.valoraciones)..where((t) => t.id.equals(id)))
            .write(_companionValoracionParaActualizar(fila));
      } else if (_localGana(remota, local.actualizadoEn)) {
        await encolarUpsert(db, tabla, id);
      }
    default:
      throw ArgumentError.value(tabla, 'tabla', 'tabla fuera del orden de sync');
  }
}

bool _servidorGana(Map<String, dynamic> fila, String localTs) {
  final remota = fila['actualizado_en'] as String?;
  return remota != null && momentoMasReciente(remota, localTs);
}

bool _localGana(String? remota, String localTs) =>
    remota == null || momentoMasReciente(localTs, remota);

// ---------------------------------------------------------------------------
// Mapeo local → remoto (snake_case, docs/modelo-de-datos.md). El campo
// `origen` de producto es solo local: no viaja.
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>?> _leerFilaLocal(
  BaseDeDatos db,
  String tabla,
  String id,
) async {
  switch (tabla) {
    case 'usuario':
      final u = await (db.select(db.usuarios)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (u == null) return null;
      return {
        'id': u.id,
        'etiqueta': u.etiqueta,
        'auth_uid': u.authUid,
        'creado_en': u.creadoEn,
        'actualizado_en': u.actualizadoEn,
      };
    case 'articulo':
      final a = await (db.select(db.articulos)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (a == null) return null;
      return {
        'id': a.id,
        'nombre': a.nombre,
        'categoria': a.categoria,
        'unidad_base': a.unidadBase,
        'creado_por': a.creadoPor,
        'creado_en': a.creadoEn,
        'actualizado_en': a.actualizadoEn,
        'borrado_en': a.borradoEn,
      };
    case 'producto':
      final p = await (db.select(db.productos)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (p == null) return null;
      return {
        'id': p.id,
        'codigo_barras': p.codigoBarras,
        'articulo_id': p.articuloId,
        'nombre': p.nombre,
        'marca': p.marca,
        'categoria': p.categoria,
        'unidad': p.unidad,
        'contenido_neto': p.contenidoNeto,
        'notas': p.notas,
        'creado_por': p.creadoPor,
        'creado_en': p.creadoEn,
        'actualizado_en': p.actualizadoEn,
        'borrado_en': p.borradoEn,
      };
    case 'comercio':
      final c = await (db.select(db.comercios)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (c == null) return null;
      return {
        'id': c.id,
        'nombre': c.nombre,
        'tipo': c.tipo,
        'direccion': c.direccion,
        'creado_por': c.creadoPor,
        'creado_en': c.creadoEn,
        'actualizado_en': c.actualizadoEn,
        'borrado_en': c.borradoEn,
      };
    case 'precio':
      final p = await (db.select(db.precios)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (p == null) return null;
      return {
        'id': p.id,
        'producto_id': p.productoId,
        'comercio_id': p.comercioId,
        'precio': p.precio,
        'fecha_toma': p.fechaToma,
        'cargado_por': p.cargadoPor,
        'cargado_en': p.cargadoEn,
      };
    case 'valoracion':
      final v = await (db.select(db.valoraciones)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (v == null) return null;
      return {
        'id': v.id,
        'usuario_id': v.usuarioId,
        'producto_id': v.productoId,
        'gusto': v.gusto,
        'observacion': v.observacion,
        'creado_en': v.creadoEn,
        'actualizado_en': v.actualizadoEn,
      };
  }
  throw ArgumentError.value(tabla, 'tabla', 'tabla fuera del orden de sync');
}

// ---------------------------------------------------------------------------
// Mapeo remoto → companions de drift (con tolerancia a filas incompletas).
// ---------------------------------------------------------------------------

UsuariosCompanion _companionUsuarioDesdeRemota(Map<String, dynamic> fila) =>
    UsuariosCompanion.insert(
      id: fila['id'] as String,
      etiqueta: fila['etiqueta'] as String? ?? '',
      authUid: Value(fila['auth_uid'] as String?),
      creadoEn: fila['creado_en'] as String? ?? cursorInicial,
      actualizadoEn: fila['actualizado_en'] as String? ?? cursorInicial,
    );

UsuariosCompanion _companionUsuarioParaActualizar(Map<String, dynamic> fila) =>
    UsuariosCompanion(
      etiqueta: Value(fila['etiqueta'] as String? ?? ''),
      authUid: Value(fila['auth_uid'] as String?),
      actualizadoEn: Value(fila['actualizado_en'] as String? ?? cursorInicial),
    );

ArticulosCompanion _companionArticuloDesdeRemota(Map<String, dynamic> fila) =>
    ArticulosCompanion.insert(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String? ?? '',
      categoria: Value(fila['categoria'] as String?),
      unidadBase: fila['unidad_base'] as String? ?? 'unidad',
      creadoPor: fila['creado_por'] as String? ?? '',
      creadoEn: fila['creado_en'] as String? ?? cursorInicial,
      actualizadoEn: fila['actualizado_en'] as String? ?? cursorInicial,
      borradoEn: Value(fila['borrado_en'] as String?),
    );

ArticulosCompanion _companionArticuloParaActualizar(Map<String, dynamic> fila) =>
    ArticulosCompanion(
      nombre: Value(fila['nombre'] as String? ?? ''),
      categoria: Value(fila['categoria'] as String?),
      unidadBase: Value(fila['unidad_base'] as String? ?? 'unidad'),
      actualizadoEn: Value(fila['actualizado_en'] as String? ?? cursorInicial),
      borradoEn: Value(fila['borrado_en'] as String?),
    );

ProductosCompanion _companionProductoDesdeRemota(Map<String, dynamic> fila) =>
    ProductosCompanion.insert(
      id: fila['id'] as String,
      codigoBarras: Value(fila['codigo_barras'] as String?),
      articuloId: Value(fila['articulo_id'] as String?),
      nombre: fila['nombre'] as String? ?? '',
      marca: Value(fila['marca'] as String?),
      categoria: Value(fila['categoria'] as String?),
      unidad: fila['unidad'] as String? ?? 'unidad',
      contenidoNeto: Value((fila['contenido_neto'] as num?)?.toDouble()),
      notas: Value(fila['notas'] as String?),
      creadoPor: fila['creado_por'] as String? ?? '',
      creadoEn: fila['creado_en'] as String? ?? cursorInicial,
      actualizadoEn: fila['actualizado_en'] as String? ?? cursorInicial,
      borradoEn: Value(fila['borrado_en'] as String?),
    );

ProductosCompanion _companionProductoParaActualizar(Map<String, dynamic> fila) =>
    ProductosCompanion(
      codigoBarras: Value(fila['codigo_barras'] as String?),
      articuloId: Value(fila['articulo_id'] as String?),
      nombre: Value(fila['nombre'] as String? ?? ''),
      marca: Value(fila['marca'] as String?),
      categoria: Value(fila['categoria'] as String?),
      unidad: Value(fila['unidad'] as String? ?? 'unidad'),
      contenidoNeto: Value((fila['contenido_neto'] as num?)?.toDouble()),
      notas: Value(fila['notas'] as String?),
      actualizadoEn: Value(fila['actualizado_en'] as String? ?? cursorInicial),
      borradoEn: Value(fila['borrado_en'] as String?),
    );

ComerciosCompanion _companionComercioDesdeRemota(Map<String, dynamic> fila) =>
    ComerciosCompanion.insert(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String? ?? '',
      tipo: Value(fila['tipo'] as String?),
      direccion: Value(fila['direccion'] as String?),
      creadoPor: fila['creado_por'] as String? ?? '',
      creadoEn: fila['creado_en'] as String? ?? cursorInicial,
      actualizadoEn: fila['actualizado_en'] as String? ?? cursorInicial,
      borradoEn: Value(fila['borrado_en'] as String?),
    );

ComerciosCompanion _companionComercioParaActualizar(Map<String, dynamic> fila) =>
    ComerciosCompanion(
      nombre: Value(fila['nombre'] as String? ?? ''),
      tipo: Value(fila['tipo'] as String?),
      direccion: Value(fila['direccion'] as String?),
      actualizadoEn: Value(fila['actualizado_en'] as String? ?? cursorInicial),
      borradoEn: Value(fila['borrado_en'] as String?),
    );

PreciosCompanion _companionPrecioDesdeRemota(Map<String, dynamic> fila) =>
    PreciosCompanion.insert(
      id: fila['id'] as String,
      productoId: fila['producto_id'] as String,
      comercioId: fila['comercio_id'] as String,
      precio: (fila['precio'] as num).toDouble(),
      fechaToma: fila['fecha_toma'] as String,
      cargadoPor: fila['cargado_por'] as String? ?? '',
      cargadoEn: fila['cargado_en'] as String,
    );

ValoracionesCompanion _companionValoracionDesdeRemota(Map<String, dynamic> fila) =>
    ValoracionesCompanion.insert(
      id: fila['id'] as String,
      usuarioId: fila['usuario_id'] as String,
      productoId: fila['producto_id'] as String,
      gusto: Value(fila['gusto'] as String?),
      observacion: Value(fila['observacion'] as String?),
      creadoEn: fila['creado_en'] as String? ?? cursorInicial,
      actualizadoEn: fila['actualizado_en'] as String? ?? cursorInicial,
    );

ValoracionesCompanion _companionValoracionParaActualizar(
        Map<String, dynamic> fila) =>
    ValoracionesCompanion(
      gusto: Value(fila['gusto'] as String?),
      observacion: Value(fila['observacion'] as String?),
      actualizadoEn: Value(fila['actualizado_en'] as String? ?? cursorInicial),
    );
