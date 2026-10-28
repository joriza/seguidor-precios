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

  int iniciosSesionAnonimos = 0;
  int pings = 0;

  /// Nombre de tabla en la que [subirLote] debe fallar (simula caída).
  String? errorAlSubir;

  /// Nombre de tabla en la que [descargarCambios] debe fallar.
  String? errorAlDescargar;

  /// EAN consultados por [idCanonicoPorEan], en orden (traza del test).
  final List<String> idsDedupConsultados = [];

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
  Future<void> ping() async => pings++;

  @override
  Future<List<Map<String, dynamic>>> subirLote({
    required String tabla,
    required List<Map<String, dynamic>> filas,
  }) async {
    if (errorAlSubir == tabla) {
      throw Exception('servidor caído al subir $tabla');
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
    required int limite,
  }) async {
    if (errorAlDescargar == tabla) {
      throw Exception('servidor caído al descargar $tabla');
    }
    descargasPedidas.add('$tabla:$columnaCursor:$desde');
    final filas = [...(remoto[tabla] ?? const <Map<String, dynamic>>[])]..sort(
        (a, b) => (a[columnaCursor] as String).compareTo(b[columnaCursor] as String),
      );
    return filas
        .where((f) => _masNueva(f[columnaCursor] as String, desde) ||
            f[columnaCursor] == desde)
        .take(limite)
        .toList();
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
