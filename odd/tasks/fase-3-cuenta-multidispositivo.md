# Fase 3 — Cuenta multi-dispositivo (post-MVP) + críticos C1/C2 del juicio

Fase 3 del Seguidor de Precios: primero los 2 críticos del pull confirmados por el juicio dual
(C1/C2, prioridad máxima), luego la cuenta opcional multi-dispositivo con enlace mágico (tarea 3.7).
Fuente normativa: docs/hoja-de-ruta.md (Fase 3), docs/requisitos.md (R17), docs/decisiones.md
(AD-003), Log L20 de odd/tasks/fase-2-colaborativo.md, ledger del juicio en
apk-debug/judgment-fase2-ledger.json (gitignored, local).

## Specs

- S1 — Crítico C1 (juicio dual ciego, Log L20 fase-2): "inanición de paginación del pull con ≥100
  timestamps iguales — un dispositivo nuevo solo baja 100/424 del catálogo". El pull debe bajar
  TODO lo nuevo sin importar cuántas filas compartan el mismo `actualizado_en`, y el cursor solo
  avanza hasta el último dato efectivamente guardado.
- S2 — Crítico C2 (juicio dual ciego, Log L20 fase-2): "colisión de EAN en el pull — ids
  sem-<ean> locales vs uuid5 del servidor violan el UNIQUE local → el pull del teléfono del dueño
  está roto: sube pero nunca baja, crash antes de guardarCursor". El pull de un producto cuyo EAN
  ya existe como fila de semilla debe converger con el servidor sin violar el UNIQUE local, sin
  crash, guardando el cursor y sin perder precios/comercios vinculados.
- S3 — Tarea 3.7 de docs/hoja-de-ruta.md: "Cuenta opcional multi-dispositivo con enlace mágico
  (diferida de la etapa de pruebas)" (cubre R17, AD-003): login opcional por email con magic
  link, la identidad local queda vinculada a la cuenta y puede restaurarse en otra instalación.

## Tasks

- T1 (S1) — Fix C1: paginación del pull sin inanición. Ruta: worker + tests. Commit:
  d04dea1 (fix(sync), unidad única junto con T2: comparten la ruta del pull y el grupo de
  tests).
- T2 (S2) — Fix C2: convergencia de ids de semilla con el servidor en el pull. Ruta: worker +
  tests. Commit: d04dea1 (ídem T1).
- T3 (S3) — Cuenta por email (magic link): UI de login opcional + vinculación de identidad +
  ajuste de auth en backend. Ruta: worker + tests. Commit: d84bf53 (feat(cuenta)). Riesgo de la
  unidad: item 2 (seguridad/RLS) — verificación inline del padre (ver Log L4/L5); el runtime no
  admitió verificador independiente delegado (la delegación no declaraba Risk line).
- T4 (S3) — Multi-dispositivo: restaurar identidad/datos en instalación nueva vía login. Ruta:
  worker + tests. Commit: b7abaa7 (feat(sync)).
- T5 (S1-S3) — Estado en docs/hoja-de-ruta.md (Fase 3 en curso), release v0.3.0 y validación en
  dispositivo del dueño. Ruta: parent + dueño. Release: tag v0.3.0 (v0.3.0+9); validación
  pendiente del dueño.

## Log

- L1 — "Dame los comandos de punto 1 que debo aplicar. / He instalado la version 0.2.2 y parece
  que vá bien / incia con la fase 3": el dueño pide el SQL de es_admin (entregado en la
  conversación), reporta v0.2.2 instalada y funcionando, y autoriza iniciar la Fase 3. Alcance
  acordado: C1/C2 (prioridad máxima del juicio) + cuenta multi-dispositivo (3.7); el resto de las
  tareas 3.x y el backlog de mejoras #1-#6 quedan candidatos a priorizar con datos de uso.
- L2 — "Recuera aplicar todo lo mas posible en 1 agente en paralelo para preservar el contexto
  actual": el trabajo pesado se delega a UN worker por vez, en background/paralelo, para preservar
  el contexto de la sesión padre.
