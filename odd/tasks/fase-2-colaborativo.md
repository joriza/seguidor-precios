# Fase 2 — Colaborativa (Supabase + sync)

Plan aprobado por el dueño. Implementación delegada a subagentes (`gentle-ai-worker`) para
preservar el contexto principal (directiva del dueño). Fuente normativa: `docs/requisitos.md`
(R4, R5, R10, R14, R15, R18), `docs/arquitectura.md` (reglas de sync 1-9), `docs/hoja-de-ruta.md`
(tareas 2.1-2.9), ADRs AD-002/003/008/010/013/015/016.

## Specs

S1 — "ejecute todo lo que pueda en subagentes para preservar el contexto principal" → el padre
orquesta, delega la implementación por unidades con superficies de edición disjuntas y comitta
por unidades revisables; los workers no comittean.

S2 — Valoraciones, selección "Solo sincronizarlas": "Se sincronizan pero la ponderación con
otros usuarios se deja para después; la fase queda más chica." → `valoracion` viaja en la sync;
sin UI de ponderación comunitaria en esta fase.

S3 — Enriquecimiento, selección "Incluir en Fase 2": "Al escanear un EAN que no está, la app
consulta la API abierta y precarga nombre/marca/contenido; siempre lo confirmás vos antes de
guardar." → precarga desde Open Food Facts con conexión, siempre confirmada por el usuario;
sin conexión o sin resultado, flujo manual actual.

S4 — Moderación, selección "Mínima (recomendada)": "RLS: cada uno borra (lógico) solo lo suyo;
correcciones de clasificación abiertas; vos corregís el resto vía Studio. Suficiente para grupo
de confianza." → registrada como AD-016; rate limiting/política seria diferida a Fase 4.

S5 — Comportamiento colaborativo canónico (docs vigentes): fuente de verdad local (R3); outbox +
push/pull incremental con merge última-escritura-gana; precios append-only (cursor `cargado_en`
normalizado por el servidor); borrado lógico; dedup por EAN con re-apunte local de precios;
identidad anónima (`signInAnonymously`, `auth_uid`); ping mínimo al iniciar con conectividad
(R14); aviso de sync solo con WiFi + (outbox pendiente o >7 días) y confirmación (R15);
sync manual siempre disponible; indicador de estado; carga inicial del semillero por lotes (R10).

## Tasks

- T1 — Esquema backend SQL (S4, S5): `supabase/migrations/` — 6 tablas espejo (incluida
  `valoracion`), índices (único parcial `codigo_barras`), trigger `actualizado_en` del servidor,
  RPC `ping()`, RPC dedup por EAN (re-apunte server-side de precios), RLS mínima (AD-016) +
  admin uid fijo (AD-015, placeholder `<<UID_DUENO>>`), y `supabase/migracion-completa.sql`
  (archivo único para pegar en Studio). Route: worker A, paralelo. Superficie: `supabase/**`.
  Commit: `f1ac623`.
- T2 — Núcleo de sync en la app (S1, S5): punto único de configuración backend (URL + anon key),
  migración local v3 (outbox por tabla+id, cursor por tabla, marca global de última sync
  exitosa), push por lotes (usuario → articulo → producto → comercio → precio → valoracion),
  pull incremental LWW con borrado lógico, identidad anónima + `auth_uid`, re-apunte local de
  precios tras dedup, tests con cliente falso (sin red). Route: worker B, paralelo. Superficie:
  `app/lib/data/**`, `app/lib/main.dart`, `app/pubspec.yaml`, `app/test/**`. Commit: `1e2d7b7`.
- T3 — Tool de carga del semillero (S5): script en `tools/` que sube el pack semilla a Supabase
  por lotes usando clave de servicio desde `.env` (nunca commiteado); reutiliza el pack de
  `app/assets/seed/` y el orden de dependencias de T2. Route: worker C, paralelo. Superficie:
  `tools/**`. Commit: `907e543`.
- T4 — UX de red (S5): ping R14 al iniciar con cualquier conectividad; aviso de sync al iniciar
  bajo condiciones de R15 con confirmación; indicador de estado de sync + sync manual
  (pull-to-refresh). Route: worker, tras T2. Superficie: `app/lib/features/**`,
  `app/lib/app.dart`, `app/lib/main.dart` (cableado de arranque) y hooks de encolado en repos de
  `app/lib/data/**` (producto/comercio/precio aún no encolan; no modificar el núcleo de sync).
  Commit: `9f294dc`.
