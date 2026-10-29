import 'package:seguidor_precios/data/sync/cliente_remoto.dart';

/// Cliente remoto falso para tests de sync (sin red): simula el
/// comportamiento del servidor — push con upsert por id, dedup por EAN en
/// `producto`, pull incremental por cursor y borrado por id.
class ClienteRemotoFalso implements ClienteRemoto {
  /// Estado remoto simulado por tabla (filas en formato del esquema remoto:
  /// snake_case, como devuelve PostgREST).
  final Map<String, List<Map<String, dynamic>>> remoto = {};

  /// Tablas pedidas por [subirLote], en el orden en que llegaron.
  final List<String> ordenSubidas = [];

  /// Lotes enviados a [subirLote], en orden.
  final List<List<Map<String, dynamic>>> lotesSubidos = [];

  /// Filas pedidas por [descargarCambios], como 'tabla:columna:desde'.
  final List<String> descargasPedidas = [];

  /// Filas pedidas por [borrarFila], como 'tabla:id'.
  final List<String> bajasPedidas = [];

  /// Sesión anónima simulada (null = sin sesión).
  String? uidSesion;

  /// S3 (R17/AD-003): email de la cuenta de la sesión actual (null si la
  /// sesión es anónima o no hay sesión).
  String? emailSesion;

  /// S3: uid que devuelve [completeMagicLink] (cuenta real simulada).
  String uidCuentaEmail = 'uid-email-1';

  /// S3: enlaces mágicos pedidos (emails ya normalizados), en orden.
  final List<String> enlacesPedidos = [];

  /// S3: verificaciones OTP (email, código), en orden.
  final List<(String, String)> codigosVerificados = [];

  /// S3: error a lanzar en [requestMagicLink] / [completeMagicLink].
  Object? errorAlPedirEnlace;
  Object? errorAlCompletarEnlace;

  int iniciosSesionAnonimos = 0;
  int pings = 0;

  /// Nombre de tabla en la que [subirLote] debe fallar (simula caída).
  String? errorAlSubir;

  /// Nombre de tabla en la que [descargarCambios] debe fallar.
  String? errorAlDescargar;

  /// EAN consultados por [idCanonicoPorEan], en orden (traza del test).
  final List<String> idsDedupConsultados = [];

  /// T4 (S3): auth_uid consultados por [idUsuarioPorAuthUid], en orden
  /// (traza del test).
  final List<String> idsUsuarioConsultados = [];

  void sembrar(String tabla, List<Map<String, dynamic>> filas) {
    (remoto[tabla] ??= []).addAll(filas);
  }

  @override
  Future<String> iniciarSesionAnonima() async {
    iniciosSesionAnonimos++;
    uidSesion = 'uid-anon-$iniciosSesionAnonimos';
    return uidSesion!;
  }

  @override
  Future<String?> uidSesionActual() async => uidSesion;

  @override
  Future<void> requestMagicLink(String email) async {
    final error = errorAlPedirEnlace;
    if (error != null) throw error;
    enlacesPedidos.add(email);
  }

  @override
  Future<String> completeMagicLink(
      {required String email, required String code}) async {
    final error = errorAlCompletarEnlace;
    if (error != null) throw error;
    codigosVerificados.add((email, code));
    uidSesion = uidCuentaEmail;
    emailSesion = email;
    return uidCuentaEmail;
  }

  @override
  Future<String?> accountEmail() async => emailSesion;

  @override
  Future<void> ping() async => pings++;

  @override
  Future<List<Map<String, dynamic>>> subirLote({
    required String tabla,
    required List<Map<String, dynamic>> filas,
  }) async {
    if (errorAlSubir == tabla) {
      throw Exception('servidor caído al subir $tabla');
    }
    if (tabla == 'usuario') {
      // El servidor rechaza con 23505 toda fila que daría a DOS filas de
      // usuario el mismo auth_uid (uq_usuario_auth_uid, migración 0001):
      // exactamente lo que pasaría si una segunda instalación subiera su
      // identidad local ya vinculada a una cuenta que el servidor conoce.
      for (final fila in filas) {
        final uid = fila['auth_uid'] as String?;
        if (uid == null) continue;
        final choca = (remoto['usuario'] ?? const <Map<String, dynamic>>[])
            .any((r) => r['auth_uid'] == uid && r['id'] != fila['id']);
        if (choca) {
          throw Exception(
              '23505: duplicate key value violates unique constraint '
              '"uq_usuario_auth_uid" (auth_uid=$uid)');
        }
      }
    }
    ordenSubidas.add(tabla);
    lotesSubidos.add(filas);

    final respuesta = <Map<String, dynamic>>[];
    for (final fila in filas) {
      final filaFinal = Map<String, dynamic>.of(fila);
      _guardarFila(tabla, filaFinal);
      respuesta.add(filaFinal);
    }
    return respuesta;
  }