- L3 — T1+T2 ejecutados por worker en background (task mvtu0zzt-1-iyt8) con TDD: RED reproduce
  C1 (solo 100/251 bajan; inanición) y C2 (SqliteException UNIQUE codigo_barras desde
  _aplicarFilaRemota, crash antes de guardarCursor — síntoma exacto del teléfono del dueño);
  GREEN: pull keyset (actualizado_en, id) con cursor por página aplicada (C1) y convergencia
  atómica por EAN (libera EAN → merge LWW bajo id del servidor, re-encola edit local ganador,
  re-apunta precios/valoraciones, descarta duplicado + entrada de outbox) sin migración de
  esquema (v4 intacta, supabase/migrations sin tocar). Verificación del padre: suite 204/204
  (201 previos + 3 nuevos) y analyze --fatal-infos limpio, observados inline. Commits: aad13e8
  (docs ODD) + d04dea1 (fix, 372 líneas). Riesgo declarado por el worker: el filtro keyset
  or(...) de PostgREST no se ejercitó contra Supabase vivo en tests (fake emula el contrato);
  la primera pull real del dueño (T5) lo valida en campo.
- L4 — T3 ejecutado por worker en background (task mvtuuyxz-2-r0dh) con TDD (13 tests RED→GREEN:
  pedido de magic link signInWithOtp, completado con código de 6 dígitos verifyOTP in-app — el
  deep-link del email queda como follow-up fuera de superficies —, vinculación de la fila local
  EXISTENTE sin duplicar identidad, errores en español por modo de fallo). Migración 0005
  (nueva): política actualizacion_propia de usuario re-creada FOR UPDATE con adopción SOLO de
  filas cuyo auth_uid es anónimo (es_usuario_anonimo SECURITY DEFINER); WITH CHECK sin cambios.
  Verificación del padre sobre blobs commiteados: en 0001 actualizacion_propia ya era FOR UPDATE
  (INSERT vive en alta_colaborativa, SELECT en lectura_colaborativa) → sin pérdida de cobertura;
  cuenta verificada nunca adoptable. Suite 217/217 (204 + 13) y analyze limpios, observados
  inline. Commit d84bf53 (849 líneas). ASSESS nativo: nativeRisk medium, reviewDue false
  (under_budget); escalado item 2 (seguridad/RLS) → plan con verificador independiente
  (gentle-ai-verify en background, lee blobs commiteados d84bf53). Pasos del lado del dueño
  (reportados por el worker, pendientes): (1) aplicar 0005 en Studio (idempotente); (2) template
  Magic Link con {{ .Token }}; (3) SMTP propio (builtin ~2 emails/hora); (4) Site URL;
  (5) chequeo de campo en T5. Franja de commits: unidad T3 de 849 líneas excede la guía de
  ~400 — para PR usar chained-pr (slices: docs+fix 372 / feat 849) o aceptar slice único;
  decisión de entrega en T5.
- L5 — Verificación de seguridad de 0005 por el padre (ítem 2), tras rechazo del runtime al
  verificador independiente delegado: (1) en 0001 actualizacion_propia ya era FOR UPDATE →
  recrearla como FOR UPDATE no pierde cobertura (INSERT=alta_colaborativa, SELECT=
  lectura_colaborativa); (2) adopción acotada: USING exige auth_uid de sesión o fila anónima
  (es_usuario_anonimo, SECURITY DEFINER, search_path '', REVOKE PUBLIC + GRANT authenticated,
  booleano puro) y WITH CHECK fuerza auth_uid = auth.uid() → cuenta verificada jamás adoptable;
  (3) idempotente y transaccional; (4) admin_dueno no es tocado por 0005; (5) flujo cliente:
  push genérico .upsert() — post-vinculación la fila del servidor lleva el auth_uid anónimo
  VIEJO y la sesión el uid NUEVO → gobierna el UPDATE que 0005 habilita; instalación nunca
  sincronizada va por INSERT con WITH CHECK propio; colisión uq_usuario_auth_uid (segunda
  instalación misma cuenta) = frontera T4 documentada en el header de 0005. Interplay vivo
  (RLS real + SMTP + template) queda a la validación de campo T5.