- T5 — Enriquecimiento EAN desconocido (S3): consulta Open Food Facts API v2 con conexión al
  escanear EAN inexistente; precarga nombre/marca/contenido confirmada por el usuario; offline
  o sin resultado → flujo manual actual. Route: worker, tras T4. Superficie:
  `app/lib/features/escaner/**`, `app/lib/data/enriquecimiento.dart`, `app/pubspec.yaml` (http).
  Commit: `156d528`.
- T6 — Docs de la fase al día (S5): AD-016 creada; tabla de decisiones abiertas actualizada;
  `modelo-de-datos.md` (valoraciones sync-only); `hoja-de-ruta.md` (estado Fase 2 aprobada);
  `desarrollo.md` + `README.md` (estados vigentes). Commit: `8d8743f` — DDL final documentado
  (modelo-de-datos § Esquema backend) y runbook de operación (desarrollo.md); sin pendientes.
- T7 — Release v0.2.0 + QR + validación en teléfono (S5). Backend creado por el dueño y
  semillero cargado (Log L11); release v0.2.0 PUBLICADO vía GitHub Actions (`fb550d8`, CI run
  40735111050, APK `seguidor-precios-v0.2.0-debug.apk` 186 MB, título y notas corregidos a
  Fase 2). PENDIENTE del dueño: instalar vía QR y validar en teléfono (sync real, indicador,
  enriquecimiento OFF), comunicar su `auth_uid` para activar admin (AD-015, reemplaza
  `<<UID_DUENO>>`), y decidir merge de `fase-2-colaborativo` a `main`.

## Log

- L1 — "ejecute todo lo que pueda en subagentes para preservar el contexto principal" (verbatim,
  2026-10-28): delegación obligatoria de la implementación; el padre orquesta y comitta.
- L2 — Decisiones del dueño (cuestionario del plan): valoraciones "Solo sincronizarlas" (S2);
  enriquecimiento "Incluir en Fase 2" (S3); moderación "Mínima (recomendada)" (S4).
- L3 — "actualice documentación y cierre acá, continuo luego" (verbatim): cierre con ODD creado
  y docs al día — commit `4c0b825` (rama `fase-2-colaborativo`): AD-016, valoraciones sync-only
  en modelo-de-datos, estado Fase 2 aprobada en hoja-de-ruta, estados vigentes en
  desarrollo/README; aviso MD060 de desarrollo.md ya no aplica (tabla única con separadores
  consistentes). Pendiente para próxima sesión: T1-T3 en paralelo por workers (superficies
  disjuntas), luego T4, T5, T6 final y T7 (requiere proyecto Supabase del dueño).
- L4 — T3 completada y commiteada (`907e543`): `tools/cargar_semilla_supabase.py` (stdlib,
  sin dependencias nuevas) + 18 tests unittest verdes; dry-run 424 productos válidos;
  upsert idempotente `on_conflict=id` con UUIDv5 por EAN; `.env` agregado a `.gitignore`
  (+ `__pycache__/`); ejecución real contra Supabase supeditada a T7 (proyecto del dueño).
  Verificar al integrar: nombres de columna vs DDL final de T1 y objetivo de conflicto del
  upsert (el índice único parcial no puede ser target de PostgREST).
- L5 — Frontera de slice de entrega (registro histórico al momento): 611 líneas authoradas en 3
  commits desde `main` (T1-T3). Estrategia de entrega de la fase: release v0.2.0 (T7) tras cerrar
  T1-T6; sin PR intermedio (repositorio del dueño, rama de fase).
- L6 — T1 completada y commiteada (`f1ac623`): `supabase/migrations/0001_esquema_colaborativo.sql`
  (564 líneas) + `supabase/migracion-completa.sql` (578, DDL byte-idéntico verificado); 6 tablas
  espejo con columnas snake_case de `tablas.dart`, 24 políticas RLS (AD-016), guardia de borrado
  lógico por trigger, `dedup_ean` SECURITY DEFINER, `ping()`; verificación 100% estática — SIN
  ejecución contra Postgres real (sin psql, Docker caído). VALIDADO por el dueño en Supabase
  Studio (2026-10-28): "Success. No rows returned", 6 tablas creadas.