  @override
  Future<String?> idCanonicoPorEan(String codigoBarras) async {
    idsDedupConsultados.add(codigoBarras);
    // Mismo criterio que el RPC dedup_ean: canónico = menor creado_en
    // (y menor id para desempatar) entre los no borrados con ese EAN.
    final candidatos = (remoto['producto'] ?? const <Map<String, dynamic>>[])
        .where((r) =>
            r['codigo_barras'] == codigoBarras && r['borrado_en'] == null)
        .toList()
      ..sort((a, b) {
        final porCreado = (a['creado_en'] as String)
            .compareTo(b['creado_en'] as String);
        if (porCreado != 0) return porCreado;
        return (a['id'] as String).compareTo(b['id'] as String);
      });
    return candidatos.isEmpty ? null : candidatos.first['id'] as String;
  }

  @override
  Future<String?> idUsuarioPorAuthUid(String authUid) async {
    idsUsuarioConsultados.add(authUid);
    // Criterio del servidor (uq_usuario_auth_uid): a lo sumo una fila por
    // auth_uid; el desempate (creado_en, id) replica el de dedup_ean.
    final candidatos = (remoto['usuario'] ?? const <Map<String, dynamic>>[])
        .where((r) => r['auth_uid'] == authUid)
        .toList()
      ..sort((a, b) {
        final porCreado =
            (a['creado_en'] as String).compareTo(b['creado_en'] as String);
        if (porCreado != 0) return porCreado;
        return (a['id'] as String).compareTo(b['id'] as String);
      });
    return candidatos.isEmpty ? null : candidatos.first['id'] as String;
  }

  @override
  Future<Map<String, dynamic>?> traerFila({
    required String tabla,
    required String id,
  }) async {
    for (final fila in remoto[tabla] ?? const <Map<String, dynamic>>[]) {
      if (fila['id'] == id) return Map<String, dynamic>.of(fila);
    }
    return null;
  }

  @override
  Future<void> borrarFila({required String tabla, required String id}) async {
    if (errorAlSubir == tabla) {
      throw Exception('servidor caído al borrar en $tabla');
    }
    bajasPedidas.add('$tabla:$id');
    remoto[tabla]?.removeWhere((f) => f['id'] == id);
  }

  @override
  Future<List<Map<String, dynamic>>> descargarCambios({
    required String tabla,
    required String columnaCursor,
    required String desde,
    String? desdeId,
    required int limite,
  }) async {
    if (errorAlDescargar == tabla) {
      throw Exception('servidor caído al descargar $tabla');
    }
    descargasPedidas.add(desdeId == null
        ? '$tabla:$columnaCursor:$desde'
        : '$tabla:$columnaCursor:$desde:$desdeId');
    // Mismo contrato que el adapter real (PostgREST): orden por
    // (columnaCursor asc, id asc) y, con keyset, la ventana avanza más
    // allá de (desde, desdeId): solo filas con cursor mayor, o igual con
    // id mayor. Así un bloque de timestamps iguales no repite la página.
    final filas = [...(remoto[tabla] ?? const <Map<String, dynamic>>[])]..sort(
        (a, b) {
          final porCursor =
              (a[columnaCursor] as String).compareTo(b[columnaCursor] as String);
          if (porCursor != 0) return porCursor;
          return (a['id'] as String).compareTo(b['id'] as String);
        },
      );
    bool dentroDeLaVentana(Map<String, dynamic> f) {
      final ts = f[columnaCursor] as String;
      if (!_masNueva(ts, desde) && ts != desde) return false;
      if (desdeId == null) return true;
      if (_masNueva(ts, desde)) return true;
      return (f['id'] as String).compareTo(desdeId) > 0;
    }

    return filas.where(dentroDeLaVentana).take(limite).toList();
  }

  void _guardarFila(String tabla, Map<String, dynamic> fila) {
    final lista = remoto[tabla] ??= [];
    lista.removeWhere((f) => f['id'] == fila['id']);
    lista.add(fila);
  }
}

bool _masNueva(String a, String b) {
  final da = DateTime.tryParse(a);
  final db = DateTime.tryParse(b);
  if (da != null && db != null) return da.isAfter(db);
  return a.compareTo(b) > 0;
}