- L6 — T4 ejecutado por worker en background (task mvtw5cox-3-tn37) con TDD (8 tests, 6 RED que
  reproducen el 23505 uq_usuario_auth_uid en vivo): convergencia de identidad espejo de C2 pero
  por auth_uid — al detectar fila remota de usuario con el auth_uid de la cuenta local, se
  adopta el id del servidor, re-apunta dependientes (valoraciones.usuario_id, precios.cargado_por,
  creado_por), merge LWW de etiqueta (gana local → re-encola bajo id canónico), descarta el
  duplicado + su entrada de outbox, y re-ancla la adoptada al primer lugar de la tabla
  (usuarioActual resuelve identidad por orden de escaneo) con PRAGMA defer_foreign_keys dentro
  de la misma transacción. Trigger tanto en push (lookup idUsuarioPorAuthUid antes de subir,
  espejo del bloque EAN) como en pull (_aplicarFilaRemota). Sin cambio de esquema: el lookup es
  SELECT colaborativo de 0001 → la garantía de adopción de 0005 no puede regresar; uq queda de
  backstop para clientes viejos. Verificación del padre: función leída inline (transacción,
  LWW, punteros sin tocar datos, defer FK con restauración exacta de ids), suite 225/225 (217 +
  8) y analyze limpios observados inline. Commit b7abaa7 (614 líneas). ASSESS: medium,
  reviewDue false (under_budget). Franja total de la rama: 1875+ líneas — para PR usar
  chained-pr con slices (fix 372 / feat cuenta 849 / feat sync 614); decisión de entrega en
  cierre de fase. Release: hoja-de-ruta actualizada (Fase 3 en curso; nota de críticos
  corregidos en Fase 2), pubspec 0.3.0+9, tag v0.3.0 → CI release. Límites documentados (sin
  bloqueo): la fila anónima vieja del servidor queda inerte; atribución cosmética de filas ya
  subidas conserva creado_por viejo hasta que cambien.
- L7 — RELEASE v0.3.0 PUBLICADA: run de CI 40937603113 verde (6m19s), asset
  `seguidor-precios-v0.3.0-debug.apk` publicado en github.com/joriza/seguidor-precios/releases/
  tag/v0.3.0. Pendiente de T5: instalación sobre la v0.2.2 existente (sin desinstalar), primera
  pull real con keyset (catálogo completo) y vinculación de cuenta en el teléfono del dueño;
  después, la decisión de merge `fase-3` → `main` es del dueño.
- L8 — VALIDACIÓN DE CAMPO DEL DUEÑO (v0.3.0) + correctivo: (a) sync reportó "subidos 0 /
  descargados 14" — SALUDABLE: subidos 0 porque no había nada pendiente local (todo ya subió con
  v0.2.2), descargados 14 es el incremental de la cola (página inicial inclusiva del cursor,
  acotada e idempotente por LWW, riesgo declarado en L3) — y sobre todo el pull COMPLETÓ sin
  crash: en v0.2.x el teléfono del dueño subía pero nunca bajaba (C2); la validación completa de
  C1 (catálogo entero en primera sync) requiere instalación NUEVA. (b) Botón "Enviar enlace" →
  "Algo salió mal": el padre reprodujo la llamada exacta del teléfono vía API con la clave
  anónima pública (AD-002) → POST /auth/v1/otp devolvió 200: el servidor está sano (signups
  habilitados, SMTP despacha); la causa es el fallback del mapeador ante errores de red no-
  Socket (ClientException de package:http). FIX v0.3.1: mapeo por texto de red para no-Auth
  + debugPrint del error crudo en consola en ambos catch del servicio (mismo patrón de
  transparencia que v0.2.2). TDD: 1 RED (mapeo ClientException → "Sin conexión") → GREEN;
  suite 226/226 y analyze limpios observados inline. Commits: fix v0.3.1+10, tag v0.3.1.
- L9 — RELEASE v0.3.1 PUBLICADA: run de CI 40995225310 verde (8m10s), asset
  `seguidor-precios-v0.3.1-debug.apk` en releases/tag/v0.3.1; QR generado en
  apk-debug/qr-instalar-v0.3.1.png (PNG; el print ASCII a terminal falla por encoding cp1252
  — irrelevante, sobra con el PNG). Pendiente de T5 (dueño): instalar v0.3.1 sobre v0.3.0,
  completar template Magic Link con {{ .Token }} y reintentar vinculación; resto del checklist
  L8 (C1 en instalación nueva, auth_uid en tabla, sync post-vínculo, T4, admin).