- L7 — Decisiones del dueño sobre modelos de workers (2026-10-28): "por ahora dejemos modelo auto
  para los workers" (se mantiene `freellmapi/auto` + fallback ling-3.0-flash en settings) y "es
  posible indicar que solo sea un worker maximo por vez?" → política de orquestación: máximo 1
  worker activo por vez (lanzamientos serializados por el padre), preservando la delegación y el
  contexto principal; el paralelismo entre workers queda postergado hasta que el router lo
  soporte o el dueño lo pida.
- L8 — T2 completada y commiteada (`1e2d7b7`): núcleo de sync (outbox v3, push/pull LWW,
  identidad anónima con sesión persistida en archivo, re-apunte local tras dedup) + adapter
  `ClienteSupabase` (supabase ^2.16.5) + 30 tests sin red; suite completa 151/151. Desviación
  aceptada: identificadores en español (consistente con el 100% del código existente).
  Contrapueba T2↔T1 del padre detectó el gap de contrato (el adapter no llamaba `dedup_ean`;
  un duplicado de EAN rompería el push con 23505 contra el índice único parcial): corregido
  test-first — el push consulta el RPC y re-apunta local sin subir el duplicado, fiel a la
  regla 6 literal (sin merge de campos entre filas); el test previo que esperaba merge LWW de
  campos se ajustó al contrato. `pubspec.lock` de app commiteado (práctica estándar Flutter).
  Pendiente de ejercicio real con red: T7.
- L9 — T4 completada y commiteada (`9f294dc`): ping R14 al iniciar, aviso R15 (solo WiFi +
  pendientes o >7 días; decisión testeada: “nunca sincronizó” con outbox vacío NO cuenta como
  >7 días — no molesta a instalaciones nuevas), indicador de estado en AppBar con diálogo y
  “Sincronizar ahora”, pull-to-refresh en 4 listas, 4 repos con encolado (producto/comercio/
  precio/artículo) re-wire de las 4 pantallas; núcleo de sync intacto. Suite 179/179. Decisión
  registrada: main.dart crea ClienteSupabase solo si `estaConfigurada` — con config real del
  dueño (2026-10-28) el arranque ya hace ping/sync real; ejercicio en dispositivo: T7.
- L10 — Claves del proyecto Supabase del dueño: las legacy JWT (anon/service_role) están
  DESACTIVADAS en su proyecto (403 con JWT bien formado, 219 chars exactos) — el proyecto
  usa el sistema nuevo de claves. Pivot a claves nuevas: `sb_publishable_...` (va a
  config_backend.dart, pública por diseño AD-002) y `sb_secret_...` (solo `.env` del loader).
  Pendiente del dueño: pasar ambas.
- L11 — CORRECCIÓN de L10 (hipótesis de legacy desactivadas: FALSA) y cierre del incidente de
  claves (2026-10-28): diagnóstico con cuerpos de error PostgREST mostró `42501 permission
  denied for table` — las 4 claves autenticaban bien; el rechazo a `anon` (publishable sin
  sesión) es POR DISEÑO (AD-016: solo authenticated lee), y el único defecto real era la
  AUSENCIA de GRANTs para `service_role` en la migración 0001 (el cargador del semillero
  quedaba afuera). Correctivo: migración `0002_permisos_service_role.sql` (`71465fd`, GRANTs
  a service_role + EXECUTE funciones + secuencias), aplicada por el dueño en Studio (Success).
  Claves en uso: legacy anon JWT en `config_backend.dart` (`6b470c7`, verificada: decodifica
  ref/role y el servidor la acepta) y `sb_secret_...` nueva en `.env` para el loader (escrita
  por el dueño con bloque PowerShell Read-Host; el harness bloquea escritura de `.env` por
  política). RESULTADO: semillero cargado y verificado — 424 productos en el servidor
  (`Content-Range: 0-423/424`); upsert idempotente (re-ejecutar no duplica). El backend
  colaborativo quedó OPERATIVO con datos reales; ejercicio de sync en dispositivo: T7.
