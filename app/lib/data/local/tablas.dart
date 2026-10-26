import 'package:drift/drift.dart';

/// Tablas del esquema v1 — espejo de docs/modelo-de-datos.md.
///
/// Convenciones (Log L2 de esta fase): identificadores UUID en TEXT;
/// fechas ISO-8601 en TEXT; precios en REAL redondeados a 2 decimales por la
/// capa de datos (equivalente funcional a NUMERIC(12,2) en SQLite).
///
/// Granel (AD-014): los bienes por kg/L/m/unidad sin contenido neto fijo se
/// tratan con contenido neto implícito = 1 (ver normalizacion.dart).

@TableIndex(name: 'idx_articulo_nombre', columns: {#nombre})
class Articulos extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get categoria => text().nullable()();

  /// kg | L | unidad | m — unidad en la que se compara el artículo.
  TextColumn get unidadBase => text()();

  TextColumn get creadoPor => text()();
  TextColumn get creadoEn => text()();
  TextColumn get actualizadoEn => text()();
  TextColumn get borradoEn => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_producto_nombre', columns: {#nombre})
@TableIndex(name: 'idx_producto_marca', columns: {#marca})
@TableIndex(name: 'idx_producto_articulo', columns: {#articuloId})
class Productos extends Table {
  TextColumn get id => text()();

  /// Único si existe; SQLite permite múltiples NULL en un índice UNIQUE,
  /// que es exactamente la semántica "único parcial" del modelo.
  TextColumn get codigoBarras => text().nullable().unique()();

  TextColumn get articuloId => text().nullable().references(Articulos, #id)();
  TextColumn get nombre => text()();
  TextColumn get marca => text().nullable()();
  TextColumn get categoria => text().nullable()();

  /// kg | g | L | mL | unidad | m — unidad en que se vende.
  TextColumn get unidad => text()();
  RealColumn get contenidoNeto => real().nullable()();
  TextColumn get notas => text().nullable()();
  TextColumn get creadoPor => text()();
  TextColumn get creadoEn => text()();
  TextColumn get actualizadoEn => text()();
  TextColumn get borradoEn => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_comercio_nombre', columns: {#nombre})
class Comercios extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get tipo => text().nullable()();
  TextColumn get direccion => text().nullable()();
  TextColumn get creadoPor => text()();
  TextColumn get creadoEn => text()();
  TextColumn get actualizadoEn => text()();
  TextColumn get borradoEn => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only: la capa de datos no expone update ni delete (modelo, regla 1).
@TableIndex(name: 'idx_precio_producto_fecha', columns: {#productoId, #fechaToma})
@TableIndex(name: 'idx_precio_fecha', columns: {#fechaToma})
class Precios extends Table {
  TextColumn get id => text()();
  TextColumn get productoId => text().references(Productos, #id)();
  TextColumn get comercioId => text().references(Comercios, #id)();

  /// Valor del precio; siempre NOT NULL, > 0 y redondeado a 2 decimales.
  /// El constraint custom pisa el NOT NULL por defecto de drift: se re-declara.
  RealColumn get precio => real().customConstraint('NOT NULL CHECK (precio > 0)')();

  /// Fecha declarada por el usuario (ISO-8601, "YYYY-MM-DD").
  TextColumn get fechaToma => text()();
  TextColumn get cargadoPor => text()();
  TextColumn get cargadoEn => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Usuarios extends Table {
  TextColumn get id => text()();
  TextColumn get etiqueta => text()();
  TextColumn get authUid => text().nullable()();
  TextColumn get creadoEn => text()();
  TextColumn get actualizadoEn => text()();

  @override
  Set<Column> get primaryKey => {id};
}