- L10 — MERGE `fase-3` → `main` POR FAST-FORWARD (7717e89..42595ed, 10 commits, 1925 líneas)
  con autorización del dueño ("mergee fase-3"); la rama queda como referencia histórica y main
  pasa a ser la línea de release. MISMO ERROR en campo con v0.3.1 ("Algo salió mal" al validar
  el correo): análisis de código del padre — el diálogo es limpio (muestra accountErrorMessage
  tal cual) y el único camino que produce el fallback EXACTO en el paso 2 es el
  `StateError('Supabase no devolvió sesión al verificar el código')` de completeMagicLink
  (no es AuthException/SocketException y su texto no tiene palabras de red). FIX v0.3.2:
  (a) StateError mapeado a mensaje específico de reintentar; (b) el fallback genérico ahora
  incluye el runtimeType del error — cualquier error no clasificado se reporta desde la
  pantalla y se diagnostica sin USB. TDD: 2 RED → GREEN (StateError específico; fallback con
  tipo); suite 228/228 y analyze limpios observados inline. tag v0.3.2 (v0.3.2+11).
- L11 — RELEASE v0.3.2 PUBLICADA (run 40997055692 verde, asset
  seguidor-precios-v0.3.2-debug.apk, QR apk-debug/qr-instalar-v0.3.2.png abierto). El dueño
  confirmó que el fallo es en el paso 1 ("Enviar enlace", signInWithOtp) → el StateError del
  paso 2 no era el camino. Hipótesis AuthApiException DESCARTADA: en gotrue 2.27.3
  (pubspec.lock) AuthApiException extends AuthException → los errores de API sí se mapean. El
  error real es un tipo aún no clasificado (candidatos: FormatException por respuesta no-JSON
  en red interceptada, HandshakeException TLS, ClientException sin palabras de red). PRÓXIMA
  SESIÓN: dueño instala v0.3.2, reintenta "Enviar enlace" y reporta el texto completo que
  ahora incluye el tipo entre paréntesis — eso nombra la clase exacta y define el fix; opción
  definitiva: teléfono por USB + adb logcat -s flutter (debugPrint de v0.3.1+ ya loguea el
  error crudo). PENDIENTES del checklist de campo: template Magic Link con {{ .Token }} (sin
  confirmar), C1 en instalación nueva, auth_uid en tabla, sync post-vínculo, T4, admin.
- L12 — DIAGNÓSTICO CERRADO + FIX v0.3.3 de la vinculación (paso 1): el dueño instaló v0.3.2 y
  reportó el tipo exacto: `_AssertionError`. Diagnóstico del padre (fuente de gotrue 2.27.3 en el
  pub cache + RED reproducible): supabase-dart arma GoTrueClient con flowType PKCE por defecto y
  exige asyncStorage para el code_verifier; `signInWithOtp` rompía en `_generatePKCECodeChallenge`
  (`assert(_asyncStorage != null)`, gotrue_client.dart:478) ANTES de tocar la red — por eso el
  servidor estaba sano (curl 200) y la app nunca mandó el request; en release el assert se compila
  fuera y rompería distinto (null-check). El nombre `_AssertionError` es el runtimeType real en la
  VM de Flutter (confirmado en el RED). FIX: `ClienteSupabase` arma el SupabaseClient con
  `AuthClientOptions(authFlowType: AuthFlowType.implicit)` — el ingreso es por código de 6 dígitos
  in-app (sin deep links ni redirects), el exchange PKCE nunca ocurre y `verifyOTP` de gotrue
  2.27.3 no envía code_verifier (verificado en el fuente). TDD: 1 RED (nuevo test del adapter
  real contra 127.0.0.1:9: esperaba error de red, llegó el AssertionError con el stack exacto del
  teléfono) → GREEN; suite 229/229 y analyze limpios. Propuestas de producto #7 (artículos sin
  EAN con código secuencial) y #8 (búsqueda combinada EAN/descripción desde 3 caracteres)
  anotadas en el backlog de hoja-de-ruta.md. tag v0.3.3 (v0.3.3+12).
