// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_de_datos.dart';

// ignore_for_file: type=lint
class $ArticulosTable extends Articulos
    with TableInfo<$ArticulosTable, Articulo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticulosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unidadBaseMeta = const VerificationMeta(
    'unidadBase',
  );
  @override
  late final GeneratedColumn<String> unidadBase = GeneratedColumn<String>(
    'unidad_base',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoPorMeta = const VerificationMeta(
    'creadoPor',
  );
  @override
  late final GeneratedColumn<String> creadoPor = GeneratedColumn<String>(
    'creado_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<String> creadoEn = GeneratedColumn<String>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<String> actualizadoEn = GeneratedColumn<String>(
    'actualizado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _borradoEnMeta = const VerificationMeta(
    'borradoEn',
  );
  @override
  late final GeneratedColumn<String> borradoEn = GeneratedColumn<String>(
    'borrado_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    categoria,
    unidadBase,
    creadoPor,
    creadoEn,
    actualizadoEn,
    borradoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'articulos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Articulo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    if (data.containsKey('unidad_base')) {
      context.handle(
        _unidadBaseMeta,
        unidadBase.isAcceptableOrUnknown(data['unidad_base']!, _unidadBaseMeta),
      );
    } else if (isInserting) {
      context.missing(_unidadBaseMeta);
    }
    if (data.containsKey('creado_por')) {
      context.handle(
        _creadoPorMeta,
        creadoPor.isAcceptableOrUnknown(data['creado_por']!, _creadoPorMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoPorMeta);
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoEnMeta);
    }
    if (data.containsKey('borrado_en')) {
      context.handle(
        _borradoEnMeta,
        borradoEn.isAcceptableOrUnknown(data['borrado_en']!, _borradoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Articulo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Articulo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      ),
      unidadBase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad_base'],
      )!,
      creadoPor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_por'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizado_en'],
      )!,
      borradoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}borrado_en'],
      ),
    );
  }

  @override
  $ArticulosTable createAlias(String alias) {
    return $ArticulosTable(attachedDatabase, alias);
  }
}

class Articulo extends DataClass implements Insertable<Articulo> {
  final String id;
  final String nombre;
  final String? categoria;

  /// kg | L | unidad | m — unidad en la que se compara el artículo.
  final String unidadBase;
  final String creadoPor;
  final String creadoEn;
  final String actualizadoEn;
  final String? borradoEn;
  const Articulo({
    required this.id,
    required this.nombre,
    this.categoria,
    required this.unidadBase,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoEn,
    this.borradoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    map['unidad_base'] = Variable<String>(unidadBase);
    map['creado_por'] = Variable<String>(creadoPor);
    map['creado_en'] = Variable<String>(creadoEn);
    map['actualizado_en'] = Variable<String>(actualizadoEn);
    if (!nullToAbsent || borradoEn != null) {
      map['borrado_en'] = Variable<String>(borradoEn);
    }
    return map;
  }

  ArticulosCompanion toCompanion(bool nullToAbsent) {
    return ArticulosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      unidadBase: Value(unidadBase),
      creadoPor: Value(creadoPor),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
      borradoEn: borradoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(borradoEn),
    );
  }