- L12 — T5 completada y commiteada (`156d528`): puerto ServicioEnriquecimiento + cliente OFF
  API v2 (timeout 6s, mapeo nombre/marca/contenido/unidad), consulta en segundo plano al
  escanear EAN inexistente con guardas anti-carrera, precarga en el form SIEMPRE con
  confirmación (ningún camino guarda solo, testeado), sin conexión/sin resultado → flujo
  manual intacto; +http ^1.6.0; 20 tests nuevos; suite 199/199. Primera consulta real a OFF:
  T7 (dispositivo).
- L13 — T6 completada (`8d8743f`) y release preparado (`f13226c`): docs del DDL backend y
  runbook; versión `0.2.0+6` (el bump de v0.1.5 había quedado salteado — por eso la app
  mostraba 0.1.4); limpieza de 7 warnings de `flutter analyze` (fatales en el CI del release:
  cast/`!` innecesarios y 5 imports sin usar), suite 199/199 re-verificada. Publicación vía
  GitHub Actions (release.yml: analyze+tests+build APK firmado con keystore commiteado →
  release al pushear tag v*); sin SDK local en la máquina (los v0.1.x ya se construían así).
  Merge a main: pendiente de decisión del dueño tras validar el release.
- L14 — RELEASE v0.2.0 PUBLICADO (2026-10-28): tag reubicado con autorización del dueño
  (primer intento falló en CI: el flutter estable del runner trata los infos de analyze como
  fatales — 9 corregidos, `No issues found!` con `--fatal-infos`; sin SDK Android local: los
  APK se construyen en GitHub Actions, release.yml). CI run 40735111050 verde (6m26s):
  analyze + 199 tests + build APK debug firmado (keystore commiteado) + release. Asset
  `seguidor-precios-v0.2.0-debug.apk` (186 MB) verificado descargable (HTTP 206); título y
  notas del release corregidos a Fase 2. QR de descarga: `apk-debug/qr-instalar-v0.2.0.png`
  (gitignored). Mantenimiento workflow pendiente (no bloqueante): actions/checkout apunta a
  Node 20 deprecado. Validación en dispositivo del dueño: ÚNICO check pendiente de la fase.
- L15 — BUG DE CAMPO en la primera sync real del dueño (reportada con v0.2.0: “no se pudo
  sincronizar ahora”, 2 filas pendientes). Diagnóstico por estado del servidor (nada llegó:
  solo semillero) + reproducción vía API con sesión anónima real. DOS causas, ambas
  correctivas aplicadas por el dueño en Studio: (a) 0003 `3507824` — el upsert de la sync
  (ON CONFLICT DO UPDATE) exige privilegio UPDATE aunque la fila sea nueva; 0001 solo daba
  UPDATE por columnas de clasificación → GRANT UPDATE completo a authenticated en las 6
  tablas (RLS y triggers siguen aplicando las invariantes); (b) 0004 `70d075e` —
  ck_comercio_tipo tenía un enum viejo sin supermercado/hipermercado (UI v0.1.3) → CHECK
  eliminado (local es texto libre; espejo). Verificación post-fix vía API: usuario → dedup →
  producto → comercio (supermercado) → precio → pull, todo 200/201. Limpieza: filas de prueba
  borradas con service key (204×4) y 6 usuarios anónimos de prueba eliminados vía admin API;
  servidor queda en estado base (424 productos, 1 usuario semillero). UID DEL DUEÑO
  identificado: `b04e9e8c-3906-4ec0-b16c-643d64331775` (auth user 17:40:12, su intento de
  sync); admin pendiente de activar con CREATE OR REPLACE FUNCTION es_admin() usando ese uid
  (SQL entregado al dueño). Pendiente: retry de “Sincronizar ahora” en el teléfono del dueño.
