# Fase 0 — Fundaciones

Implementación de la Fase 0 de Seguidor de Precios: repo/convenciones, proyecto Flutter con
estructura feature-first, esqueleto de navegación y CI básica. Fuente normativa: `README.md` +
`docs/` (requisitos R1–R18, decisiones AD-001–015, hoja-de-ruta Fase 0).

## Specs

S1 — "**Repo Git + `.gitignore` estándar (Flutter/Dart)**" (hoja-de-ruta 0.1). El `.gitignore` de
raíz ya existe (excluye `pdt-*.md` y `.atl/`, directiva del dueño); se completa con lo estándar de
Flutter/Dart. El proyecto Flutter vive en `app/`.

S2 — "**Proyecto Flutter + estructura de carpetas (feature-first)**" (0.2). Android-only (R2);
mínimo soportado objetivo API 24 (R2); package `seguidor_precios`, org `com.seguidorprecios`.
Estructura: `lib/main.dart`, `lib/app.dart`, `lib/features/{inicio,escaner,articulos,historial,comercios}`, `lib/shared/`.

S3 — "**Esqueleto de navegación con pantallas placeholder (inicio, escanear, artículos, historial, comercios)**" (0.3). UI en español rioplatense (AD-007); NavigationBar inferior con las 5 secciones; pantallas placeholder con título; smoke test de widget.

S4 — "**CI básica: `flutter analyze` + `flutter test` en GitHub Actions**" (0.4). Workflow en
`.github/workflows/ci.yml` sobre ubuntu-latest, canal stable.

S5 — "**Validar el mínimo soportado (objetivo: API 24) en emulador/dispositivo real**" (0.5, R2).
Si no hay emulador/dispositivo disponible, queda pendiente y se reporta; como evidencia mínima, CI
compila `apk --debug` para validar el target Android.

**Criterio de salida (hoja-de-ruta):** "la app corre en un dispositivo/emulador y navega entre
pantallas vacías; CI en verde."

## Tasks

- T1 — [S1] Completar `.gitignore` raíz con estándar Flutter/Dart. ✅ commit `806b074`
- T2 — [S2] `flutter create` en `app/` + reorganización feature-first + smoke test. ✅ commit `8c764ba` (baseline; estructura y smoke test en `9ca1f88`)
- T3 — [S3] Shell de navegación + 5 pantallas placeholder. ✅ commit `9ca1f88`
- T4 — [S4] Workflow de CI. ✅ commit `7bf929c` — CI verde en GitHub para ese sha (conclusión `success`, ~3 min: analyze + test + apk --debug)
- T5 — [S5] `apk --debug` compilado en CI ✅; validación en dispositivo/emulador ⏳ **pendiente de hardware** (sin Android SDK local)

## Log

- L1 — Pedido del dueño (verbatim): "inicie. Evaluar por etapas, para evitar acumular errores." —
  autoriza la implementación y fija el modo: evaluación por etapas (esta fase = Fase 0; al cerrarla
  se reporta y se espera la evaluación del dueño antes de Fase 1).
- L2 — Decisiones técnicas de la fase (agente, dentro de lo acordado): proyecto Android-only,
  `--org com.seguidorprecios --project-name seguidor_precios` en `app/`; Material 3;
  NavigationBar inferior; CI con `subosito/flutter-action`.
- L3 — Resultados (2026-10-26): Flutter 3.47.8 stable instalado en `D:/Desarrollo/flutter` (sin Android SDK local; `flutter doctor` marca solo Android toolchain ausente). `flutter analyze` sin issues; `flutter test` 1/1 verde (navegación entre las 5 secciones en el shell). CI de GitHub en verde (analyze + test + apk --debug). **Criterio de salida: parcial** — navegable verificado por pruebas de widget; la corrida en dispositivo/emulador queda pendiente de hardware (T5).