  factory Articulo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Articulo(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      unidadBase: serializer.fromJson<String>(json['unidadBase']),
      creadoPor: serializer.fromJson<String>(json['creadoPor']),
      creadoEn: serializer.fromJson<String>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<String>(json['actualizadoEn']),
      borradoEn: serializer.fromJson<String?>(json['borradoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'categoria': serializer.toJson<String?>(categoria),
      'unidadBase': serializer.toJson<String>(unidadBase),
      'creadoPor': serializer.toJson<String>(creadoPor),
      'creadoEn': serializer.toJson<String>(creadoEn),
      'actualizadoEn': serializer.toJson<String>(actualizadoEn),
      'borradoEn': serializer.toJson<String?>(borradoEn),
    };
  }

  Articulo copyWith({
    String? id,
    String? nombre,
    Value<String?> categoria = const Value.absent(),
    String? unidadBase,
    String? creadoPor,
    String? creadoEn,
    String? actualizadoEn,
    Value<String?> borradoEn = const Value.absent(),
  }) => Articulo(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    categoria: categoria.present ? categoria.value : this.categoria,
    unidadBase: unidadBase ?? this.unidadBase,
    creadoPor: creadoPor ?? this.creadoPor,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    borradoEn: borradoEn.present ? borradoEn.value : this.borradoEn,
  );
  Articulo copyWithCompanion(ArticulosCompanion data) {
    return Articulo(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      unidadBase: data.unidadBase.present
          ? data.unidadBase.value
          : this.unidadBase,
      creadoPor: data.creadoPor.present ? data.creadoPor.value : this.creadoPor,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
      borradoEn: data.borradoEn.present ? data.borradoEn.value : this.borradoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Articulo(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('unidadBase: $unidadBase, ')
          ..write('creadoPor: $creadoPor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('borradoEn: $borradoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    categoria,
    unidadBase,
    creadoPor,
    creadoEn,
    actualizadoEn,
    borradoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Articulo &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.categoria == this.categoria &&
          other.unidadBase == this.unidadBase &&
          other.creadoPor == this.creadoPor &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn &&
          other.borradoEn == this.borradoEn);
}

class ArticulosCompanion extends UpdateCompanion<Articulo> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String?> categoria;
  final Value<String> unidadBase;
  final Value<String> creadoPor;
  final Value<String> creadoEn;
  final Value<String> actualizadoEn;
  final Value<String?> borradoEn;
  final Value<int> rowid;
  const ArticulosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.categoria = const Value.absent(),
    this.unidadBase = const Value.absent(),
    this.creadoPor = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.borradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArticulosCompanion.insert({
    required String id,
    required String nombre,
    this.categoria = const Value.absent(),
    required String unidadBase,
    required String creadoPor,
    required String creadoEn,
    required String actualizadoEn,
    this.borradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       unidadBase = Value(unidadBase),
       creadoPor = Value(creadoPor),
       creadoEn = Value(creadoEn),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<Articulo> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? categoria,
    Expression<String>? unidadBase,
    Expression<String>? creadoPor,
    Expression<String>? creadoEn,
    Expression<String>? actualizadoEn,
    Expression<String>? borradoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (categoria != null) 'categoria': categoria,
      if (unidadBase != null) 'unidad_base': unidadBase,
      if (creadoPor != null) 'creado_por': creadoPor,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (borradoEn != null) 'borrado_en': borradoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArticulosCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String?>? categoria,
    Value<String>? unidadBase,
    Value<String>? creadoPor,
    Value<String>? creadoEn,
    Value<String>? actualizadoEn,
    Value<String?>? borradoEn,
    Value<int>? rowid,
  }) {
    return ArticulosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      unidadBase: unidadBase ?? this.unidadBase,
      creadoPor: creadoPor ?? this.creadoPor,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      borradoEn: borradoEn ?? this.borradoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (unidadBase.present) {
      map['unidad_base'] = Variable<String>(unidadBase.value);
    }
    if (creadoPor.present) {
      map['creado_por'] = Variable<String>(creadoPor.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<String>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<String>(actualizadoEn.value);
    }
    if (borradoEn.present) {
      map['borrado_en'] = Variable<String>(borradoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticulosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('unidadBase: $unidadBase, ')
          ..write('creadoPor: $creadoPor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('borradoEn: $borradoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductosTable extends Productos
    with TableInfo<$ProductosTable, Producto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoBarrasMeta = const VerificationMeta(
    'codigoBarras',
  );
  @override
  late final GeneratedColumn<String> codigoBarras = GeneratedColumn<String>(
    'codigo_barras',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _articuloIdMeta = const VerificationMeta(
    'articuloId',
  );
  @override
  late final GeneratedColumn<String> articuloId = GeneratedColumn<String>(
    'articulo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES articulos (id)',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
    'marca',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unidadMeta = const VerificationMeta('unidad');
  @override
  late final GeneratedColumn<String> unidad = GeneratedColumn<String>(
    'unidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contenidoNetoMeta = const VerificationMeta(
    'contenidoNeto',
  );
  @override
  late final GeneratedColumn<double> contenidoNeto = GeneratedColumn<double>(
    'contenido_neto',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _origenMeta = const VerificationMeta('origen');
  @override
  late final GeneratedColumn<String> origen = GeneratedColumn<String>(
    'origen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoPorMeta = const VerificationMeta(
    'creadoPor',
  );
  @override
  late final GeneratedColumn<String> creadoPor = GeneratedColumn<String>(
    'creado_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<String> creadoEn = GeneratedColumn<String>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<String> actualizadoEn = GeneratedColumn<String>(
    'actualizado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _borradoEnMeta = const VerificationMeta(
    'borradoEn',
  );
  @override
  late final GeneratedColumn<String> borradoEn = GeneratedColumn<String>(
    'borrado_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    codigoBarras,
    articuloId,
    nombre,
    marca,
    categoria,
    unidad,
    contenidoNeto,
    origen,
    notas,
    creadoPor,
    creadoEn,
    actualizadoEn,
    borradoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Producto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('codigo_barras')) {
      context.handle(
        _codigoBarrasMeta,
        codigoBarras.isAcceptableOrUnknown(
          data['codigo_barras']!,
          _codigoBarrasMeta,
        ),
      );
    }
    if (data.containsKey('articulo_id')) {
      context.handle(
        _articuloIdMeta,
        articuloId.isAcceptableOrUnknown(data['articulo_id']!, _articuloIdMeta),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('marca')) {
      context.handle(
        _marcaMeta,
        marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta),
      );
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    if (data.containsKey('unidad')) {
      context.handle(
        _unidadMeta,
        unidad.isAcceptableOrUnknown(data['unidad']!, _unidadMeta),
      );
    } else if (isInserting) {
      context.missing(_unidadMeta);
    }
    if (data.containsKey('contenido_neto')) {
      context.handle(
        _contenidoNetoMeta,
        contenidoNeto.isAcceptableOrUnknown(
          data['contenido_neto']!,
          _contenidoNetoMeta,
        ),
      );
    }
    if (data.containsKey('origen')) {
      context.handle(
        _origenMeta,
        origen.isAcceptableOrUnknown(data['origen']!, _origenMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('creado_por')) {
      context.handle(
        _creadoPorMeta,
        creadoPor.isAcceptableOrUnknown(data['creado_por']!, _creadoPorMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoPorMeta);
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoEnMeta);
    }
    if (data.containsKey('borrado_en')) {
      context.handle(
        _borradoEnMeta,
        borradoEn.isAcceptableOrUnknown(data['borrado_en']!, _borradoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Producto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Producto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      codigoBarras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_barras'],
      ),
      articuloId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}articulo_id'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      marca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marca'],
      ),
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      ),
      unidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad'],
      )!,
      contenidoNeto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}contenido_neto'],
      ),
      origen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origen'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      creadoPor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_por'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizado_en'],
      )!,
      borradoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}borrado_en'],
      ),
    );
  }

  @override
  $ProductosTable createAlias(String alias) {
    return $ProductosTable(attachedDatabase, alias);
  }
}

class Producto extends DataClass implements Insertable<Producto> {
  final String id;

  /// Único si existe; SQLite permite múltiples NULL en un índice UNIQUE,
  /// que es exactamente la semántica "único parcial" del modelo.
  final String? codigoBarras;
  final String? articuloId;
  final String nombre;
  final String? marca;
  final String? categoria;

  /// kg | g | L | mL | unidad | m — unidad en que se vende.
  final String unidad;
  final double? contenidoNeto;

  /// 'semilla' si vino del pack de Open Food Facts; null si lo cargó un usuario.
  final String? origen;
  final String? notas;
  final String creadoPor;
  final String creadoEn;
  final String actualizadoEn;
  final String? borradoEn;
  const Producto({
    required this.id,
    this.codigoBarras,
    this.articuloId,
    required this.nombre,
    this.marca,
    this.categoria,
    required this.unidad,
    this.contenidoNeto,
    this.origen,
    this.notas,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoEn,
    this.borradoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || codigoBarras != null) {
      map['codigo_barras'] = Variable<String>(codigoBarras);
    }
    if (!nullToAbsent || articuloId != null) {
      map['articulo_id'] = Variable<String>(articuloId);
    }
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || marca != null) {
      map['marca'] = Variable<String>(marca);
    }
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    map['unidad'] = Variable<String>(unidad);
    if (!nullToAbsent || contenidoNeto != null) {
      map['contenido_neto'] = Variable<double>(contenidoNeto);
    }
    if (!nullToAbsent || origen != null) {
      map['origen'] = Variable<String>(origen);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    map['creado_por'] = Variable<String>(creadoPor);
    map['creado_en'] = Variable<String>(creadoEn);
    map['actualizado_en'] = Variable<String>(actualizadoEn);
    if (!nullToAbsent || borradoEn != null) {
      map['borrado_en'] = Variable<String>(borradoEn);
    }
    return map;
  }

  ProductosCompanion toCompanion(bool nullToAbsent) {
    return ProductosCompanion(
      id: Value(id),
      codigoBarras: codigoBarras == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoBarras),
      articuloId: articuloId == null && nullToAbsent
          ? const Value.absent()
          : Value(articuloId),
      nombre: Value(nombre),
      marca: marca == null && nullToAbsent
          ? const Value.absent()
          : Value(marca),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      unidad: Value(unidad),
      contenidoNeto: contenidoNeto == null && nullToAbsent
          ? const Value.absent()
          : Value(contenidoNeto),
      origen: origen == null && nullToAbsent
          ? const Value.absent()
          : Value(origen),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      creadoPor: Value(creadoPor),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
      borradoEn: borradoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(borradoEn),
    );
  }

  factory Producto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Producto(
      id: serializer.fromJson<String>(json['id']),
      codigoBarras: serializer.fromJson<String?>(json['codigoBarras']),
      articuloId: serializer.fromJson<String?>(json['articuloId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      marca: serializer.fromJson<String?>(json['marca']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      unidad: serializer.fromJson<String>(json['unidad']),
      contenidoNeto: serializer.fromJson<double?>(json['contenidoNeto']),
      origen: serializer.fromJson<String?>(json['origen']),
      notas: serializer.fromJson<String?>(json['notas']),
      creadoPor: serializer.fromJson<String>(json['creadoPor']),
      creadoEn: serializer.fromJson<String>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<String>(json['actualizadoEn']),
      borradoEn: serializer.fromJson<String?>(json['borradoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'codigoBarras': serializer.toJson<String?>(codigoBarras),
      'articuloId': serializer.toJson<String?>(articuloId),
      'nombre': serializer.toJson<String>(nombre),
      'marca': serializer.toJson<String?>(marca),
      'categoria': serializer.toJson<String?>(categoria),
      'unidad': serializer.toJson<String>(unidad),
      'contenidoNeto': serializer.toJson<double?>(contenidoNeto),
      'origen': serializer.toJson<String?>(origen),
      'notas': serializer.toJson<String?>(notas),
      'creadoPor': serializer.toJson<String>(creadoPor),
      'creadoEn': serializer.toJson<String>(creadoEn),
      'actualizadoEn': serializer.toJson<String>(actualizadoEn),
      'borradoEn': serializer.toJson<String?>(borradoEn),
    };
  }

  Producto copyWith({
    String? id,
    Value<String?> codigoBarras = const Value.absent(),
    Value<String?> articuloId = const Value.absent(),
    String? nombre,
    Value<String?> marca = const Value.absent(),
    Value<String?> categoria = const Value.absent(),
    String? unidad,
    Value<double?> contenidoNeto = const Value.absent(),
    Value<String?> origen = const Value.absent(),
    Value<String?> notas = const Value.absent(),
    String? creadoPor,
    String? creadoEn,
    String? actualizadoEn,
    Value<String?> borradoEn = const Value.absent(),
  }) => Producto(
    id: id ?? this.id,
    codigoBarras: codigoBarras.present ? codigoBarras.value : this.codigoBarras,
    articuloId: articuloId.present ? articuloId.value : this.articuloId,
    nombre: nombre ?? this.nombre,
    marca: marca.present ? marca.value : this.marca,
    categoria: categoria.present ? categoria.value : this.categoria,
    unidad: unidad ?? this.unidad,
    contenidoNeto: contenidoNeto.present
        ? contenidoNeto.value
        : this.contenidoNeto,
    origen: origen.present ? origen.value : this.origen,
    notas: notas.present ? notas.value : this.notas,
    creadoPor: creadoPor ?? this.creadoPor,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    borradoEn: borradoEn.present ? borradoEn.value : this.borradoEn,
  );
  Producto copyWithCompanion(ProductosCompanion data) {
    return Producto(
      id: data.id.present ? data.id.value : this.id,
      codigoBarras: data.codigoBarras.present
          ? data.codigoBarras.value
          : this.codigoBarras,
      articuloId: data.articuloId.present
          ? data.articuloId.value
          : this.articuloId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      marca: data.marca.present ? data.marca.value : this.marca,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      unidad: data.unidad.present ? data.unidad.value : this.unidad,
      contenidoNeto: data.contenidoNeto.present
          ? data.contenidoNeto.value
          : this.contenidoNeto,
      origen: data.origen.present ? data.origen.value : this.origen,
      notas: data.notas.present ? data.notas.value : this.notas,
      creadoPor: data.creadoPor.present ? data.creadoPor.value : this.creadoPor,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
      borradoEn: data.borradoEn.present ? data.borradoEn.value : this.borradoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Producto(')
          ..write('id: $id, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('articuloId: $articuloId, ')
          ..write('nombre: $nombre, ')
          ..write('marca: $marca, ')
          ..write('categoria: $categoria, ')
          ..write('unidad: $unidad, ')
          ..write('contenidoNeto: $contenidoNeto, ')
          ..write('origen: $origen, ')
          ..write('notas: $notas, ')
          ..write('creadoPor: $creadoPor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('borradoEn: $borradoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    codigoBarras,
    articuloId,
    nombre,
    marca,
    categoria,
    unidad,
    contenidoNeto,
    origen,
    notas,
    creadoPor,
    creadoEn,
    actualizadoEn,
    borradoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Producto &&
          other.id == this.id &&
          other.codigoBarras == this.codigoBarras &&
          other.articuloId == this.articuloId &&
          other.nombre == this.nombre &&
          other.marca == this.marca &&
          other.categoria == this.categoria &&
          other.unidad == this.unidad &&
          other.contenidoNeto == this.contenidoNeto &&
          other.origen == this.origen &&
          other.notas == this.notas &&
          other.creadoPor == this.creadoPor &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn &&
          other.borradoEn == this.borradoEn);
}

class ProductosCompanion extends UpdateCompanion<Producto> {
  final Value<String> id;
  final Value<String?> codigoBarras;
  final Value<String?> articuloId;
  final Value<String> nombre;
  final Value<String?> marca;
  final Value<String?> categoria;
  final Value<String> unidad;
  final Value<double?> contenidoNeto;
  final Value<String?> origen;
  final Value<String?> notas;
  final Value<String> creadoPor;
  final Value<String> creadoEn;
  final Value<String> actualizadoEn;
  final Value<String?> borradoEn;
  final Value<int> rowid;
  const ProductosCompanion({
    this.id = const Value.absent(),
    this.codigoBarras = const Value.absent(),
    this.articuloId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.marca = const Value.absent(),
    this.categoria = const Value.absent(),
    this.unidad = const Value.absent(),
    this.contenidoNeto = const Value.absent(),
    this.origen = const Value.absent(),
    this.notas = const Value.absent(),
    this.creadoPor = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.borradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductosCompanion.insert({
    required String id,
    this.codigoBarras = const Value.absent(),
    this.articuloId = const Value.absent(),
    required String nombre,
    this.marca = const Value.absent(),
    this.categoria = const Value.absent(),
    required String unidad,
    this.contenidoNeto = const Value.absent(),
    this.origen = const Value.absent(),
    this.notas = const Value.absent(),
    required String creadoPor,
    required String creadoEn,
    required String actualizadoEn,
    this.borradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       unidad = Value(unidad),
       creadoPor = Value(creadoPor),
       creadoEn = Value(creadoEn),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<Producto> custom({
    Expression<String>? id,
    Expression<String>? codigoBarras,
    Expression<String>? articuloId,
    Expression<String>? nombre,
    Expression<String>? marca,
    Expression<String>? categoria,
    Expression<String>? unidad,
    Expression<double>? contenidoNeto,
    Expression<String>? origen,
    Expression<String>? notas,
    Expression<String>? creadoPor,
    Expression<String>? creadoEn,
    Expression<String>? actualizadoEn,
    Expression<String>? borradoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (codigoBarras != null) 'codigo_barras': codigoBarras,
      if (articuloId != null) 'articulo_id': articuloId,
      if (nombre != null) 'nombre': nombre,
      if (marca != null) 'marca': marca,
      if (categoria != null) 'categoria': categoria,
      if (unidad != null) 'unidad': unidad,
      if (contenidoNeto != null) 'contenido_neto': contenidoNeto,
      if (origen != null) 'origen': origen,
      if (notas != null) 'notas': notas,
      if (creadoPor != null) 'creado_por': creadoPor,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (borradoEn != null) 'borrado_en': borradoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductosCompanion copyWith({
    Value<String>? id,
    Value<String?>? codigoBarras,
    Value<String?>? articuloId,
    Value<String>? nombre,
    Value<String?>? marca,
    Value<String?>? categoria,
    Value<String>? unidad,
    Value<double?>? contenidoNeto,
    Value<String?>? origen,
    Value<String?>? notas,
    Value<String>? creadoPor,
    Value<String>? creadoEn,
    Value<String>? actualizadoEn,
    Value<String?>? borradoEn,
    Value<int>? rowid,
  }) {
    return ProductosCompanion(
      id: id ?? this.id,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      articuloId: articuloId ?? this.articuloId,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      categoria: categoria ?? this.categoria,
      unidad: unidad ?? this.unidad,
      contenidoNeto: contenidoNeto ?? this.contenidoNeto,
      origen: origen ?? this.origen,
      notas: notas ?? this.notas,
      creadoPor: creadoPor ?? this.creadoPor,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      borradoEn: borradoEn ?? this.borradoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (codigoBarras.present) {
      map['codigo_barras'] = Variable<String>(codigoBarras.value);
    }
    if (articuloId.present) {
      map['articulo_id'] = Variable<String>(articuloId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (unidad.present) {
      map['unidad'] = Variable<String>(unidad.value);
    }
    if (contenidoNeto.present) {
      map['contenido_neto'] = Variable<double>(contenidoNeto.value);
    }
    if (origen.present) {
      map['origen'] = Variable<String>(origen.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (creadoPor.present) {
      map['creado_por'] = Variable<String>(creadoPor.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<String>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<String>(actualizadoEn.value);
    }
    if (borradoEn.present) {
      map['borrado_en'] = Variable<String>(borradoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductosCompanion(')
          ..write('id: $id, ')
          ..write('codigoBarras: $codigoBarras, ')
          ..write('articuloId: $articuloId, ')
          ..write('nombre: $nombre, ')
          ..write('marca: $marca, ')
          ..write('categoria: $categoria, ')
          ..write('unidad: $unidad, ')
          ..write('contenidoNeto: $contenidoNeto, ')
          ..write('origen: $origen, ')
          ..write('notas: $notas, ')
          ..write('creadoPor: $creadoPor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('borradoEn: $borradoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComerciosTable extends Comercios
    with TableInfo<$ComerciosTable, Comercio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComerciosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _direccionMeta = const VerificationMeta(
    'direccion',
  );
  @override
  late final GeneratedColumn<String> direccion = GeneratedColumn<String>(
    'direccion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoPorMeta = const VerificationMeta(
    'creadoPor',
  );
  @override
  late final GeneratedColumn<String> creadoPor = GeneratedColumn<String>(
    'creado_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<String> creadoEn = GeneratedColumn<String>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<String> actualizadoEn = GeneratedColumn<String>(
    'actualizado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _borradoEnMeta = const VerificationMeta(
    'borradoEn',
  );
  @override
  late final GeneratedColumn<String> borradoEn = GeneratedColumn<String>(
    'borrado_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    tipo,
    direccion,
    creadoPor,
    creadoEn,
    actualizadoEn,
    borradoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comercios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Comercio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('direccion')) {
      context.handle(
        _direccionMeta,
        direccion.isAcceptableOrUnknown(data['direccion']!, _direccionMeta),
      );
    }
    if (data.containsKey('creado_por')) {
      context.handle(
        _creadoPorMeta,
        creadoPor.isAcceptableOrUnknown(data['creado_por']!, _creadoPorMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoPorMeta);
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoEnMeta);
    }
    if (data.containsKey('borrado_en')) {
      context.handle(
        _borradoEnMeta,
        borradoEn.isAcceptableOrUnknown(data['borrado_en']!, _borradoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Comercio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Comercio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      ),
      direccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direccion'],
      ),
      creadoPor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_por'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizado_en'],
      )!,
      borradoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}borrado_en'],
      ),
    );
  }

  @override
  $ComerciosTable createAlias(String alias) {
    return $ComerciosTable(attachedDatabase, alias);
  }
}

class Comercio extends DataClass implements Insertable<Comercio> {
  final String id;
  final String nombre;
  final String? tipo;
  final String? direccion;
  final String creadoPor;
  final String creadoEn;
  final String actualizadoEn;
  final String? borradoEn;
  const Comercio({
    required this.id,
    required this.nombre,
    this.tipo,
    this.direccion,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoEn,
    this.borradoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || tipo != null) {
      map['tipo'] = Variable<String>(tipo);
    }
    if (!nullToAbsent || direccion != null) {
      map['direccion'] = Variable<String>(direccion);
    }
    map['creado_por'] = Variable<String>(creadoPor);
    map['creado_en'] = Variable<String>(creadoEn);
    map['actualizado_en'] = Variable<String>(actualizadoEn);
    if (!nullToAbsent || borradoEn != null) {
      map['borrado_en'] = Variable<String>(borradoEn);
    }
    return map;
  }

  ComerciosCompanion toCompanion(bool nullToAbsent) {
    return ComerciosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      tipo: tipo == null && nullToAbsent ? const Value.absent() : Value(tipo),
      direccion: direccion == null && nullToAbsent
          ? const Value.absent()
          : Value(direccion),
      creadoPor: Value(creadoPor),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
      borradoEn: borradoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(borradoEn),
    );
  }

  factory Comercio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Comercio(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      tipo: serializer.fromJson<String?>(json['tipo']),
      direccion: serializer.fromJson<String?>(json['direccion']),
      creadoPor: serializer.fromJson<String>(json['creadoPor']),
      creadoEn: serializer.fromJson<String>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<String>(json['actualizadoEn']),
      borradoEn: serializer.fromJson<String?>(json['borradoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'tipo': serializer.toJson<String?>(tipo),
      'direccion': serializer.toJson<String?>(direccion),
      'creadoPor': serializer.toJson<String>(creadoPor),
      'creadoEn': serializer.toJson<String>(creadoEn),
      'actualizadoEn': serializer.toJson<String>(actualizadoEn),
      'borradoEn': serializer.toJson<String?>(borradoEn),
    };
  }

  Comercio copyWith({
    String? id,
    String? nombre,
    Value<String?> tipo = const Value.absent(),
    Value<String?> direccion = const Value.absent(),
    String? creadoPor,
    String? creadoEn,
    String? actualizadoEn,
    Value<String?> borradoEn = const Value.absent(),
  }) => Comercio(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    tipo: tipo.present ? tipo.value : this.tipo,
    direccion: direccion.present ? direccion.value : this.direccion,
    creadoPor: creadoPor ?? this.creadoPor,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    borradoEn: borradoEn.present ? borradoEn.value : this.borradoEn,
  );
  Comercio copyWithCompanion(ComerciosCompanion data) {
    return Comercio(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      direccion: data.direccion.present ? data.direccion.value : this.direccion,
      creadoPor: data.creadoPor.present ? data.creadoPor.value : this.creadoPor,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
      borradoEn: data.borradoEn.present ? data.borradoEn.value : this.borradoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Comercio(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo, ')
          ..write('direccion: $direccion, ')
          ..write('creadoPor: $creadoPor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('borradoEn: $borradoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    tipo,
    direccion,
    creadoPor,
    creadoEn,
    actualizadoEn,
    borradoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Comercio &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.tipo == this.tipo &&
          other.direccion == this.direccion &&
          other.creadoPor == this.creadoPor &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn &&
          other.borradoEn == this.borradoEn);
}

class ComerciosCompanion extends UpdateCompanion<Comercio> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String?> tipo;
  final Value<String?> direccion;
  final Value<String> creadoPor;
  final Value<String> creadoEn;
  final Value<String> actualizadoEn;
  final Value<String?> borradoEn;
  final Value<int> rowid;
  const ComerciosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.tipo = const Value.absent(),
    this.direccion = const Value.absent(),
    this.creadoPor = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.borradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComerciosCompanion.insert({
    required String id,
    required String nombre,
    this.tipo = const Value.absent(),
    this.direccion = const Value.absent(),
    required String creadoPor,
    required String creadoEn,
    required String actualizadoEn,
    this.borradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       creadoPor = Value(creadoPor),
       creadoEn = Value(creadoEn),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<Comercio> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? tipo,
    Expression<String>? direccion,
    Expression<String>? creadoPor,
    Expression<String>? creadoEn,
    Expression<String>? actualizadoEn,
    Expression<String>? borradoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (tipo != null) 'tipo': tipo,
      if (direccion != null) 'direccion': direccion,
      if (creadoPor != null) 'creado_por': creadoPor,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (borradoEn != null) 'borrado_en': borradoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComerciosCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String?>? tipo,
    Value<String?>? direccion,
    Value<String>? creadoPor,
    Value<String>? creadoEn,
    Value<String>? actualizadoEn,
    Value<String?>? borradoEn,
    Value<int>? rowid,
  }) {
    return ComerciosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      direccion: direccion ?? this.direccion,
      creadoPor: creadoPor ?? this.creadoPor,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      borradoEn: borradoEn ?? this.borradoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (direccion.present) {
      map['direccion'] = Variable<String>(direccion.value);
    }
    if (creadoPor.present) {
      map['creado_por'] = Variable<String>(creadoPor.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<String>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<String>(actualizadoEn.value);
    }
    if (borradoEn.present) {
      map['borrado_en'] = Variable<String>(borradoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComerciosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo, ')
          ..write('direccion: $direccion, ')
          ..write('creadoPor: $creadoPor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('borradoEn: $borradoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreciosTable extends Precios with TableInfo<$PreciosTable, Precio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreciosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productoIdMeta = const VerificationMeta(
    'productoId',
  );
  @override
  late final GeneratedColumn<String> productoId = GeneratedColumn<String>(
    'producto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES productos (id)',
    ),
  );
  static const VerificationMeta _comercioIdMeta = const VerificationMeta(
    'comercioId',
  );
  @override
  late final GeneratedColumn<String> comercioId = GeneratedColumn<String>(
    'comercio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES comercios (id)',
    ),
  );
  static const VerificationMeta _precioMeta = const VerificationMeta('precio');
  @override
  late final GeneratedColumn<double> precio = GeneratedColumn<double>(
    'precio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (precio > 0)',
  );
  static const VerificationMeta _fechaTomaMeta = const VerificationMeta(
    'fechaToma',
  );
  @override
  late final GeneratedColumn<String> fechaToma = GeneratedColumn<String>(
    'fecha_toma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cargadoPorMeta = const VerificationMeta(
    'cargadoPor',
  );
  @override
  late final GeneratedColumn<String> cargadoPor = GeneratedColumn<String>(
    'cargado_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cargadoEnMeta = const VerificationMeta(
    'cargadoEn',
  );
  @override
  late final GeneratedColumn<String> cargadoEn = GeneratedColumn<String>(
    'cargado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productoId,
    comercioId,
    precio,
    fechaToma,
    cargadoPor,
    cargadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'precios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Precio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('producto_id')) {
      context.handle(
        _productoIdMeta,
        productoId.isAcceptableOrUnknown(data['producto_id']!, _productoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productoIdMeta);
    }
    if (data.containsKey('comercio_id')) {
      context.handle(
        _comercioIdMeta,
        comercioId.isAcceptableOrUnknown(data['comercio_id']!, _comercioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_comercioIdMeta);
    }
    if (data.containsKey('precio')) {
      context.handle(
        _precioMeta,
        precio.isAcceptableOrUnknown(data['precio']!, _precioMeta),
      );
    } else if (isInserting) {
      context.missing(_precioMeta);
    }
    if (data.containsKey('fecha_toma')) {
      context.handle(
        _fechaTomaMeta,
        fechaToma.isAcceptableOrUnknown(data['fecha_toma']!, _fechaTomaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaTomaMeta);
    }
    if (data.containsKey('cargado_por')) {
      context.handle(
        _cargadoPorMeta,
        cargadoPor.isAcceptableOrUnknown(data['cargado_por']!, _cargadoPorMeta),
      );
    } else if (isInserting) {
      context.missing(_cargadoPorMeta);
    }
    if (data.containsKey('cargado_en')) {
      context.handle(
        _cargadoEnMeta,
        cargadoEn.isAcceptableOrUnknown(data['cargado_en']!, _cargadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_cargadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Precio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Precio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_id'],
      )!,
      comercioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comercio_id'],
      )!,
      precio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio'],
      )!,
      fechaToma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha_toma'],
      )!,
      cargadoPor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cargado_por'],
      )!,
      cargadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cargado_en'],
      )!,
    );
  }

  @override
  $PreciosTable createAlias(String alias) {
    return $PreciosTable(attachedDatabase, alias);
  }
}

class Precio extends DataClass implements Insertable<Precio> {
  final String id;
  final String productoId;
  final String comercioId;

  /// Valor del precio; siempre NOT NULL, > 0 y redondeado a 2 decimales.
  /// El constraint custom pisa el NOT NULL por defecto de drift: se re-declara.
  final double precio;

  /// Fecha declarada por el usuario (ISO-8601, "YYYY-MM-DD").
  final String fechaToma;
  final String cargadoPor;
  final String cargadoEn;
  const Precio({
    required this.id,
    required this.productoId,
    required this.comercioId,
    required this.precio,
    required this.fechaToma,
    required this.cargadoPor,
    required this.cargadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['producto_id'] = Variable<String>(productoId);
    map['comercio_id'] = Variable<String>(comercioId);
    map['precio'] = Variable<double>(precio);
    map['fecha_toma'] = Variable<String>(fechaToma);
    map['cargado_por'] = Variable<String>(cargadoPor);
    map['cargado_en'] = Variable<String>(cargadoEn);
    return map;
  }

  PreciosCompanion toCompanion(bool nullToAbsent) {
    return PreciosCompanion(
      id: Value(id),
      productoId: Value(productoId),
      comercioId: Value(comercioId),
      precio: Value(precio),
      fechaToma: Value(fechaToma),
      cargadoPor: Value(cargadoPor),
      cargadoEn: Value(cargadoEn),
    );
  }

  factory Precio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Precio(
      id: serializer.fromJson<String>(json['id']),
      productoId: serializer.fromJson<String>(json['productoId']),
      comercioId: serializer.fromJson<String>(json['comercioId']),
      precio: serializer.fromJson<double>(json['precio']),
      fechaToma: serializer.fromJson<String>(json['fechaToma']),
      cargadoPor: serializer.fromJson<String>(json['cargadoPor']),
      cargadoEn: serializer.fromJson<String>(json['cargadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productoId': serializer.toJson<String>(productoId),
      'comercioId': serializer.toJson<String>(comercioId),
      'precio': serializer.toJson<double>(precio),
      'fechaToma': serializer.toJson<String>(fechaToma),
      'cargadoPor': serializer.toJson<String>(cargadoPor),
      'cargadoEn': serializer.toJson<String>(cargadoEn),
    };
  }

  Precio copyWith({
    String? id,
    String? productoId,
    String? comercioId,
    double? precio,
    String? fechaToma,
    String? cargadoPor,
    String? cargadoEn,
  }) => Precio(
    id: id ?? this.id,
    productoId: productoId ?? this.productoId,
    comercioId: comercioId ?? this.comercioId,
    precio: precio ?? this.precio,
    fechaToma: fechaToma ?? this.fechaToma,
    cargadoPor: cargadoPor ?? this.cargadoPor,
    cargadoEn: cargadoEn ?? this.cargadoEn,
  );
  Precio copyWithCompanion(PreciosCompanion data) {
    return Precio(
      id: data.id.present ? data.id.value : this.id,
      productoId: data.productoId.present
          ? data.productoId.value
          : this.productoId,
      comercioId: data.comercioId.present
          ? data.comercioId.value
          : this.comercioId,
      precio: data.precio.present ? data.precio.value : this.precio,
      fechaToma: data.fechaToma.present ? data.fechaToma.value : this.fechaToma,
      cargadoPor: data.cargadoPor.present
          ? data.cargadoPor.value
          : this.cargadoPor,
      cargadoEn: data.cargadoEn.present ? data.cargadoEn.value : this.cargadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Precio(')
          ..write('id: $id, ')
          ..write('productoId: $productoId, ')
          ..write('comercioId: $comercioId, ')
          ..write('precio: $precio, ')
          ..write('fechaToma: $fechaToma, ')
          ..write('cargadoPor: $cargadoPor, ')
          ..write('cargadoEn: $cargadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productoId,
    comercioId,
    precio,
    fechaToma,
    cargadoPor,
    cargadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Precio &&
          other.id == this.id &&
          other.productoId == this.productoId &&
          other.comercioId == this.comercioId &&
          other.precio == this.precio &&
          other.fechaToma == this.fechaToma &&
          other.cargadoPor == this.cargadoPor &&
          other.cargadoEn == this.cargadoEn);
}

class PreciosCompanion extends UpdateCompanion<Precio> {
  final Value<String> id;
  final Value<String> productoId;
  final Value<String> comercioId;
  final Value<double> precio;
  final Value<String> fechaToma;
  final Value<String> cargadoPor;
  final Value<String> cargadoEn;
  final Value<int> rowid;
  const PreciosCompanion({
    this.id = const Value.absent(),
    this.productoId = const Value.absent(),
    this.comercioId = const Value.absent(),
    this.precio = const Value.absent(),
    this.fechaToma = const Value.absent(),
    this.cargadoPor = const Value.absent(),
    this.cargadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreciosCompanion.insert({
    required String id,
    required String productoId,
    required String comercioId,
    required double precio,
    required String fechaToma,
    required String cargadoPor,
    required String cargadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productoId = Value(productoId),
       comercioId = Value(comercioId),
       precio = Value(precio),
       fechaToma = Value(fechaToma),
       cargadoPor = Value(cargadoPor),
       cargadoEn = Value(cargadoEn);
  static Insertable<Precio> custom({
    Expression<String>? id,
    Expression<String>? productoId,
    Expression<String>? comercioId,
    Expression<double>? precio,
    Expression<String>? fechaToma,
    Expression<String>? cargadoPor,
    Expression<String>? cargadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productoId != null) 'producto_id': productoId,
      if (comercioId != null) 'comercio_id': comercioId,
      if (precio != null) 'precio': precio,
      if (fechaToma != null) 'fecha_toma': fechaToma,
      if (cargadoPor != null) 'cargado_por': cargadoPor,
      if (cargadoEn != null) 'cargado_en': cargadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreciosCompanion copyWith({
    Value<String>? id,
    Value<String>? productoId,
    Value<String>? comercioId,
    Value<double>? precio,
    Value<String>? fechaToma,
    Value<String>? cargadoPor,
    Value<String>? cargadoEn,
    Value<int>? rowid,
  }) {
    return PreciosCompanion(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      comercioId: comercioId ?? this.comercioId,
      precio: precio ?? this.precio,
      fechaToma: fechaToma ?? this.fechaToma,
      cargadoPor: cargadoPor ?? this.cargadoPor,
      cargadoEn: cargadoEn ?? this.cargadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productoId.present) {
      map['producto_id'] = Variable<String>(productoId.value);
    }
    if (comercioId.present) {
      map['comercio_id'] = Variable<String>(comercioId.value);
    }
    if (precio.present) {
      map['precio'] = Variable<double>(precio.value);
    }
    if (fechaToma.present) {
      map['fecha_toma'] = Variable<String>(fechaToma.value);
    }
    if (cargadoPor.present) {
      map['cargado_por'] = Variable<String>(cargadoPor.value);
    }
    if (cargadoEn.present) {
      map['cargado_en'] = Variable<String>(cargadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreciosCompanion(')
          ..write('id: $id, ')
          ..write('productoId: $productoId, ')
          ..write('comercioId: $comercioId, ')
          ..write('precio: $precio, ')
          ..write('fechaToma: $fechaToma, ')
          ..write('cargadoPor: $cargadoPor, ')
          ..write('cargadoEn: $cargadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsuariosTable extends Usuarios with TableInfo<$UsuariosTable, Usuario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsuariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etiquetaMeta = const VerificationMeta(
    'etiqueta',
  );
  @override
  late final GeneratedColumn<String> etiqueta = GeneratedColumn<String>(
    'etiqueta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authUidMeta = const VerificationMeta(
    'authUid',
  );
  @override
  late final GeneratedColumn<String> authUid = GeneratedColumn<String>(
    'auth_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<String> creadoEn = GeneratedColumn<String>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<String> actualizadoEn = GeneratedColumn<String>(
    'actualizado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    etiqueta,
    authUid,
    creadoEn,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Usuario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('etiqueta')) {
      context.handle(
        _etiquetaMeta,
        etiqueta.isAcceptableOrUnknown(data['etiqueta']!, _etiquetaMeta),
      );
    } else if (isInserting) {
      context.missing(_etiquetaMeta);
    }
    if (data.containsKey('auth_uid')) {
      context.handle(
        _authUidMeta,
        authUid.isAcceptableOrUnknown(data['auth_uid']!, _authUidMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Usuario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Usuario(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      etiqueta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etiqueta'],
      )!,
      authUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_uid'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }
}

class Usuario extends DataClass implements Insertable<Usuario> {
  final String id;
  final String etiqueta;
  final String? authUid;
  final String creadoEn;
  final String actualizadoEn;
  const Usuario({
    required this.id,
    required this.etiqueta,
    this.authUid,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['etiqueta'] = Variable<String>(etiqueta);
    if (!nullToAbsent || authUid != null) {
      map['auth_uid'] = Variable<String>(authUid);
    }
    map['creado_en'] = Variable<String>(creadoEn);
    map['actualizado_en'] = Variable<String>(actualizadoEn);
    return map;
  }

  UsuariosCompanion toCompanion(bool nullToAbsent) {
    return UsuariosCompanion(
      id: Value(id),
      etiqueta: Value(etiqueta),
      authUid: authUid == null && nullToAbsent
          ? const Value.absent()
          : Value(authUid),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory Usuario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Usuario(
      id: serializer.fromJson<String>(json['id']),
      etiqueta: serializer.fromJson<String>(json['etiqueta']),
      authUid: serializer.fromJson<String?>(json['authUid']),
      creadoEn: serializer.fromJson<String>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<String>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'etiqueta': serializer.toJson<String>(etiqueta),
      'authUid': serializer.toJson<String?>(authUid),
      'creadoEn': serializer.toJson<String>(creadoEn),
      'actualizadoEn': serializer.toJson<String>(actualizadoEn),
    };
  }

  Usuario copyWith({
    String? id,
    String? etiqueta,
    Value<String?> authUid = const Value.absent(),
    String? creadoEn,
    String? actualizadoEn,
  }) => Usuario(
    id: id ?? this.id,
    etiqueta: etiqueta ?? this.etiqueta,
    authUid: authUid.present ? authUid.value : this.authUid,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  Usuario copyWithCompanion(UsuariosCompanion data) {
    return Usuario(
      id: data.id.present ? data.id.value : this.id,
      etiqueta: data.etiqueta.present ? data.etiqueta.value : this.etiqueta,
      authUid: data.authUid.present ? data.authUid.value : this.authUid,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Usuario(')
          ..write('id: $id, ')
          ..write('etiqueta: $etiqueta, ')
          ..write('authUid: $authUid, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, etiqueta, authUid, creadoEn, actualizadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Usuario &&
          other.id == this.id &&
          other.etiqueta == this.etiqueta &&
          other.authUid == this.authUid &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn);
}

class UsuariosCompanion extends UpdateCompanion<Usuario> {
  final Value<String> id;
  final Value<String> etiqueta;
  final Value<String?> authUid;
  final Value<String> creadoEn;
  final Value<String> actualizadoEn;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.id = const Value.absent(),
    this.etiqueta = const Value.absent(),
    this.authUid = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsuariosCompanion.insert({
    required String id,
    required String etiqueta,
    this.authUid = const Value.absent(),
    required String creadoEn,
    required String actualizadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       etiqueta = Value(etiqueta),
       creadoEn = Value(creadoEn),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<Usuario> custom({
    Expression<String>? id,
    Expression<String>? etiqueta,
    Expression<String>? authUid,
    Expression<String>? creadoEn,
    Expression<String>? actualizadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (etiqueta != null) 'etiqueta': etiqueta,
      if (authUid != null) 'auth_uid': authUid,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsuariosCompanion copyWith({
    Value<String>? id,
    Value<String>? etiqueta,
    Value<String?>? authUid,
    Value<String>? creadoEn,
    Value<String>? actualizadoEn,
    Value<int>? rowid,
  }) {
    return UsuariosCompanion(
      id: id ?? this.id,
      etiqueta: etiqueta ?? this.etiqueta,
      authUid: authUid ?? this.authUid,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (etiqueta.present) {
      map['etiqueta'] = Variable<String>(etiqueta.value);
    }
    if (authUid.present) {
      map['auth_uid'] = Variable<String>(authUid.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<String>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<String>(actualizadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsuariosCompanion(')
          ..write('id: $id, ')
          ..write('etiqueta: $etiqueta, ')
          ..write('authUid: $authUid, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ValoracionesTable extends Valoraciones
    with TableInfo<$ValoracionesTable, Valoracion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ValoracionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES usuarios (id)',
    ),
  );
  static const VerificationMeta _productoIdMeta = const VerificationMeta(
    'productoId',
  );
  @override
  late final GeneratedColumn<String> productoId = GeneratedColumn<String>(
    'producto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES productos (id)',
    ),
  );
  static const VerificationMeta _gustoMeta = const VerificationMeta('gusto');
  @override
  late final GeneratedColumn<String> gusto = GeneratedColumn<String>(
    'gusto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacionMeta = const VerificationMeta(
    'observacion',
  );
  @override
  late final GeneratedColumn<String> observacion = GeneratedColumn<String>(
    'observacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<String> creadoEn = GeneratedColumn<String>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<String> actualizadoEn = GeneratedColumn<String>(
    'actualizado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    usuarioId,
    productoId,
    gusto,
    observacion,
    creadoEn,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'valoraciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Valoracion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('producto_id')) {
      context.handle(
        _productoIdMeta,
        productoId.isAcceptableOrUnknown(data['producto_id']!, _productoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productoIdMeta);
    }
    if (data.containsKey('gusto')) {
      context.handle(
        _gustoMeta,
        gusto.isAcceptableOrUnknown(data['gusto']!, _gustoMeta),
      );
    }
    if (data.containsKey('observacion')) {
      context.handle(
        _observacionMeta,
        observacion.isAcceptableOrUnknown(
          data['observacion']!,
          _observacionMeta,
        ),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Valoracion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Valoracion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_id'],
      )!,
      productoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_id'],
      )!,
      gusto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gusto'],
      ),
      observacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacion'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $ValoracionesTable createAlias(String alias) {
    return $ValoracionesTable(attachedDatabase, alias);
  }
}

class Valoracion extends DataClass implements Insertable<Valoracion> {
  final String id;
  final String usuarioId;
  final String productoId;

  /// 'si' | 'no' | null (neutro — sin valoración cargada).
  final String? gusto;

  /// Observación personal breve (ej.: "salió bueno", "no repito").
  final String? observacion;
  final String creadoEn;
  final String actualizadoEn;
  const Valoracion({
    required this.id,
    required this.usuarioId,
    required this.productoId,
    this.gusto,
    this.observacion,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['producto_id'] = Variable<String>(productoId);
    if (!nullToAbsent || gusto != null) {
      map['gusto'] = Variable<String>(gusto);
    }
    if (!nullToAbsent || observacion != null) {
      map['observacion'] = Variable<String>(observacion);
    }
    map['creado_en'] = Variable<String>(creadoEn);
    map['actualizado_en'] = Variable<String>(actualizadoEn);
    return map;
  }

  ValoracionesCompanion toCompanion(bool nullToAbsent) {
    return ValoracionesCompanion(
      id: Value(id),
      usuarioId: Value(usuarioId),
      productoId: Value(productoId),
      gusto: gusto == null && nullToAbsent
          ? const Value.absent()
          : Value(gusto),
      observacion: observacion == null && nullToAbsent
          ? const Value.absent()
          : Value(observacion),
      creadoEn: Value(creadoEn),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory Valoracion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Valoracion(
      id: serializer.fromJson<String>(json['id']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      productoId: serializer.fromJson<String>(json['productoId']),
      gusto: serializer.fromJson<String?>(json['gusto']),
      observacion: serializer.fromJson<String?>(json['observacion']),
      creadoEn: serializer.fromJson<String>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<String>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'productoId': serializer.toJson<String>(productoId),
      'gusto': serializer.toJson<String?>(gusto),
      'observacion': serializer.toJson<String?>(observacion),
      'creadoEn': serializer.toJson<String>(creadoEn),
      'actualizadoEn': serializer.toJson<String>(actualizadoEn),
    };
  }

  Valoracion copyWith({
    String? id,
    String? usuarioId,
    String? productoId,
    Value<String?> gusto = const Value.absent(),
    Value<String?> observacion = const Value.absent(),
    String? creadoEn,
    String? actualizadoEn,
  }) => Valoracion(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    productoId: productoId ?? this.productoId,
    gusto: gusto.present ? gusto.value : this.gusto,
    observacion: observacion.present ? observacion.value : this.observacion,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  Valoracion copyWithCompanion(ValoracionesCompanion data) {
    return Valoracion(
      id: data.id.present ? data.id.value : this.id,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      productoId: data.productoId.present
          ? data.productoId.value
          : this.productoId,
      gusto: data.gusto.present ? data.gusto.value : this.gusto,
      observacion: data.observacion.present
          ? data.observacion.value
          : this.observacion,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Valoracion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('productoId: $productoId, ')
          ..write('gusto: $gusto, ')
          ..write('observacion: $observacion, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    usuarioId,
    productoId,
    gusto,
    observacion,
    creadoEn,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Valoracion &&
          other.id == this.id &&
          other.usuarioId == this.usuarioId &&
          other.productoId == this.productoId &&
          other.gusto == this.gusto &&
          other.observacion == this.observacion &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn);
}

class ValoracionesCompanion extends UpdateCompanion<Valoracion> {
  final Value<String> id;
  final Value<String> usuarioId;
  final Value<String> productoId;
  final Value<String?> gusto;
  final Value<String?> observacion;
  final Value<String> creadoEn;
  final Value<String> actualizadoEn;
  final Value<int> rowid;
  const ValoracionesCompanion({
    this.id = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.productoId = const Value.absent(),
    this.gusto = const Value.absent(),
    this.observacion = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ValoracionesCompanion.insert({
    required String id,
    required String usuarioId,
    required String productoId,
    this.gusto = const Value.absent(),
    this.observacion = const Value.absent(),
    required String creadoEn,
    required String actualizadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       usuarioId = Value(usuarioId),
       productoId = Value(productoId),
       creadoEn = Value(creadoEn),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<Valoracion> custom({
    Expression<String>? id,
    Expression<String>? usuarioId,
    Expression<String>? productoId,
    Expression<String>? gusto,
    Expression<String>? observacion,
    Expression<String>? creadoEn,
    Expression<String>? actualizadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (productoId != null) 'producto_id': productoId,
      if (gusto != null) 'gusto': gusto,
      if (observacion != null) 'observacion': observacion,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ValoracionesCompanion copyWith({
    Value<String>? id,
    Value<String>? usuarioId,
    Value<String>? productoId,
    Value<String?>? gusto,
    Value<String?>? observacion,
    Value<String>? creadoEn,
    Value<String>? actualizadoEn,
    Value<int>? rowid,
  }) {
    return ValoracionesCompanion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      productoId: productoId ?? this.productoId,
      gusto: gusto ?? this.gusto,
      observacion: observacion ?? this.observacion,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (productoId.present) {
      map['producto_id'] = Variable<String>(productoId.value);
    }
    if (gusto.present) {
      map['gusto'] = Variable<String>(gusto.value);
    }
    if (observacion.present) {
      map['observacion'] = Variable<String>(observacion.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<String>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<String>(actualizadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ValoracionesCompanion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('productoId: $productoId, ')
          ..write('gusto: $gusto, ')
          ..write('observacion: $observacion, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, EntradaOutbox> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tablaMeta = const VerificationMeta('tabla');
  @override
  late final GeneratedColumn<String> tabla = GeneratedColumn<String>(
    'tabla',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filaIdMeta = const VerificationMeta('filaId');
  @override
  late final GeneratedColumn<String> filaId = GeneratedColumn<String>(
    'fila_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operacionMeta = const VerificationMeta(
    'operacion',
  );
  @override
  late final GeneratedColumn<String> operacion = GeneratedColumn<String>(
    'operacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encoladoEnMeta = const VerificationMeta(
    'encoladoEn',
  );
  @override
  late final GeneratedColumn<String> encoladoEn = GeneratedColumn<String>(
    'encolado_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tabla, filaId, operacion, encoladoEn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntradaOutbox> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tabla')) {
      context.handle(
        _tablaMeta,
        tabla.isAcceptableOrUnknown(data['tabla']!, _tablaMeta),
      );
    } else if (isInserting) {
      context.missing(_tablaMeta);
    }
    if (data.containsKey('fila_id')) {
      context.handle(
        _filaIdMeta,
        filaId.isAcceptableOrUnknown(data['fila_id']!, _filaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_filaIdMeta);
    }
    if (data.containsKey('operacion')) {
      context.handle(
        _operacionMeta,
        operacion.isAcceptableOrUnknown(data['operacion']!, _operacionMeta),
      );
    } else if (isInserting) {
      context.missing(_operacionMeta);
    }
    if (data.containsKey('encolado_en')) {
      context.handle(
        _encoladoEnMeta,
        encoladoEn.isAcceptableOrUnknown(data['encolado_en']!, _encoladoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_encoladoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tabla, filaId};
  @override
  EntradaOutbox map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntradaOutbox(
      tabla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabla'],
      )!,
      filaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fila_id'],
      )!,
      operacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operacion'],
      )!,
      encoladoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encolado_en'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class EntradaOutbox extends DataClass implements Insertable<EntradaOutbox> {
  /// Nombre de tabla remota (snake_case): usuario, articulo, producto,
  /// comercio, precio o valoracion.
  final String tabla;
  final String filaId;
  final String operacion;
  final String encoladoEn;
  const EntradaOutbox({
    required this.tabla,
    required this.filaId,
    required this.operacion,
    required this.encoladoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tabla'] = Variable<String>(tabla);
    map['fila_id'] = Variable<String>(filaId);
    map['operacion'] = Variable<String>(operacion);
    map['encolado_en'] = Variable<String>(encoladoEn);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      tabla: Value(tabla),
      filaId: Value(filaId),
      operacion: Value(operacion),
      encoladoEn: Value(encoladoEn),
    );
  }

  factory EntradaOutbox.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntradaOutbox(
      tabla: serializer.fromJson<String>(json['tabla']),
      filaId: serializer.fromJson<String>(json['filaId']),
      operacion: serializer.fromJson<String>(json['operacion']),
      encoladoEn: serializer.fromJson<String>(json['encoladoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tabla': serializer.toJson<String>(tabla),
      'filaId': serializer.toJson<String>(filaId),
      'operacion': serializer.toJson<String>(operacion),
      'encoladoEn': serializer.toJson<String>(encoladoEn),
    };
  }

  EntradaOutbox copyWith({
    String? tabla,
    String? filaId,
    String? operacion,
    String? encoladoEn,
  }) => EntradaOutbox(
    tabla: tabla ?? this.tabla,
    filaId: filaId ?? this.filaId,
    operacion: operacion ?? this.operacion,
    encoladoEn: encoladoEn ?? this.encoladoEn,
  );
  EntradaOutbox copyWithCompanion(OutboxCompanion data) {
    return EntradaOutbox(
      tabla: data.tabla.present ? data.tabla.value : this.tabla,
      filaId: data.filaId.present ? data.filaId.value : this.filaId,
      operacion: data.operacion.present ? data.operacion.value : this.operacion,
      encoladoEn: data.encoladoEn.present
          ? data.encoladoEn.value
          : this.encoladoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntradaOutbox(')
          ..write('tabla: $tabla, ')
          ..write('filaId: $filaId, ')
          ..write('operacion: $operacion, ')
          ..write('encoladoEn: $encoladoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tabla, filaId, operacion, encoladoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntradaOutbox &&
          other.tabla == this.tabla &&
          other.filaId == this.filaId &&
          other.operacion == this.operacion &&
          other.encoladoEn == this.encoladoEn);
}

class OutboxCompanion extends UpdateCompanion<EntradaOutbox> {
  final Value<String> tabla;
  final Value<String> filaId;
  final Value<String> operacion;
  final Value<String> encoladoEn;
  final Value<int> rowid;
  const OutboxCompanion({
    this.tabla = const Value.absent(),
    this.filaId = const Value.absent(),
    this.operacion = const Value.absent(),
    this.encoladoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String tabla,
    required String filaId,
    required String operacion,
    required String encoladoEn,
    this.rowid = const Value.absent(),
  }) : tabla = Value(tabla),
       filaId = Value(filaId),
       operacion = Value(operacion),
       encoladoEn = Value(encoladoEn);
  static Insertable<EntradaOutbox> custom({
    Expression<String>? tabla,
    Expression<String>? filaId,
    Expression<String>? operacion,
    Expression<String>? encoladoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tabla != null) 'tabla': tabla,
      if (filaId != null) 'fila_id': filaId,
      if (operacion != null) 'operacion': operacion,
      if (encoladoEn != null) 'encolado_en': encoladoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? tabla,
    Value<String>? filaId,
    Value<String>? operacion,
    Value<String>? encoladoEn,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      tabla: tabla ?? this.tabla,
      filaId: filaId ?? this.filaId,
      operacion: operacion ?? this.operacion,
      encoladoEn: encoladoEn ?? this.encoladoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tabla.present) {
      map['tabla'] = Variable<String>(tabla.value);
    }
    if (filaId.present) {
      map['fila_id'] = Variable<String>(filaId.value);
    }
    if (operacion.present) {
      map['operacion'] = Variable<String>(operacion.value);
    }
    if (encoladoEn.present) {
      map['encolado_en'] = Variable<String>(encoladoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('tabla: $tabla, ')
          ..write('filaId: $filaId, ')
          ..write('operacion: $operacion, ')
          ..write('encoladoEn: $encoladoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CursoresSyncTable extends CursoresSync
    with TableInfo<$CursoresSyncTable, CursorSync> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CursoresSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tablaMeta = const VerificationMeta('tabla');
  @override
  late final GeneratedColumn<String> tabla = GeneratedColumn<String>(
    'tabla',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tabla, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cursores_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<CursorSync> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tabla')) {
      context.handle(
        _tablaMeta,
        tabla.isAcceptableOrUnknown(data['tabla']!, _tablaMeta),
      );
    } else if (isInserting) {
      context.missing(_tablaMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tabla};
  @override
  CursorSync map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CursorSync(
      tabla: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabla'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      )!,
    );
  }

  @override
  $CursoresSyncTable createAlias(String alias) {
    return $CursoresSyncTable(attachedDatabase, alias);
  }
}

class CursorSync extends DataClass implements Insertable<CursorSync> {
  final String tabla;
  final String cursor;
  const CursorSync({required this.tabla, required this.cursor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tabla'] = Variable<String>(tabla);
    map['cursor'] = Variable<String>(cursor);
    return map;
  }

  CursoresSyncCompanion toCompanion(bool nullToAbsent) {
    return CursoresSyncCompanion(tabla: Value(tabla), cursor: Value(cursor));
  }

  factory CursorSync.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CursorSync(
      tabla: serializer.fromJson<String>(json['tabla']),
      cursor: serializer.fromJson<String>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tabla': serializer.toJson<String>(tabla),
      'cursor': serializer.toJson<String>(cursor),
    };
  }

  CursorSync copyWith({String? tabla, String? cursor}) =>
      CursorSync(tabla: tabla ?? this.tabla, cursor: cursor ?? this.cursor);
  CursorSync copyWithCompanion(CursoresSyncCompanion data) {
    return CursorSync(
      tabla: data.tabla.present ? data.tabla.value : this.tabla,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CursorSync(')
          ..write('tabla: $tabla, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tabla, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CursorSync &&
          other.tabla == this.tabla &&
          other.cursor == this.cursor);
}

class CursoresSyncCompanion extends UpdateCompanion<CursorSync> {
  final Value<String> tabla;
  final Value<String> cursor;
  final Value<int> rowid;
  const CursoresSyncCompanion({
    this.tabla = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CursoresSyncCompanion.insert({
    required String tabla,
    required String cursor,
    this.rowid = const Value.absent(),
  }) : tabla = Value(tabla),
       cursor = Value(cursor);
  static Insertable<CursorSync> custom({
    Expression<String>? tabla,
    Expression<String>? cursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tabla != null) 'tabla': tabla,
      if (cursor != null) 'cursor': cursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CursoresSyncCompanion copyWith({
    Value<String>? tabla,
    Value<String>? cursor,
    Value<int>? rowid,
  }) {
    return CursoresSyncCompanion(
      tabla: tabla ?? this.tabla,
      cursor: cursor ?? this.cursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tabla.present) {
      map['tabla'] = Variable<String>(tabla.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CursoresSyncCompanion(')
          ..write('tabla: $tabla, ')
          ..write('cursor: $cursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EstadoSyncTable extends EstadoSync
    with TableInfo<$EstadoSyncTable, EstadoSyncData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstadoSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimoSyncExitosoMeta = const VerificationMeta(
    'ultimoSyncExitoso',
  );
  @override
  late final GeneratedColumn<String> ultimoSyncExitoso =
      GeneratedColumn<String>(
        'ultimo_sync_exitoso',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, ultimoSyncExitoso];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'estado_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<EstadoSyncData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ultimo_sync_exitoso')) {
      context.handle(
        _ultimoSyncExitosoMeta,
        ultimoSyncExitoso.isAcceptableOrUnknown(
          data['ultimo_sync_exitoso']!,
          _ultimoSyncExitosoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EstadoSyncData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EstadoSyncData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ultimoSyncExitoso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_sync_exitoso'],
      ),
    );
  }

  @override
  $EstadoSyncTable createAlias(String alias) {
    return $EstadoSyncTable(attachedDatabase, alias);
  }
}

class EstadoSyncData extends DataClass implements Insertable<EstadoSyncData> {
  /// Fila única: id 'global'.
  final String id;
  final String? ultimoSyncExitoso;
  const EstadoSyncData({required this.id, this.ultimoSyncExitoso});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ultimoSyncExitoso != null) {
      map['ultimo_sync_exitoso'] = Variable<String>(ultimoSyncExitoso);
    }
    return map;
  }

  EstadoSyncCompanion toCompanion(bool nullToAbsent) {
    return EstadoSyncCompanion(
      id: Value(id),
      ultimoSyncExitoso: ultimoSyncExitoso == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoSyncExitoso),
    );
  }

  factory EstadoSyncData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EstadoSyncData(
      id: serializer.fromJson<String>(json['id']),
      ultimoSyncExitoso: serializer.fromJson<String?>(
        json['ultimoSyncExitoso'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ultimoSyncExitoso': serializer.toJson<String?>(ultimoSyncExitoso),
    };
  }

  EstadoSyncData copyWith({
    String? id,
    Value<String?> ultimoSyncExitoso = const Value.absent(),
  }) => EstadoSyncData(
    id: id ?? this.id,
    ultimoSyncExitoso: ultimoSyncExitoso.present
        ? ultimoSyncExitoso.value
        : this.ultimoSyncExitoso,
  );
  EstadoSyncData copyWithCompanion(EstadoSyncCompanion data) {
    return EstadoSyncData(
      id: data.id.present ? data.id.value : this.id,
      ultimoSyncExitoso: data.ultimoSyncExitoso.present
          ? data.ultimoSyncExitoso.value
          : this.ultimoSyncExitoso,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EstadoSyncData(')
          ..write('id: $id, ')
          ..write('ultimoSyncExitoso: $ultimoSyncExitoso')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ultimoSyncExitoso);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EstadoSyncData &&
          other.id == this.id &&
          other.ultimoSyncExitoso == this.ultimoSyncExitoso);
}

class EstadoSyncCompanion extends UpdateCompanion<EstadoSyncData> {
  final Value<String> id;
  final Value<String?> ultimoSyncExitoso;
  final Value<int> rowid;
  const EstadoSyncCompanion({
    this.id = const Value.absent(),
    this.ultimoSyncExitoso = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EstadoSyncCompanion.insert({
    required String id,
    this.ultimoSyncExitoso = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<EstadoSyncData> custom({
    Expression<String>? id,
    Expression<String>? ultimoSyncExitoso,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ultimoSyncExitoso != null) 'ultimo_sync_exitoso': ultimoSyncExitoso,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EstadoSyncCompanion copyWith({
    Value<String>? id,
    Value<String?>? ultimoSyncExitoso,
    Value<int>? rowid,
  }) {
    return EstadoSyncCompanion(
      id: id ?? this.id,
      ultimoSyncExitoso: ultimoSyncExitoso ?? this.ultimoSyncExitoso,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ultimoSyncExitoso.present) {
      map['ultimo_sync_exitoso'] = Variable<String>(ultimoSyncExitoso.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstadoSyncCompanion(')
          ..write('id: $id, ')
          ..write('ultimoSyncExitoso: $ultimoSyncExitoso, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseDeDatos extends GeneratedDatabase {
  _$BaseDeDatos(QueryExecutor e) : super(e);
  $BaseDeDatosManager get managers => $BaseDeDatosManager(this);
  late final $ArticulosTable articulos = $ArticulosTable(this);
  late final $ProductosTable productos = $ProductosTable(this);
  late final $ComerciosTable comercios = $ComerciosTable(this);
  late final $PreciosTable precios = $PreciosTable(this);
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $ValoracionesTable valoraciones = $ValoracionesTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $CursoresSyncTable cursoresSync = $CursoresSyncTable(this);
  late final $EstadoSyncTable estadoSync = $EstadoSyncTable(this);
  late final Index idxArticuloNombre = Index(
    'idx_articulo_nombre',
    'CREATE INDEX idx_articulo_nombre ON articulos (nombre)',
  );
  late final Index idxProductoNombre = Index(
    'idx_producto_nombre',
    'CREATE INDEX idx_producto_nombre ON productos (nombre)',
  );
  late final Index idxProductoMarca = Index(
    'idx_producto_marca',
    'CREATE INDEX idx_producto_marca ON productos (marca)',
  );
  late final Index idxProductoArticulo = Index(
    'idx_producto_articulo',
    'CREATE INDEX idx_producto_articulo ON productos (articulo_id)',
  );
  late final Index idxComercioNombre = Index(
    'idx_comercio_nombre',
    'CREATE INDEX idx_comercio_nombre ON comercios (nombre)',
  );
  late final Index idxPrecioProductoFecha = Index(
    'idx_precio_producto_fecha',
    'CREATE INDEX idx_precio_producto_fecha ON precios (producto_id, fecha_toma)',
  );
  late final Index idxPrecioFecha = Index(
    'idx_precio_fecha',
    'CREATE INDEX idx_precio_fecha ON precios (fecha_toma)',
  );
  late final Index idxValoracionProducto = Index(
    'idx_valoracion_producto',
    'CREATE INDEX idx_valoracion_producto ON valoraciones (producto_id)',
  );
  late final Index idxValoracionUsuario = Index(
    'idx_valoracion_usuario',
    'CREATE INDEX idx_valoracion_usuario ON valoraciones (usuario_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    articulos,
    productos,
    comercios,
    precios,
    usuarios,
    valoraciones,
    outbox,
    cursoresSync,
    estadoSync,
    idxArticuloNombre,
    idxProductoNombre,
    idxProductoMarca,
    idxProductoArticulo,
    idxComercioNombre,
    idxPrecioProductoFecha,
    idxPrecioFecha,
    idxValoracionProducto,
    idxValoracionUsuario,
  ];
}

typedef $$ArticulosTableCreateCompanionBuilder = ArticulosCompanion Function({
  required String id,
  required String nombre,
  Value<String?> categoria,
  required String unidadBase,
  required String creadoPor,
  required String creadoEn,
  required String actualizadoEn,
  Value<String?> borradoEn,
  Value<int> rowid,
});
typedef $$ArticulosTableUpdateCompanionBuilder = ArticulosCompanion Function({
  Value<String> id,
  Value<String> nombre,
  Value<String?> categoria,
  Value<String> unidadBase,
  Value<String> creadoPor,
  Value<String> creadoEn,
  Value<String> actualizadoEn,
  Value<String?> borradoEn,
  Value<int> rowid,
});

final class $$ArticulosTableReferences
    extends BaseReferences<_$BaseDeDatos, $ArticulosTable, Articulo> {
  $$ArticulosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductosTable, List<Producto>>
  _productosRefsTable(_$BaseDeDatos db) => MultiTypedResultKey.fromTable(
    db.productos,
    aliasName: 'articulos__id__productos__articulo_id',
  );

  $$ProductosTableProcessedTableManager get productosRefs {
    final manager = $$ProductosTableTableManager(
      $_db,
      $_db.productos,
    ).filter((f) => f.articuloId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArticulosTableFilterComposer
    extends Composer<_$BaseDeDatos, $ArticulosTable> {
  $$ArticulosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidadBase => $composableBuilder(
    column: $table.unidadBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoPor => $composableBuilder(
    column: $table.creadoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borradoEn => $composableBuilder(
    column: $table.borradoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productosRefs(
    Expression<bool> Function($$ProductosTableFilterComposer f) f,
  ) {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.articuloId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArticulosTableOrderingComposer
    extends Composer<_$BaseDeDatos, $ArticulosTable> {
  $$ArticulosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidadBase => $composableBuilder(
    column: $table.unidadBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoPor => $composableBuilder(
    column: $table.creadoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borradoEn => $composableBuilder(
    column: $table.borradoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArticulosTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $ArticulosTable> {
  $$ArticulosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get unidadBase => $composableBuilder(
    column: $table.unidadBase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creadoPor =>
      $composableBuilder(column: $table.creadoPor, builder: (column) => column);

  GeneratedColumn<String> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get borradoEn =>
      $composableBuilder(column: $table.borradoEn, builder: (column) => column);

  Expression<T> productosRefs<T extends Object>(
    Expression<T> Function($$ProductosTableAnnotationComposer a) f,
  ) {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.articuloId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArticulosTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $ArticulosTable,
          Articulo,
          $$ArticulosTableFilterComposer,
          $$ArticulosTableOrderingComposer,
          $$ArticulosTableAnnotationComposer,
          $$ArticulosTableCreateCompanionBuilder,
          $$ArticulosTableUpdateCompanionBuilder,
          (Articulo, $$ArticulosTableReferences),
          Articulo,
          PrefetchHooks Function({bool productosRefs})
        > {
  $$ArticulosTableTableManager(_$BaseDeDatos db, $ArticulosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticulosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticulosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticulosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                Value<String> unidadBase = const Value.absent(),
                Value<String> creadoPor = const Value.absent(),
                Value<String> creadoEn = const Value.absent(),
                Value<String> actualizadoEn = const Value.absent(),
                Value<String?> borradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticulosCompanion(
                id: id,
                nombre: nombre,
                categoria: categoria,
                unidadBase: unidadBase,
                creadoPor: creadoPor,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                borradoEn: borradoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                Value<String?> categoria = const Value.absent(),
                required String unidadBase,
                required String creadoPor,
                required String creadoEn,
                required String actualizadoEn,
                Value<String?> borradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticulosCompanion.insert(
                id: id,
                nombre: nombre,
                categoria: categoria,
                unidadBase: unidadBase,
                creadoPor: creadoPor,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                borradoEn: borradoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArticulosTable, Articulo>(table),
                  $$ArticulosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productosRefs) db.productos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productosRefs)
                    await $_getPrefetchedDataByColumns<
                      Articulo,
                      $ArticulosTable,
                      Producto,
                      $ProductosTable
                    >(
                      currentTable: table,
                      referencedTable: $$ArticulosTableReferences
                          ._productosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ArticulosTableReferences(
                            db,
                            table,
                            p0,
                          ).productosRefs,
                      currentColumn: 'id',
                      referencedColumn: 'articulo_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ArticulosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $ArticulosTable,
      Articulo,
      $$ArticulosTableFilterComposer,
      $$ArticulosTableOrderingComposer,
      $$ArticulosTableAnnotationComposer,
      $$ArticulosTableCreateCompanionBuilder,
      $$ArticulosTableUpdateCompanionBuilder,
      (Articulo, $$ArticulosTableReferences),
      Articulo,
      PrefetchHooks Function({bool productosRefs})
    >;
typedef $$ProductosTableCreateCompanionBuilder = ProductosCompanion Function({
  required String id,
  Value<String?> codigoBarras,
  Value<String?> articuloId,
  required String nombre,
  Value<String?> marca,
  Value<String?> categoria,
  required String unidad,
  Value<double?> contenidoNeto,
  Value<String?> origen,
  Value<String?> notas,
  required String creadoPor,
  required String creadoEn,
  required String actualizadoEn,
  Value<String?> borradoEn,
  Value<int> rowid,
});
typedef $$ProductosTableUpdateCompanionBuilder = ProductosCompanion Function({
  Value<String> id,
  Value<String?> codigoBarras,
  Value<String?> articuloId,
  Value<String> nombre,
  Value<String?> marca,
  Value<String?> categoria,
  Value<String> unidad,
  Value<double?> contenidoNeto,
  Value<String?> origen,
  Value<String?> notas,
  Value<String> creadoPor,
  Value<String> creadoEn,
  Value<String> actualizadoEn,
  Value<String?> borradoEn,
  Value<int> rowid,
});

final class $$ProductosTableReferences
    extends BaseReferences<_$BaseDeDatos, $ProductosTable, Producto> {
  $$ProductosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArticulosTable _articuloIdTable(_$BaseDeDatos db) =>
      db.articulos.createAlias('productos__articulo_id__articulos__id');

  $$ArticulosTableProcessedTableManager? get articuloId {
    final $_column = $_itemColumn<String>('articulo_id');
    if ($_column == null) return null;
    final manager = $$ArticulosTableTableManager(
      $_db,
      $_db.articulos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_articuloIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PreciosTable, List<Precio>> _preciosRefsTable(
    _$BaseDeDatos db,
  ) => MultiTypedResultKey.fromTable(
    db.precios,
    aliasName: 'productos__id__precios__producto_id',
  );

  $$PreciosTableProcessedTableManager get preciosRefs {
    final manager = $$PreciosTableTableManager(
      $_db,
      $_db.precios,
    ).filter((f) => f.productoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_preciosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ValoracionesTable, List<Valoracion>>
  _valoracionesRefsTable(_$BaseDeDatos db) => MultiTypedResultKey.fromTable(
    db.valoraciones,
    aliasName: 'productos__id__valoraciones__producto_id',
  );

  $$ValoracionesTableProcessedTableManager get valoracionesRefs {
    final manager = $$ValoracionesTableTableManager(
      $_db,
      $_db.valoraciones,
    ).filter((f) => f.productoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_valoracionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductosTableFilterComposer
    extends Composer<_$BaseDeDatos, $ProductosTable> {
  $$ProductosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get contenidoNeto => $composableBuilder(
    column: $table.contenidoNeto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoPor => $composableBuilder(
    column: $table.creadoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borradoEn => $composableBuilder(
    column: $table.borradoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$ArticulosTableFilterComposer get articuloId {
    final $$ArticulosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articuloId,
      referencedTable: $db.articulos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticulosTableFilterComposer(
            $db: $db,
            $table: $db.articulos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> preciosRefs(
    Expression<bool> Function($$PreciosTableFilterComposer f) f,
  ) {
    final $$PreciosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.precios,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PreciosTableFilterComposer(
            $db: $db,
            $table: $db.precios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> valoracionesRefs(
    Expression<bool> Function($$ValoracionesTableFilterComposer f) f,
  ) {
    final $$ValoracionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.valoraciones,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ValoracionesTableFilterComposer(
            $db: $db,
            $table: $db.valoraciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductosTableOrderingComposer
    extends Composer<_$BaseDeDatos, $ProductosTable> {
  $$ProductosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get contenidoNeto => $composableBuilder(
    column: $table.contenidoNeto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoPor => $composableBuilder(
    column: $table.creadoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borradoEn => $composableBuilder(
    column: $table.borradoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArticulosTableOrderingComposer get articuloId {
    final $$ArticulosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articuloId,
      referencedTable: $db.articulos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticulosTableOrderingComposer(
            $db: $db,
            $table: $db.articulos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductosTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $ProductosTable> {
  $$ProductosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codigoBarras => $composableBuilder(
    column: $table.codigoBarras,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get unidad =>
      $composableBuilder(column: $table.unidad, builder: (column) => column);

  GeneratedColumn<double> get contenidoNeto => $composableBuilder(
    column: $table.contenidoNeto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origen =>
      $composableBuilder(column: $table.origen, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<String> get creadoPor =>
      $composableBuilder(column: $table.creadoPor, builder: (column) => column);

  GeneratedColumn<String> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get borradoEn =>
      $composableBuilder(column: $table.borradoEn, builder: (column) => column);

  $$ArticulosTableAnnotationComposer get articuloId {
    final $$ArticulosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articuloId,
      referencedTable: $db.articulos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticulosTableAnnotationComposer(
            $db: $db,
            $table: $db.articulos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> preciosRefs<T extends Object>(
    Expression<T> Function($$PreciosTableAnnotationComposer a) f,
  ) {
    final $$PreciosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.precios,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PreciosTableAnnotationComposer(
            $db: $db,
            $table: $db.precios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> valoracionesRefs<T extends Object>(
    Expression<T> Function($$ValoracionesTableAnnotationComposer a) f,
  ) {
    final $$ValoracionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.valoraciones,
      getReferencedColumn: (t) => t.productoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ValoracionesTableAnnotationComposer(
            $db: $db,
            $table: $db.valoraciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductosTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $ProductosTable,
          Producto,
          $$ProductosTableFilterComposer,
          $$ProductosTableOrderingComposer,
          $$ProductosTableAnnotationComposer,
          $$ProductosTableCreateCompanionBuilder,
          $$ProductosTableUpdateCompanionBuilder,
          (Producto, $$ProductosTableReferences),
          Producto,
          PrefetchHooks Function({
            bool articuloId,
            bool preciosRefs,
            bool valoracionesRefs,
          })
        > {
  $$ProductosTableTableManager(_$BaseDeDatos db, $ProductosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> codigoBarras = const Value.absent(),
                Value<String?> articuloId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> marca = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                Value<String> unidad = const Value.absent(),
                Value<double?> contenidoNeto = const Value.absent(),
                Value<String?> origen = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<String> creadoPor = const Value.absent(),
                Value<String> creadoEn = const Value.absent(),
                Value<String> actualizadoEn = const Value.absent(),
                Value<String?> borradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion(
                id: id,
                codigoBarras: codigoBarras,
                articuloId: articuloId,
                nombre: nombre,
                marca: marca,
                categoria: categoria,
                unidad: unidad,
                contenidoNeto: contenidoNeto,
                origen: origen,
                notas: notas,
                creadoPor: creadoPor,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                borradoEn: borradoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> codigoBarras = const Value.absent(),
                Value<String?> articuloId = const Value.absent(),
                required String nombre,
                Value<String?> marca = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                required String unidad,
                Value<double?> contenidoNeto = const Value.absent(),
                Value<String?> origen = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                required String creadoPor,
                required String creadoEn,
                required String actualizadoEn,
                Value<String?> borradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion.insert(
                id: id,
                codigoBarras: codigoBarras,
                articuloId: articuloId,
                nombre: nombre,
                marca: marca,
                categoria: categoria,
                unidad: unidad,
                contenidoNeto: contenidoNeto,
                origen: origen,
                notas: notas,
                creadoPor: creadoPor,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                borradoEn: borradoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductosTable, Producto>(table),
                  $$ProductosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                articuloId = false,
                preciosRefs = false,
                valoracionesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (preciosRefs) db.precios,
                    if (valoracionesRefs) db.valoraciones,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (articuloId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.articuloId,
                            referencedTable: $$ProductosTableReferences
                                ._articuloIdTable(db),
                            referencedColumn: $$ProductosTableReferences
                                ._articuloIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (preciosRefs)
                        await $_getPrefetchedDataByColumns<
                          Producto,
                          $ProductosTable,
                          Precio,
                          $PreciosTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProductosTableReferences
                              ._preciosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductosTableReferences(
                                db,
                                table,
                                p0,
                              ).preciosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'producto_id',
                          typedResults: items,
                        ),
                      if (valoracionesRefs)
                        await $_getPrefetchedDataByColumns<
                          Producto,
                          $ProductosTable,
                          Valoracion,
                          $ValoracionesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProductosTableReferences
                              ._valoracionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductosTableReferences(
                                db,
                                table,
                                p0,
                              ).valoracionesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'producto_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $ProductosTable,
      Producto,
      $$ProductosTableFilterComposer,
      $$ProductosTableOrderingComposer,
      $$ProductosTableAnnotationComposer,
      $$ProductosTableCreateCompanionBuilder,
      $$ProductosTableUpdateCompanionBuilder,
      (Producto, $$ProductosTableReferences),
      Producto,
      PrefetchHooks Function({
        bool articuloId,
        bool preciosRefs,
        bool valoracionesRefs,
      })
    >;
typedef $$ComerciosTableCreateCompanionBuilder = ComerciosCompanion Function({
  required String id,
  required String nombre,
  Value<String?> tipo,
  Value<String?> direccion,
  required String creadoPor,
  required String creadoEn,
  required String actualizadoEn,
  Value<String?> borradoEn,
  Value<int> rowid,
});
typedef $$ComerciosTableUpdateCompanionBuilder = ComerciosCompanion Function({
  Value<String> id,
  Value<String> nombre,
  Value<String?> tipo,
  Value<String?> direccion,
  Value<String> creadoPor,
  Value<String> creadoEn,
  Value<String> actualizadoEn,
  Value<String?> borradoEn,
  Value<int> rowid,
});

final class $$ComerciosTableReferences
    extends BaseReferences<_$BaseDeDatos, $ComerciosTable, Comercio> {
  $$ComerciosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PreciosTable, List<Precio>> _preciosRefsTable(
    _$BaseDeDatos db,
  ) => MultiTypedResultKey.fromTable(
    db.precios,
    aliasName: 'comercios__id__precios__comercio_id',
  );

  $$PreciosTableProcessedTableManager get preciosRefs {
    final manager = $$PreciosTableTableManager(
      $_db,
      $_db.precios,
    ).filter((f) => f.comercioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_preciosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ComerciosTableFilterComposer
    extends Composer<_$BaseDeDatos, $ComerciosTable> {
  $$ComerciosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoPor => $composableBuilder(
    column: $table.creadoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borradoEn => $composableBuilder(
    column: $table.borradoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> preciosRefs(
    Expression<bool> Function($$PreciosTableFilterComposer f) f,
  ) {
    final $$PreciosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.precios,
      getReferencedColumn: (t) => t.comercioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PreciosTableFilterComposer(
            $db: $db,
            $table: $db.precios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComerciosTableOrderingComposer
    extends Composer<_$BaseDeDatos, $ComerciosTable> {
  $$ComerciosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoPor => $composableBuilder(
    column: $table.creadoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borradoEn => $composableBuilder(
    column: $table.borradoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComerciosTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $ComerciosTable> {
  $$ComerciosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get direccion =>
      $composableBuilder(column: $table.direccion, builder: (column) => column);

  GeneratedColumn<String> get creadoPor =>
      $composableBuilder(column: $table.creadoPor, builder: (column) => column);

  GeneratedColumn<String> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get borradoEn =>
      $composableBuilder(column: $table.borradoEn, builder: (column) => column);

  Expression<T> preciosRefs<T extends Object>(
    Expression<T> Function($$PreciosTableAnnotationComposer a) f,
  ) {
    final $$PreciosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.precios,
      getReferencedColumn: (t) => t.comercioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PreciosTableAnnotationComposer(
            $db: $db,
            $table: $db.precios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComerciosTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $ComerciosTable,
          Comercio,
          $$ComerciosTableFilterComposer,
          $$ComerciosTableOrderingComposer,
          $$ComerciosTableAnnotationComposer,
          $$ComerciosTableCreateCompanionBuilder,
          $$ComerciosTableUpdateCompanionBuilder,
          (Comercio, $$ComerciosTableReferences),
          Comercio,
          PrefetchHooks Function({bool preciosRefs})
        > {
  $$ComerciosTableTableManager(_$BaseDeDatos db, $ComerciosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComerciosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComerciosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComerciosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> tipo = const Value.absent(),
                Value<String?> direccion = const Value.absent(),
                Value<String> creadoPor = const Value.absent(),
                Value<String> creadoEn = const Value.absent(),
                Value<String> actualizadoEn = const Value.absent(),
                Value<String?> borradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComerciosCompanion(
                id: id,
                nombre: nombre,
                tipo: tipo,
                direccion: direccion,
                creadoPor: creadoPor,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                borradoEn: borradoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                Value<String?> tipo = const Value.absent(),
                Value<String?> direccion = const Value.absent(),
                required String creadoPor,
                required String creadoEn,
                required String actualizadoEn,
                Value<String?> borradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComerciosCompanion.insert(
                id: id,
                nombre: nombre,
                tipo: tipo,
                direccion: direccion,
                creadoPor: creadoPor,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                borradoEn: borradoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ComerciosTable, Comercio>(table),
                  $$ComerciosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({preciosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (preciosRefs) db.precios],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (preciosRefs)
                    await $_getPrefetchedDataByColumns<
                      Comercio,
                      $ComerciosTable,
                      Precio,
                      $PreciosTable
                    >(
                      currentTable: table,
                      referencedTable: $$ComerciosTableReferences
                          ._preciosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ComerciosTableReferences(db, table, p0).preciosRefs,
                      currentColumn: 'id',
                      referencedColumn: 'comercio_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ComerciosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $ComerciosTable,
      Comercio,
      $$ComerciosTableFilterComposer,
      $$ComerciosTableOrderingComposer,
      $$ComerciosTableAnnotationComposer,
      $$ComerciosTableCreateCompanionBuilder,
      $$ComerciosTableUpdateCompanionBuilder,
      (Comercio, $$ComerciosTableReferences),
      Comercio,
      PrefetchHooks Function({bool preciosRefs})
    >;
typedef $$PreciosTableCreateCompanionBuilder = PreciosCompanion Function({
  required String id,
  required String productoId,
  required String comercioId,
  required double precio,
  required String fechaToma,
  required String cargadoPor,
  required String cargadoEn,
  Value<int> rowid,
});
typedef $$PreciosTableUpdateCompanionBuilder = PreciosCompanion Function({
  Value<String> id,
  Value<String> productoId,
  Value<String> comercioId,
  Value<double> precio,
  Value<String> fechaToma,
  Value<String> cargadoPor,
  Value<String> cargadoEn,
  Value<int> rowid,
});

final class $$PreciosTableReferences
    extends BaseReferences<_$BaseDeDatos, $PreciosTable, Precio> {
  $$PreciosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductosTable _productoIdTable(_$BaseDeDatos db) =>
      db.productos.createAlias('precios__producto_id__productos__id');

  $$ProductosTableProcessedTableManager get productoId {
    final $_column = $_itemColumn<String>('producto_id')!;

    final manager = $$ProductosTableTableManager(
      $_db,
      $_db.productos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ComerciosTable _comercioIdTable(_$BaseDeDatos db) =>
      db.comercios.createAlias('precios__comercio_id__comercios__id');

  $$ComerciosTableProcessedTableManager get comercioId {
    final $_column = $_itemColumn<String>('comercio_id')!;

    final manager = $$ComerciosTableTableManager(
      $_db,
      $_db.comercios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comercioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PreciosTableFilterComposer
    extends Composer<_$BaseDeDatos, $PreciosTable> {
  $$PreciosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precio => $composableBuilder(
    column: $table.precio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaToma => $composableBuilder(
    column: $table.fechaToma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cargadoPor => $composableBuilder(
    column: $table.cargadoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cargadoEn => $composableBuilder(
    column: $table.cargadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductosTableFilterComposer get productoId {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComerciosTableFilterComposer get comercioId {
    final $$ComerciosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comercioId,
      referencedTable: $db.comercios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComerciosTableFilterComposer(
            $db: $db,
            $table: $db.comercios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreciosTableOrderingComposer
    extends Composer<_$BaseDeDatos, $PreciosTable> {
  $$PreciosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precio => $composableBuilder(
    column: $table.precio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaToma => $composableBuilder(
    column: $table.fechaToma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cargadoPor => $composableBuilder(
    column: $table.cargadoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cargadoEn => $composableBuilder(
    column: $table.cargadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductosTableOrderingComposer get productoId {
    final $$ProductosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableOrderingComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComerciosTableOrderingComposer get comercioId {
    final $$ComerciosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comercioId,
      referencedTable: $db.comercios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComerciosTableOrderingComposer(
            $db: $db,
            $table: $db.comercios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreciosTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $PreciosTable> {
  $$PreciosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get precio =>
      $composableBuilder(column: $table.precio, builder: (column) => column);

  GeneratedColumn<String> get fechaToma =>
      $composableBuilder(column: $table.fechaToma, builder: (column) => column);

  GeneratedColumn<String> get cargadoPor => $composableBuilder(
    column: $table.cargadoPor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cargadoEn =>
      $composableBuilder(column: $table.cargadoEn, builder: (column) => column);

  $$ProductosTableAnnotationComposer get productoId {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComerciosTableAnnotationComposer get comercioId {
    final $$ComerciosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comercioId,
      referencedTable: $db.comercios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComerciosTableAnnotationComposer(
            $db: $db,
            $table: $db.comercios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreciosTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $PreciosTable,
          Precio,
          $$PreciosTableFilterComposer,
          $$PreciosTableOrderingComposer,
          $$PreciosTableAnnotationComposer,
          $$PreciosTableCreateCompanionBuilder,
          $$PreciosTableUpdateCompanionBuilder,
          (Precio, $$PreciosTableReferences),
          Precio,
          PrefetchHooks Function({bool productoId, bool comercioId})
        > {
  $$PreciosTableTableManager(_$BaseDeDatos db, $PreciosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreciosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreciosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreciosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productoId = const Value.absent(),
                Value<String> comercioId = const Value.absent(),
                Value<double> precio = const Value.absent(),
                Value<String> fechaToma = const Value.absent(),
                Value<String> cargadoPor = const Value.absent(),
                Value<String> cargadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreciosCompanion(
                id: id,
                productoId: productoId,
                comercioId: comercioId,
                precio: precio,
                fechaToma: fechaToma,
                cargadoPor: cargadoPor,
                cargadoEn: cargadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productoId,
                required String comercioId,
                required double precio,
                required String fechaToma,
                required String cargadoPor,
                required String cargadoEn,
                Value<int> rowid = const Value.absent(),
              }) => PreciosCompanion.insert(
                id: id,
                productoId: productoId,
                comercioId: comercioId,
                precio: precio,
                fechaToma: fechaToma,
                cargadoPor: cargadoPor,
                cargadoEn: cargadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreciosTable, Precio>(table),
                  $$PreciosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productoId = false, comercioId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productoId,
                        referencedTable: $$PreciosTableReferences
                            ._productoIdTable(db),
                        referencedColumn: $$PreciosTableReferences
                            ._productoIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (comercioId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.comercioId,
                        referencedTable: $$PreciosTableReferences
                            ._comercioIdTable(db),
                        referencedColumn: $$PreciosTableReferences
                            ._comercioIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PreciosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $PreciosTable,
      Precio,
      $$PreciosTableFilterComposer,
      $$PreciosTableOrderingComposer,
      $$PreciosTableAnnotationComposer,
      $$PreciosTableCreateCompanionBuilder,
      $$PreciosTableUpdateCompanionBuilder,
      (Precio, $$PreciosTableReferences),
      Precio,
      PrefetchHooks Function({bool productoId, bool comercioId})
    >;
typedef $$UsuariosTableCreateCompanionBuilder = UsuariosCompanion Function({
  required String id,
  required String etiqueta,
  Value<String?> authUid,
  required String creadoEn,
  required String actualizadoEn,
  Value<int> rowid,
});
typedef $$UsuariosTableUpdateCompanionBuilder = UsuariosCompanion Function({
  Value<String> id,
  Value<String> etiqueta,
  Value<String?> authUid,
  Value<String> creadoEn,
  Value<String> actualizadoEn,
  Value<int> rowid,
});

final class $$UsuariosTableReferences
    extends BaseReferences<_$BaseDeDatos, $UsuariosTable, Usuario> {
  $$UsuariosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ValoracionesTable, List<Valoracion>>
  _valoracionesRefsTable(_$BaseDeDatos db) => MultiTypedResultKey.fromTable(
    db.valoraciones,
    aliasName: 'usuarios__id__valoraciones__usuario_id',
  );

  $$ValoracionesTableProcessedTableManager get valoracionesRefs {
    final manager = $$ValoracionesTableTableManager(
      $_db,
      $_db.valoraciones,
    ).filter((f) => f.usuarioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_valoracionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsuariosTableFilterComposer
    extends Composer<_$BaseDeDatos, $UsuariosTable> {
  $$UsuariosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etiqueta => $composableBuilder(
    column: $table.etiqueta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authUid => $composableBuilder(
    column: $table.authUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> valoracionesRefs(
    Expression<bool> Function($$ValoracionesTableFilterComposer f) f,
  ) {
    final $$ValoracionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.valoraciones,
      getReferencedColumn: (t) => t.usuarioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ValoracionesTableFilterComposer(
            $db: $db,
            $table: $db.valoraciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsuariosTableOrderingComposer
    extends Composer<_$BaseDeDatos, $UsuariosTable> {
  $$UsuariosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etiqueta => $composableBuilder(
    column: $table.etiqueta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authUid => $composableBuilder(
    column: $table.authUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsuariosTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $UsuariosTable> {
  $$UsuariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get etiqueta =>
      $composableBuilder(column: $table.etiqueta, builder: (column) => column);

  GeneratedColumn<String> get authUid =>
      $composableBuilder(column: $table.authUid, builder: (column) => column);

  GeneratedColumn<String> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  Expression<T> valoracionesRefs<T extends Object>(
    Expression<T> Function($$ValoracionesTableAnnotationComposer a) f,
  ) {
    final $$ValoracionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.valoraciones,
      getReferencedColumn: (t) => t.usuarioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ValoracionesTableAnnotationComposer(
            $db: $db,
            $table: $db.valoraciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $UsuariosTable,
          Usuario,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (Usuario, $$UsuariosTableReferences),
          Usuario,
          PrefetchHooks Function({bool valoracionesRefs})
        > {
  $$UsuariosTableTableManager(_$BaseDeDatos db, $UsuariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsuariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsuariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsuariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> etiqueta = const Value.absent(),
                Value<String?> authUid = const Value.absent(),
                Value<String> creadoEn = const Value.absent(),
                Value<String> actualizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                id: id,
                etiqueta: etiqueta,
                authUid: authUid,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String etiqueta,
                Value<String?> authUid = const Value.absent(),
                required String creadoEn,
                required String actualizadoEn,
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                id: id,
                etiqueta: etiqueta,
                authUid: authUid,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsuariosTable, Usuario>(table),
                  $$UsuariosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({valoracionesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (valoracionesRefs) db.valoraciones],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (valoracionesRefs)
                    await $_getPrefetchedDataByColumns<
                      Usuario,
                      $UsuariosTable,
                      Valoracion,
                      $ValoracionesTable
                    >(
                      currentTable: table,
                      referencedTable: $$UsuariosTableReferences
                          ._valoracionesRefsTable(db),
                      managerFromTypedResult: (p0) => $$UsuariosTableReferences(
                        db,
                        table,
                        p0,
                      ).valoracionesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'usuario_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $UsuariosTable,
      Usuario,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (Usuario, $$UsuariosTableReferences),
      Usuario,
      PrefetchHooks Function({bool valoracionesRefs})
    >;
typedef $$ValoracionesTableCreateCompanionBuilder =
    ValoracionesCompanion Function({
      required String id,
      required String usuarioId,
      required String productoId,
      Value<String?> gusto,
      Value<String?> observacion,
      required String creadoEn,
      required String actualizadoEn,
      Value<int> rowid,
    });
typedef $$ValoracionesTableUpdateCompanionBuilder =
    ValoracionesCompanion Function({
      Value<String> id,
      Value<String> usuarioId,
      Value<String> productoId,
      Value<String?> gusto,
      Value<String?> observacion,
      Value<String> creadoEn,
      Value<String> actualizadoEn,
      Value<int> rowid,
    });

final class $$ValoracionesTableReferences
    extends BaseReferences<_$BaseDeDatos, $ValoracionesTable, Valoracion> {
  $$ValoracionesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsuariosTable _usuarioIdTable(_$BaseDeDatos db) =>
      db.usuarios.createAlias('valoraciones__usuario_id__usuarios__id');

  $$UsuariosTableProcessedTableManager get usuarioId {
    final $_column = $_itemColumn<String>('usuario_id')!;

    final manager = $$UsuariosTableTableManager(
      $_db,
      $_db.usuarios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_usuarioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductosTable _productoIdTable(_$BaseDeDatos db) =>
      db.productos.createAlias('valoraciones__producto_id__productos__id');

  $$ProductosTableProcessedTableManager get productoId {
    final $_column = $_itemColumn<String>('producto_id')!;

    final manager = $$ProductosTableTableManager(
      $_db,
      $_db.productos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ValoracionesTableFilterComposer
    extends Composer<_$BaseDeDatos, $ValoracionesTable> {
  $$ValoracionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gusto => $composableBuilder(
    column: $table.gusto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$UsuariosTableFilterComposer get usuarioId {
    final $$UsuariosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.usuarioId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableFilterComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableFilterComposer get productoId {
    final $$ProductosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableFilterComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ValoracionesTableOrderingComposer
    extends Composer<_$BaseDeDatos, $ValoracionesTable> {
  $$ValoracionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gusto => $composableBuilder(
    column: $table.gusto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsuariosTableOrderingComposer get usuarioId {
    final $$UsuariosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.usuarioId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableOrderingComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableOrderingComposer get productoId {
    final $$ProductosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableOrderingComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ValoracionesTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $ValoracionesTable> {
  $$ValoracionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gusto =>
      $composableBuilder(column: $table.gusto, builder: (column) => column);

  GeneratedColumn<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<String> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  $$UsuariosTableAnnotationComposer get usuarioId {
    final $$UsuariosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.usuarioId,
      referencedTable: $db.usuarios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsuariosTableAnnotationComposer(
            $db: $db,
            $table: $db.usuarios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductosTableAnnotationComposer get productoId {
    final $$ProductosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productoId,
      referencedTable: $db.productos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductosTableAnnotationComposer(
            $db: $db,
            $table: $db.productos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ValoracionesTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $ValoracionesTable,
          Valoracion,
          $$ValoracionesTableFilterComposer,
          $$ValoracionesTableOrderingComposer,
          $$ValoracionesTableAnnotationComposer,
          $$ValoracionesTableCreateCompanionBuilder,
          $$ValoracionesTableUpdateCompanionBuilder,
          (Valoracion, $$ValoracionesTableReferences),
          Valoracion,
          PrefetchHooks Function({bool usuarioId, bool productoId})
        > {
  $$ValoracionesTableTableManager(_$BaseDeDatos db, $ValoracionesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ValoracionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ValoracionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ValoracionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<String> productoId = const Value.absent(),
                Value<String?> gusto = const Value.absent(),
                Value<String?> observacion = const Value.absent(),
                Value<String> creadoEn = const Value.absent(),
                Value<String> actualizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ValoracionesCompanion(
                id: id,
                usuarioId: usuarioId,
                productoId: productoId,
                gusto: gusto,
                observacion: observacion,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String usuarioId,
                required String productoId,
                Value<String?> gusto = const Value.absent(),
                Value<String?> observacion = const Value.absent(),
                required String creadoEn,
                required String actualizadoEn,
                Value<int> rowid = const Value.absent(),
              }) => ValoracionesCompanion.insert(
                id: id,
                usuarioId: usuarioId,
                productoId: productoId,
                gusto: gusto,
                observacion: observacion,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ValoracionesTable, Valoracion>(table),
                  $$ValoracionesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({usuarioId = false, productoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (usuarioId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.usuarioId,
                        referencedTable: $$ValoracionesTableReferences
                            ._usuarioIdTable(db),
                        referencedColumn: $$ValoracionesTableReferences
                            ._usuarioIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (productoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productoId,
                        referencedTable: $$ValoracionesTableReferences
                            ._productoIdTable(db),
                        referencedColumn: $$ValoracionesTableReferences
                            ._productoIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ValoracionesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $ValoracionesTable,
      Valoracion,
      $$ValoracionesTableFilterComposer,
      $$ValoracionesTableOrderingComposer,
      $$ValoracionesTableAnnotationComposer,
      $$ValoracionesTableCreateCompanionBuilder,
      $$ValoracionesTableUpdateCompanionBuilder,
      (Valoracion, $$ValoracionesTableReferences),
      Valoracion,
      PrefetchHooks Function({bool usuarioId, bool productoId})
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String tabla,
  required String filaId,
  required String operacion,
  required String encoladoEn,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> tabla,
  Value<String> filaId,
  Value<String> operacion,
  Value<String> encoladoEn,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$BaseDeDatos, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filaId => $composableBuilder(
    column: $table.filaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operacion => $composableBuilder(
    column: $table.operacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encoladoEn => $composableBuilder(
    column: $table.encoladoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$BaseDeDatos, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filaId => $composableBuilder(
    column: $table.filaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operacion => $composableBuilder(
    column: $table.operacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encoladoEn => $composableBuilder(
    column: $table.encoladoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tabla =>
      $composableBuilder(column: $table.tabla, builder: (column) => column);

  GeneratedColumn<String> get filaId =>
      $composableBuilder(column: $table.filaId, builder: (column) => column);

  GeneratedColumn<String> get operacion =>
      $composableBuilder(column: $table.operacion, builder: (column) => column);

  GeneratedColumn<String> get encoladoEn => $composableBuilder(
    column: $table.encoladoEn,
    builder: (column) => column,
  );
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $OutboxTable,
          EntradaOutbox,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            EntradaOutbox,
            BaseReferences<_$BaseDeDatos, $OutboxTable, EntradaOutbox>,
          ),
          EntradaOutbox,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$BaseDeDatos db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tabla = const Value.absent(),
                Value<String> filaId = const Value.absent(),
                Value<String> operacion = const Value.absent(),
                Value<String> encoladoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                tabla: tabla,
                filaId: filaId,
                operacion: operacion,
                encoladoEn: encoladoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabla,
                required String filaId,
                required String operacion,
                required String encoladoEn,
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                tabla: tabla,
                filaId: filaId,
                operacion: operacion,
                encoladoEn: encoladoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, EntradaOutbox>(table),
                  BaseReferences<_$BaseDeDatos, $OutboxTable, EntradaOutbox>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $OutboxTable,
      EntradaOutbox,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (
        EntradaOutbox,
        BaseReferences<_$BaseDeDatos, $OutboxTable, EntradaOutbox>,
      ),
      EntradaOutbox,
      PrefetchHooks Function()
    >;
typedef $$CursoresSyncTableCreateCompanionBuilder =
    CursoresSyncCompanion Function({
      required String tabla,
      required String cursor,
      Value<int> rowid,
    });
typedef $$CursoresSyncTableUpdateCompanionBuilder =
    CursoresSyncCompanion Function({
      Value<String> tabla,
      Value<String> cursor,
      Value<int> rowid,
    });

class $$CursoresSyncTableFilterComposer
    extends Composer<_$BaseDeDatos, $CursoresSyncTable> {
  $$CursoresSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CursoresSyncTableOrderingComposer
    extends Composer<_$BaseDeDatos, $CursoresSyncTable> {
  $$CursoresSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CursoresSyncTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $CursoresSyncTable> {
  $$CursoresSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tabla =>
      $composableBuilder(column: $table.tabla, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);
}

class $$CursoresSyncTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $CursoresSyncTable,
          CursorSync,
          $$CursoresSyncTableFilterComposer,
          $$CursoresSyncTableOrderingComposer,
          $$CursoresSyncTableAnnotationComposer,
          $$CursoresSyncTableCreateCompanionBuilder,
          $$CursoresSyncTableUpdateCompanionBuilder,
          (
            CursorSync,
            BaseReferences<_$BaseDeDatos, $CursoresSyncTable, CursorSync>,
          ),
          CursorSync,
          PrefetchHooks Function()
        > {
  $$CursoresSyncTableTableManager(_$BaseDeDatos db, $CursoresSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CursoresSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CursoresSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CursoresSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tabla = const Value.absent(),
                Value<String> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CursoresSyncCompanion(
                tabla: tabla,
                cursor: cursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabla,
                required String cursor,
                Value<int> rowid = const Value.absent(),
              }) => CursoresSyncCompanion.insert(
                tabla: tabla,
                cursor: cursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CursoresSyncTable, CursorSync>(table),
                  BaseReferences<_$BaseDeDatos, $CursoresSyncTable, CursorSync>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CursoresSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $CursoresSyncTable,
      CursorSync,
      $$CursoresSyncTableFilterComposer,
      $$CursoresSyncTableOrderingComposer,
      $$CursoresSyncTableAnnotationComposer,
      $$CursoresSyncTableCreateCompanionBuilder,
      $$CursoresSyncTableUpdateCompanionBuilder,
      (
        CursorSync,
        BaseReferences<_$BaseDeDatos, $CursoresSyncTable, CursorSync>,
      ),
      CursorSync,
      PrefetchHooks Function()
    >;
typedef $$EstadoSyncTableCreateCompanionBuilder = EstadoSyncCompanion Function({
  required String id,
  Value<String?> ultimoSyncExitoso,
  Value<int> rowid,
});
typedef $$EstadoSyncTableUpdateCompanionBuilder = EstadoSyncCompanion Function({
  Value<String> id,
  Value<String?> ultimoSyncExitoso,
  Value<int> rowid,
});

class $$EstadoSyncTableFilterComposer
    extends Composer<_$BaseDeDatos, $EstadoSyncTable> {
  $$EstadoSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoSyncExitoso => $composableBuilder(
    column: $table.ultimoSyncExitoso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EstadoSyncTableOrderingComposer
    extends Composer<_$BaseDeDatos, $EstadoSyncTable> {
  $$EstadoSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoSyncExitoso => $composableBuilder(
    column: $table.ultimoSyncExitoso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EstadoSyncTableAnnotationComposer
    extends Composer<_$BaseDeDatos, $EstadoSyncTable> {
  $$EstadoSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ultimoSyncExitoso => $composableBuilder(
    column: $table.ultimoSyncExitoso,
    builder: (column) => column,
  );
}

class $$EstadoSyncTableTableManager
    extends
        RootTableManager<
          _$BaseDeDatos,
          $EstadoSyncTable,
          EstadoSyncData,
          $$EstadoSyncTableFilterComposer,
          $$EstadoSyncTableOrderingComposer,
          $$EstadoSyncTableAnnotationComposer,
          $$EstadoSyncTableCreateCompanionBuilder,
          $$EstadoSyncTableUpdateCompanionBuilder,
          (
            EstadoSyncData,
            BaseReferences<_$BaseDeDatos, $EstadoSyncTable, EstadoSyncData>,
          ),
          EstadoSyncData,
          PrefetchHooks Function()
        > {
  $$EstadoSyncTableTableManager(_$BaseDeDatos db, $EstadoSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstadoSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EstadoSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EstadoSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ultimoSyncExitoso = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EstadoSyncCompanion(
                id: id,
                ultimoSyncExitoso: ultimoSyncExitoso,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ultimoSyncExitoso = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EstadoSyncCompanion.insert(
                id: id,
                ultimoSyncExitoso: ultimoSyncExitoso,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EstadoSyncTable, EstadoSyncData>(table),
                  BaseReferences<
                    _$BaseDeDatos,
                    $EstadoSyncTable,
                    EstadoSyncData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EstadoSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseDeDatos,
      $EstadoSyncTable,
      EstadoSyncData,
      $$EstadoSyncTableFilterComposer,
      $$EstadoSyncTableOrderingComposer,
      $$EstadoSyncTableAnnotationComposer,
      $$EstadoSyncTableCreateCompanionBuilder,
      $$EstadoSyncTableUpdateCompanionBuilder,
      (
        EstadoSyncData,
        BaseReferences<_$BaseDeDatos, $EstadoSyncTable, EstadoSyncData>,
      ),
      EstadoSyncData,
      PrefetchHooks Function()
    >;

class $BaseDeDatosManager {
  final _$BaseDeDatos _db;
  $BaseDeDatosManager(this._db);
  $$ArticulosTableTableManager get articulos =>
      $$ArticulosTableTableManager(_db, _db.articulos);
  $$ProductosTableTableManager get productos =>
      $$ProductosTableTableManager(_db, _db.productos);
  $$ComerciosTableTableManager get comercios =>
      $$ComerciosTableTableManager(_db, _db.comercios);
  $$PreciosTableTableManager get precios =>
      $$PreciosTableTableManager(_db, _db.precios);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$ValoracionesTableTableManager get valoraciones =>
      $$ValoracionesTableTableManager(_db, _db.valoraciones);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$CursoresSyncTableTableManager get cursoresSync =>
      $$CursoresSyncTableTableManager(_db, _db.cursoresSync);
  $$EstadoSyncTableTableManager get estadoSync =>
      $$EstadoSyncTableTableManager(_db, _db.estadoSync);
}
