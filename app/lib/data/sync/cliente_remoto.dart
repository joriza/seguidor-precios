/// Puerto del núcleo de sync hacia el backend colaborativo.
///
/// Minimal y Sin dependencias: el servicio de sync solo conoce esta
/// interfaz, de modo que los tests corren con un cliente falso (sin red) y
/// el adapter real ([ClienteSupabase]) encapsula el paquete `supabase`.
///
/// Formato de filas: mapas con los nombres de columna del esquema remoto
/// (snake_case, según docs/modelo-de-datos.md), igual que devuelve PostgREST.
abstract class ClienteRemoto {
  /// uid del usuario anónimo de la sesión activa, o null si no hay sesión.
  Future<String?> uidSesionActual();

  /// Inicia sesión anónima (AD-003) y devuelve el uid nuevo.
  Future<String> iniciarSesionAnonima();

  /// Pide el enlace mágico (S3, R17/AD-003): Supabase envía al email el
  /// enlace y el código de 6 dígitos. No abre sesión todavía; la sesión
  /// llega con [completeMagicLink].
  Future<void> requestMagicLink(String email);

  /// Completa el login con el código del email (OTP de email) y devuelve
  /// el uid de la cuenta (nueva o existente). Deja la sesión guardada para
  /// que sobreviva al cierre de la app, igual que la anónima.
  Future<String> completeMagicLink({
    required String email,
    required String code,
  });

  /// Email de la cuenta de la sesión activa, o null si la sesión es
  /// anónima o no hay sesión. Alimenta el estado visible en la UI.
  Future<String?> accountEmail();

  /// Ping mínimo anti-pausa (R14): RPC `ping`, no sincroniza datos.
  Future<void> ping();

  /// Sube un lote de filas por upsert (por id, regla de sync 1) y devuelve
  /// las filas resultantes, también por id. El dedup de EAN es una llamada
  /// explícita aparte: [idCanonicoPorEan] ANTES de subir un producto con
  /// `codigo_barras` (regla de sync 6; el índice único parcial del servidor
  /// rechazaría el duplicado con 23505 si se subiera directo).
  Future<List<Map<String, dynamic>>> subirLote({
    required String tabla,
    required List<Map<String, dynamic>> filas,
  });

  /// Id del producto canónico para un EAN ya existente en el servidor
  /// (RPC `dedup_ean`, regla de sync 6), o null si el EAN aún no existe.
  /// Al ejecutarse, el servidor re-apunta sus precios y da de baja lógica
  /// los duplicados; la fila canónica conserva sus propios datos.
  Future<String?> idCanonicoPorEan(String codigoBarras);

  /// Id de la fila de usuario que ya lleva ese `auth_uid` en el servidor
  /// (T4, multi-dispositivo), o null si ninguna fila remota lo lleva.
  /// Es el espejo de [idCanonicoPorEan] para la identidad: el servidor
  /// garantiza a lo sumo una fila por `auth_uid` (uq_usuario_auth_uid),
  /// así que subir la identidad de una cuenta ya conocida chocaría con
  /// 23505 — primero hay que converger a ESA fila.
  Future<String?> idUsuarioPorAuthUid(String authUid);

  /// Trae una fila remota por id; null si no existe. Se usa para copiar
  /// localmente la fila canónica tras un dedup antes de re-apuntar.
  Future<Map<String, dynamic>?> traerFila({
    required String tabla,
    required String id,
  });

  /// Borra físicamente una fila remota por id (solo `valoracion`: su baja
  /// es física por diseño — “quedan cero datos”). Las bajas de articulo,
  /// producto y comercio son lógicas y viajan como upsert con `borrado_en`.
  Future<void> borrarFila({required String tabla, required String id});

  /// Descarga filas con `columnaCursor >= desde`, ordenadas por
  /// (columnaCursor, id), hasta [limite]. `actualizado_en` para todas las
  /// tablas salvo precio (append-only: su cursor es `cargado_en`, regla de
  /// sync 3).
  ///
  /// Con [desdeId] la ventana avanza más allá de (desde, desdeId) — keyset
  /// (C1 del juicio fase-2): devuelve solo filas con cursor mayor, o igual
  /// con id mayor, siempre en ese orden. Un lote lleno de timestamps
  /// idénticos (el `now()` común de un cargador masivo) así no repite la
  /// misma página para nunca.
  Future<List<Map<String, dynamic>>> descargarCambios({
    required String tabla,
    required String columnaCursor,
    required String desde,
    String? desdeId,
    required int limite,
  });
}
