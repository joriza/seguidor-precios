import 'package:drift/drift.dart';

import '../local/base_de_datos.dart';

/// Estado local de sync (reglas de sync 2, 3 y 8): la cola outbox, el
/// cursor de pull por tabla y la marca global de última sesión exitosa
/// viven solo en el dispositivo — no se sincronizan ni viajan en backup.
///
/// Nombres de tabla: los del esquema remoto (snake_case), compartidos por
/// push, pull y la carga inicial — siempre en orden de dependencias.
const List<String> tablasEnOrden = [
  'usuario',
  'articulo',
  'producto',
  'comercio',
  'precio',
  'valoracion',
];

/// Operaciones de la cola: alta/cambio de fila o baja por id.
const String operacionAlta = 'upsert';
const String operacionBaja = 'delete';

/// Cursor inicial: epoch UTC, garantiza descargar todo el servidor.
const String cursorInicial = '1970-01-01T00:00:00.000Z';

void _validarTabla(String tabla) {
  if (!tablasEnOrden.contains(tabla)) {
    throw ArgumentError.value(
      tabla,
      'tabla',
      'tabla fuera del orden de sync: ${tablasEnOrden.join(', ')}',
    );
  }
}

/// Encola (o renueva) el alta/cambio de una fila local. Re-encolar la misma
/// clave (tabla, fila) reemplaza la entrada anterior: última intención gana.
Future<void> encolarUpsert(
  BaseDeDatos db,
  String tabla,
  String filaId, {
  DateTime? ahora,
}) async {
  _validarTabla(tabla);
  await db.into(db.outbox).insertOnConflictUpdate(
        OutboxCompanion.insert(
          tabla: tabla,
          filaId: filaId,
          operacion: operacionAlta,
          encoladoEn: (ahora ?? DateTime.now()).toUtc().toIso8601String(),
        ),
      );
}

/// Encola la baja de una fila (reemplaza un alta pendiente de la misma fila).
Future<void> encolarBaja(
  BaseDeDatos db,
  String tabla,
  String filaId, {
  DateTime? ahora,
}) async {
  _validarTabla(tabla);
  await db.into(db.outbox).insertOnConflictUpdate(
        OutboxCompanion.insert(
          tabla: tabla,
          filaId: filaId,
          operacion: operacionBaja,
          encoladoEn: (ahora ?? DateTime.now()).toUtc().toIso8601String(),
        ),
      );
}

/// Cantidad de cambios locales pendientes de subir (condición de R15).
Future<int> cambiosPendientes(BaseDeDatos db) async =>
    (await db.select(db.outbox).get()).length;

/// Cursor de pull guardado para una tabla, o null si nunca descargó.
Future<String?> leerCursor(BaseDeDatos db, String tabla) async {
  _validarTabla(tabla);
  final filas = await (db.select(db.cursoresSync)
        ..where((c) => c.tabla.equals(tabla)))
      .get();
  return filas.isEmpty ? null : filas.single.cursor;
}

/// Guarda el cursor de pull de una tabla (regla de sync 3).
Future<void> guardarCursor(BaseDeDatos db, String tabla, String cursor) async {
  _validarTabla(tabla);
  await db.into(db.cursoresSync).insertOnConflictUpdate(
        CursoresSyncCompanion.insert(tabla: tabla, cursor: cursor),
      );
}

/// Marca global de la última sesión de sync exitosa (condición de R15).
Future<DateTime?> ultimoSyncExitoso(BaseDeDatos db) async {
  final filas = await (db.select(db.estadoSync)
        ..where((e) => e.id.equals('global')))
      .get();
  if (filas.isEmpty || filas.single.ultimoSyncExitoso == null) return null;
  return DateTime.parse(filas.single.ultimoSyncExitoso!);
}

Future<void> marcarSyncExitosa(BaseDeDatos db, DateTime cuando) async {
  await db.into(db.estadoSync).insertOnConflictUpdate(
        EstadoSyncCompanion.insert(
          id: 'global',
          ultimoSyncExitoso: Value(cuando.toUtc().toIso8601String()),
        ),
      );
}

/// ¿[a] es estrictamente más reciente que [b]? Compara ISO-8601; si el
/// formato no parsea, cae a comparación lexicográfica.
bool momentoMasReciente(String a, String b) {
  final da = DateTime.tryParse(a);
  final dbTs = DateTime.tryParse(b);
  if (da != null && dbTs != null) return da.isAfter(dbTs);
  return a.compareTo(b) > 0;
}
