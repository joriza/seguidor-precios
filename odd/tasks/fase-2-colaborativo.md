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
  Commit: pendiente.
- T5 — Enriquecimiento EAN desconocido (S3): consulta Open Food Facts API v2 con conexión al
  escanear EAN inexistente; precarga nombre/marca/contenido confirmada por el usuario; offline
  o sin resultado → flujo manual actual. Route: worker, tras T4. Superficie:
  `app/lib/features/escaner/**`, `app/lib/data/enriquecimiento.dart`, `app/pubspec.yaml` (http).
  Commit: pendiente.
- T6 — Docs de la fase al día (S5): AD-016 creada; tabla de decisiones abiertas actualizada;
  `modelo-de-datos.md` (valoraciones sync-only); `hoja-de-ruta.md` (estado Fase 2 aprobada);
  `desarrollo.md` + `README.md` (estados vigentes). Commit: docs de este cierre (ver Log L3).
  Falta: docs final con DDL Postgres y nota de operación al cerrar la fase.
- T7 — Release v0.2.0 + QR + validación en teléfono (S5). BLOQUEADO por el dueño: crear proyecto
  Supabase (free, región sa-east-1, activar anonymous sign-ins), aplicar SQL en Studio, pasar
  Project URL + anon key, ejecutar T3, y dar visto de publicación.

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