- L13 — RELEASE v0.3.3 PUBLICADA (run de release 41090391769 verde, 6m20s, asset
  `seguidor-precios-v0.3.3-debug.apk`, 186 MB, en releases/tag/v0.3.3; QR
  apk-debug/qr-instalar-v0.3.3.png generado). Checklist del dueño: (1) template Magic Link con
  {{ .Token }} en Supabase Studio — CRÍTICO, sin él el email no muestra el código de 6 dígitos;
  (2) instalar v0.3.3; (3) reintentar la vinculación completa (paso 1 debería pedir el enlace de
  verdad esta vez); resto: auth_uid en tabla, sync post-vínculo, C1 en instalación nueva, T4,
  admin.
- L14 — VALIDACIÓN DE CAMPO v0.3.3 EQUIPO NUEVO ("Noe", instalación fresca, usuario creado
  19:11:33 UTC 2026-10-30): primera sync aborta con `SqliteException(787) FOREIGN KEY` al insertar
  el precio `dc13c0e0` (captura Downloads/Err-equipo-nuevo.jpeg). Datos verificados: (1) SERVIDOR
  ÍNTEGRO — dump REST con sesión anónima de diagnóstico (app/build/diag/*.json, gitignored):
  428 productos con EAN únicos y sin borrados, 2 comercios, 7 precios con padres todos presentes y
  cargado_en IDÉNTICO (19:36:24.051723, trigger por statement), RPC dedup_ean responde el canónico
  correcto; (2) la tabla local `precios` tiene FK solo a producto y comercio (cargado_por es
  texto); (3) REPROS QUE PASAN: test/sync_primera_instalacion_test.dart (escenario sintético con
  volúmenes reales, COMMITTEADO como pin del caso instalación-nueva) y test/tmp_diag_repro_test.dart
  (dump REAL + semilla REAL del asset, temporal no-commiteado) — la sync fresca de una sola
  vuelta NO reproduce el fallo; (4) DEDUCCIÓN CLAVE: dc13c0e0 es el ÚLTIMO precio del orden
  (cargado_en,id) y su gemelo 9dc116b5 (MISMOS padres producto ba129b10 + comercio 4e1614be) Sorta
  ANTES — la FK es por fila: si 9dc116b5 insertó, dc13c0e0 no puede fallar con los mismos padres
  ⟹ en el intento que falló el pull RETOMÓ con el cursor del precio ya parado ENTRE ambos (keyset
  pidió solo dc13c0e0) ⟹ hubo MÚLTIPLES intentos y en uno previo los padres NO estaban cuando se
  aplicaron los precios 1-6 y se guardó ese cursor, O un padre se borró localmente después de
  insertarse (únicos borradores de producto: _reApuntarProducto por push y
  _convergerProductoPorEan por pull, ambos transaccionales). HIPÓTESIS A INVESTIGAR (matriz de
  multi-intento con crashes de red a mitad de pasada): retomas con cursores por lote + el encolado
  de canónicos que hace la convergencia del pull (encolarUpsert en _convergerProductoPorEan) + el
  re-touch de actualizado_en por la trigger del servidor al re-subirlos — verificar ninguna
  combinación deja un canónico ausente con el cursor del precio avanzado. Diagnóstico delegado a
  worker con estas premisas; fix y release v0.3.4 en el mismo alcance.
- L15 — CAUSA RAÍZ + FIX v0.3.4 (worker mvvdtuhi-1-i1ef, verificado por el padre): la FK 787 de
  campo estaba en el pull de precio insertando con padres ausentes localmente — su única garantía
  era el orden producto→comercio→precio DENTRO de una sesión, y se rompe cuando el padre aterriza
  o es re-apuntado en el servidor ENTRE el pull de producto y el de precio (el dueño corría el
  cargador tools/cargar_semilla_supabase.py por tandas esa noche; 96 productos escritos por el
  teléfono en UN statement a las 19:12:48.957816). Peor: con el cursor de producto por encima del
  sello del padre, los reintentos con gte(cursor) lo saltean para siempre. CORRECCIÓN a la
  deducción de L14: el estado "cursor entre gemelas + padre ausente" es inconstruible en SQLite
  (la gemela local retiene al padre por FK, probado en la matriz N5); el fallo real fue la PRIMERA
  fila de precio cuyo padre faltaba (SQLite no nombra filas: el error de campo no identifica a
  dc13c0e0), y el +1 de descargas es el eco propio del usuario del dispositivo (expectativa 439→440
  corregida en sync_primera_instalacion_test.dart, pre-existente en HEAD probado por diferencial).
  FIX mínimo (regla de sync 1: el id es la identidad): _asegurarPadreRemoto trae el padre ausente
  por id (traerFila) y lo aplica por la MISMA ruta del pull (merge LWW + convergencia por
  EAN/auth_uid incluidos) antes de insertar precio/valoración; el pull de producto también repara
  articulo_id. Si el padre tampoco existe server-side, la sesión aborta sin guardar el cursor
  (contrato R15 fijado por test) y el reintento lo re-busca. Robusto a todos los entrelazados
  porque ignora cursores. TDD: RED 4 fallos FK + matriz multi-intento N1-N7 (ServidorFiel con
  triggers por statement y ventana del cargador concurrente) → GREEN; suite commiteada 234/234 y
  analyze limpios (verificados por el padre; los tests temporales tmp_* se descartaron, el pin
  durable es sync_autoreparacion_padres_test.dart). Hallazgo forense: el push sube lotes reducidos
  cuando el dedup descarta intercalado — el sello único de 96 filas implica outbox de exactamente
  96 canónicos limpios = re-encolados de la convergencia del pull. tag v0.3.4 (v0.3.4+13).
- L16 — RELEASE v0.3.4 PUBLICADA (run de release 41126402199 verde, 5m56s, asset
  `seguidor-precios-v0.3.4-debug.apk` en releases/tag/v0.3.4; QR apk-debug/qr-instalar-v0.3.4.png).
  Checklist del dueño: (1) EN EL EQUIPO NUEVO: instalar v0.3.4 y sincronizar — la primera sync
  ahora auto-repara y baja el catálogo completo (~428 productos + precios); (2) template Magic
  Link con {{ .Token }} en Supabase Studio (pasos HTML dados al dueño) + instalar v0.3.4 en su
  teléfono y reintentar la vinculación de email; resto: auth_uid en tabla, sync post-vínculo, C1
  completo (~428), T4, admin.
- L17 — VALIDACIÓN DE CAMPO v0.3.4 (equipo nuevo, usuario Noe): la sincronización funcionó
  correctamente — el fix de auto-reparación de padres queda validado en campo y C1 (catálogo
  completo en primera sync de instalación nueva) queda VALIDADO. Restan del checklist: template
  Magic Link con {{ .Token }} (el dueño aún no lo pegó), vinculación de email en el teléfono del
  dueño, auth_uid en tabla, sync post-vínculo, T4 (segunda instalación CON la misma cuenta — Noe
  era identidad anónima propia, no restaura), prueba admin.
- L18 — DECISIÓN DEL DUEÑO: la vinculación de cuenta por email se POSTERGA («No quiero tocar a
  cuenta google, dejemos lo de confirmar el email para mucho mas adelante, por ahora sigo con un
  grupo reducido y de confianza para realizar las pruebas»). El bloqueante real: Supabase exige
  SMTP propio para editar la plantilla (hallazgo de campo: sin SMTP custom el email manda enlace,
  no código — los campos Subject/Body están deshabilitados en el panel). La app sigue 100%
  usable: identidades anónimas + sync colaborativa cubren el grupo de confianza (la cuenta siempre
  fue opcional, R17). POSTERGADOS hasta nueva decisión del dueño: SMTP propio, template Magic
  Link con {{ .Token }}, vinculación de email, auth_uid en tabla (verificación), sync
  post-vínculo, T4 (restauración con la misma cuenta), prueba admin. El código T3/T4 queda
  commiteado y probado (suite verde), listo para activar cuando se retome. Con C1 validado en
  campo (L17), la validación de campo del alcance vigente de T5 queda COMPLETA.