- L20 — JUICIO (judgment-day, dual ciego) sobre la Fase 2 antes de Fase 3: target inmutable
  `3a4be4c..55b2d53` (sha256 88b674e9…), jueces jd-judge-a/b en paralelo. Resultado: 2
  CRITICAL CONFIRMADOS por ambos (C1: inanición de paginación del pull con ≥100 timestamps
  iguales — un dispositivo nuevo solo baja 100/424 del catálogo; C2: colisión de EAN en el
  pull — ids sem-<ean> locales vs uuid5 del servidor violan el UNIQUE local → el pull del
  teléfono del dueño está roto: sube pero nunca baja, crash antes de guardarCursor), 5
  sospechosos (backfill en dispositivos ya-sincronizados; forja de creado_por vía 0003;
  sesgo de reloj en LWW; usuarioActual sin orden; valoraciones duplicadas), 1 info (sesión
  perdida sin re-login). El dueño decidió NO corregir ahora → veredicto ESCALATED; C1 y C2
  pasan al backlog de Fase 3 con prioridad máxima (C2 deja al teléfono del dueño sin baja de
  datos hasta corregirse). Ledger: apk-debug/judgment-fase2-ledger.json (gitignored).
- L19 — FASE 2 CERRADA Y MERGEADA (2026-10-28): `fase-2-colaborativo` → `main` por
  fast-forward (`3a4be4c..55b2d53`, 28 commits) con autorización del dueño (“mergee fase-2”).
  La rama queda como referencia histórica; los tags v0.2.0/v0.2.1/v0.2.2 ya apuntan a commits
  de la línea principal. Único pendiente administrativo abierto: el dueño aplica el SQL de
  es_admin con su uid (b04e9e8c…) cuando quiera. Fase 3 (login por email, multi-dispositivo)
  queda trazada en docs/hoja-de-ruta.md.
- L17 — Fallo de sync 2.0 (tras 0003/0004 + v0.2.1 con backfill): el push del dueño avanzó
  bien (usuario ✓, los 424 de semilla ✓, cerealitas ✓ y 3 productos viejos v0.1.x ✓ — todo
  al servidor 18:51:51) pero murió en comercio (0) antes de precio. La reproducción por API
  del comercio devolvía 201, así que el error específico era invisible: el gestor atrapaba
  la excepción y la UI mostraba solo “No se pudo sincronizar ahora” (catch (_) sin detalle).
  FIX de transparencia (`0631d7c`): GestorSync expone ultimoError + debugPrint a consola y
  los SnackBar de app.dart/refresco.dart muestran el detalle real. Suite 201/201. Release
  v0.2.2+8 vía CI: el dueño reintenta la sync y el propio teléfono muestra el error exacto
  (o se lee por USB con flutter run adjunto).
- L18 — SYNC REAL VERIFICADA EN SERVIDOR (2026-10-28 19:36:24): el dueño sincronizó desde
  v0.2.1 — comercio: 2 filas reales (Coto, Tino Market, tipo almacen); precio: 7 filas con
  historial v0.1.x (2026-10-19 y 2026-10-27, cargado_en 19:36:24 = hora del push del dueño);
  producto: 428 completos; usuario: identidad joriza con auth_uid. El backfill v4 funcionó
  (sus comercios/precios históricos subieron). Nota menor de UI: el SnackBar de éxito no fue
  visto por el dueño (v0.2.2 mejora la visibilidad de resultados y errores). FASE 2 VALIDADA
  EN DISPOSITIVO. Pendientes administrativos: (1) dueño aplica el SQL de es_admin con su uid
  (opcional, no bloquea); (2) merge fase-2-colaborativo → main (decisión del dueño); (3)
  instalar v0.2.2 en el teléfono (opcional, mejora errores visibles).
- L16 — SEGUNDA causa del fallo de sync del dueño (post-0003/0004): su usuario y producto
  subieron ✓, pero el precio murió en FK — apunta a un comercio de la era v0.1.x que nunca
  entró al outbox (los hooks nacieron en v0.2.0; su outbox tenía exactamente producto+precio,
  como reportó). FIX: migración local v4 (`67aca6c`, v0.2.1+7) — backfill del outbox: encola
  toda fila pre-existente de las 6 tablas (una sola vez por instalación; el push por orden de
  dependencias resuelve las FK). Tests: v4 nuevo (backfill) + v3 actualizado al nuevo contrato
  (backfill deja 6 entradas + 1 manual = 7). Suite 200/200; analyze --fatal-infos limpio.
  Release v0.2.1 vía CI (tag re-push). Nota: el backfill también sube precios históricos
  locales v0.1.x — dato valioso del dueño que queda compartido.
