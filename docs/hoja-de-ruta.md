# Hoja de ruta

## Fase 0 — Fundaciones

*Estado: **completada** (v0.1.0).*

| # | Tarea |
| --- | --- |
| 0.1 | Repo Git + `.gitignore` estándar (Flutter/Dart) |
| 0.2 | Proyecto Flutter + estructura de carpetas (feature-first) |
| 0.3 | Esqueleto de navegación con pantallas placeholder (inicio, escanear, artículos, historial, comercios) |
| 0.4 | CI básica: `flutter analyze` + `flutter test` en GitHub Actions |
| 0.5 | Validar el mínimo soportado (objetivo: API 24) en emulador/dispositivo real |

**Criterio de salida:** la app corre en un dispositivo/emulador y navega entre pantallas vacías; CI en verde.

## Fase 1 — MVP 100% local (R1, R2, R3, R5, R6, R7, R8, R9, R10, R11, R12, R13, R17)

*Estado: **completada** (v0.1.5).*

| # | Tarea | Cubre |
| --- | --- | --- |
| 1.1 | Esquema local (drift): artículo, producto, comercio, precio, usuario + índices y vista `resumen_articulo` | modelo de datos |
| 1.2 | Script `tools/seed`: dump de Open Food Facts / Open Products Facts → pack JSON filtrado por Argentina (EAN-13, nombre, marca, contenido neto) | R10 |
| 1.3 | Import del pack semilla en el primer inicio (en segundo plano, origen `semilla`) | R10 |
| 1.4 | Escáner con cámara + campo manual de código | R6 |
| 1.5 | Alta/edición de producto: con/sin EAN, marca, unidad, contenido neto, artículo sugerido | R1, R7, R11 |
| 1.6 | Administración de artículos: alta, renombre, asignar producto ↔ artículo | R11 |
| 1.7 | Alta de comercio en el momento desde el registro de precio | R9 |
| 1.8 | Registro de precio con fecha de toma (hoy por defecto, editable) | R8, R1 |
| 1.9 | Precio por unidad de medida + comparador con jerarquía: producto por EAN primero, artículo después (orden por $/unidad, mínimo resaltado) | R11, R13 |
| 1.10 | Historial por producto y por comercio, con variación % | R8 |
| 1.11 | Mínimo, promedio y máximo por artículo (30 días por defecto / histórico, filtro por comercio) | R12 |
| 1.12 | Búsqueda y listado por producto y por artículo | R1 |
| 1.13 | Backup/export JSON + CSV, e importación | R3, R5 |
| 1.14 | Etiqueta de aportante en el primer inicio (guardada en el dispositivo, viaja con cada dato) | R17 |
| 1.15 | Primer APK de pruebas publicado en GitHub Releases | R2, AD-006 |

**Criterio de salida:** con modo avión: escanear un EAN del catálogo semilla → registrar su precio
en un comercio nuevo → abrir el comparador del artículo y ver el precio por unidad con mínimo y
promedio; el backup restaura en otra instalación.

## Fase 2 — Colaborativo (R4, R5, R10, R14, R15, R18)

*Estado: **cerrada y validada** — implementada, probada en el dispositivo del dueño con sync real
verificada en servidor, releases v0.2.0/v0.2.1/v0.2.2 publicados y mergeada a `main`. Correctivos de
campo aplicados en caliente: migraciones 0002-0004 y backfill v4. El juicio dual previo a Fase 3
confirmó 2 críticos del pull (C1 paginación con timestamps iguales, C2 colisión de EAN local vs
servidor) que pasaron a Fase 3 con prioridad máxima — ver Log L20 del ODD — y quedaron corregidos
en `fase-3` (d04dea1: pull keyset por (actualizado_en, id) + convergencia de ids de semilla).*

| # | Tarea | Cubre |
| --- | --- | --- |
| 2.1 | Proyecto Supabase + esquema espejo (incluida `valoracion`) + RLS + auth anónimo | AD-002, AD-003 |
| 2.2 | Outbox local + push/pull incremental por `actualizado_en` | arquitectura |
| 2.3 | Dedup por código de barras (RPC/trigger en Postgres) | R4 |
| 2.4 | Ping mínimo keep-alive al iniciar (con conectividad); cron de GitHub Actions como complemento opcional | R14, R5, AD-010 |
| 2.5 | Indicador de estado de sync + sync manual (pull-to-refresh) | UX |
| 2.6 | Carga inicial del catálogo semilla en Supabase (por lotes) | R10 |
| 2.7 | Enriquecimiento: EAN desconocido con red → precarga desde la API abierta, confirmada por el usuario | R10 |
| 2.8 | Aviso de sync al iniciar: solo WiFi + (cambios locales pendientes o >7 días), con confirmación del usuario | R15, AD-010 |
| 2.9 | Mantenimiento de datos vía Supabase Studio (procedimiento); web admin del dueño cuando el panel quede corto | R18, AD-013 |

**Criterio de salida:** dos instalaciones se ven los datos mutuamente; el mismo EAN de dos usuarios
converge en un solo producto; sin conexión todo sigue funcionando; un EAN desconocido se precarga
desde la fuente abierta. El aviso de sync respeta las condiciones de R15 y la app nunca
sincroniza sin confirmación. El dueño mantiene los datos (asignar artículos, corregir duplicados)
vía Supabase Studio (R18).

## Fase 3 — Valor agregado (post-MVP)

*Estado: **en curso** — arrancada con los críticos C1/C2 (corregidos en d04dea1) y la cuenta
multi-dispositivo 3.7 (magic link por email + convergencia de identidad, implementada en d84bf53/b7abaa7
con migración 0005). La validación de campo corrigió la vinculación de cuenta en v0.3.3: el flujo
PKCE por defecto de supabase-dart exige un storage que la app no provee y `signInWithOtp` rompía
con AssertionError antes de tocar la red; ahora usa flujo implícito (código de 6 dígitos in-app,
sin deep links). En v0.3.4 el pull se vuelve auto-reparante: los padres ausentes de un precio o
valoración (y el artículo de un producto) se traen por id desde el servidor antes de insertar —
un servidor que aterriza filas a mitad de sesión ya no rompe la FK (L15 del ODD). El resto de
las tareas (3.1-3.6, 3.8 y el backlog de mejoras #1-#8) se prioriza con datos de uso reales. La
vinculación de cuenta por email queda POSTERGADA por decisión del dueño (2026-10-30): el grupo de
confianza continúa con identidades anónimas; el código T3/T4 queda listo para activar cuando se
configure SMTP propio.*

| # | Tarea | Cubre |
| --- | --- | --- |
| 3.1 | Comparación de comercios lado a lado en la pantalla del artículo | R8, R12 |
| 3.2 | Inflación por artículo (variación % mensual) | R12 |
| 3.3 | Listas de compras | — |
| 3.4 | Alertas de subas | — |
| 3.5 | Coincidencia difusa para sugerir artículos (productos sin EAN) | R11 |
| 3.6 | Aviso de nueva versión dentro de la app | AD-006 |
| 3.7 | Cuenta opcional multi-dispositivo con enlace mágico (diferida de la etapa de pruebas) | R17, AD-003 |
| 3.8 | Web de administración del dueño (si Studio quedó corto) | R18, AD-013 |

**Criterio de salida:** se define al priorizar la fase con datos de uso reales.

## Fase 4 — Público e infraestructura propia (condicional, R16)

*Se ejecuta **solo si** el proyecto tiene aceptación real y se decide liberarlo al público. Estado: condicional.*

| # | Tarea | Cubre |
| --- | --- | --- |
| 4.1 | Decidir infraestructura propia: VPS/servidor del dueño; Supabase self-hosted (Docker) o Postgres + PostgREST | R16, AD-011 |
| 4.2 | Migración de datos: `pg_dump`/`restore` + verificación; cambio de URL del backend (config) | R16 |
| 4.3 | Anti-abuso para público: rate limiting, revisión de RLS, política de moderación | AD-011, decisión abierta |
| 4.4 | Operación: backups automáticos, monitoreo, actualizaciones de seguridad | AD-011 |
| 4.5 | Distribución pública: APK + aviso de actualización, o Play Store (decisión abierta) | AD-006 |
| 4.6 | Política de privacidad y atribuciones visibles (ODbL, Open Food Facts) | AD-008 |

**Criterio de salida:** la app pública funciona contra infraestructura propia con los mismos datos
migrados; backups y monitoreo activos.

## Backlog de mejoras de producto (propuestas, pendientes de priorizar)

*Propuestas del 2026-10-28 (más #9 del 2026-10-30), pendientes de priorizar. Fuera de este
backlog quedan los 2 críticos del pull confirmados por el juicio (C1/C2, Log L20 del ODD), ya
corregidos y validados en campo (v0.3.4, L17 fase-3).*

***Orden acordado (2026-10-30, el dueño delega la priorización):**
1. #8 búsqueda ≥3 caracteres — **HECHA (v0.3.5)**;
2. #9 escáner como pantalla por defecto + #4 texto del escáner — **HECHA (v0.3.5)**;
3. #7 producto sin EAN con código interno `S-<TOK>-<NNNN>` — **HECHA (v0.3.5)**;
4. #10 packs/combos — evaluación del padre (2026-10-30): el problema real es la corrección del
   precio normalizado cuando el precio se carga por un pack. Recomendación en dos pasos:
   **(a) liviano y correcto** — calculadora de pack en el formulario (pack de 10 × 500 g →
   completa `contenido_neto = 5000`), sin migraciones; **(b) completo después** — campo
   `unidades_por_pack` en producto (migración local v5 + servidor 0006) para registrar la
   presentación explícitamente. El artículo ya agrupa presentaciones de un mismo producto;
5. #1 clasificación en lote + sugerencia de artículo desde OFF;
6. #5 verificar EAN al abrir el formulario;
7. #3 «Completar desde OFF»;
8. #2 catálogo vivo (gran parte ya cubierta por el fix C1: la instalación nueva baja el
catálogo completo; resta achicar la semilla offline);
9. #6 foto del producto.
Después: tareas Fase 3 (3.1-3.6, 3.8).*

| # | Fricción | Mejora propuesta |
| --- | --- | --- |
| 1 | Clasificación manual: los productos semilla nacen sin artículo y asignarlos es tarea individual. OFF ya trae categorías que hoy se descartan | Enriquecimiento sugiere artículo (mapeo categoría OFF → artículos propios); pantalla de clasificación en lote |
| 2 | Semilla congelada: la instalación nueva recibe el pack de v0.1.1 por APK y nunca se actualiza | Con nube activa: instalación nueva = seed mínimo offline + pull del catálogo real del servidor (la semilla queda como plan B sin conexión) |
| 3 | Enriquecimiento solo al crear: productos viejos o mal cargados nunca se completan desde OFF | Botón “Completar desde OFF” en la ficha de producto (para productos con EAN y datos flojos) |
| 4 | Mensaje desactualizado del escáner: dice “crealo desde la sección Artículos (Fase 1.5)” pero el escáner ya abre el formulario con precarga | Corregir el texto (trivial) — **HECHA en v0.3.5** |
| 5 | EAN duplicado se descubre tarde: el aviso llega recién al guardar | Verificar el EAN al abrir el formulario y ofrecer “ir al producto existente” |
| 6 | OFF trae más datos útiles que se descartan (imagen del producto, nutrición) | Fase 3+: foto del producto en la ficha |
| 7 | Artículos sin código de barras (verdulería de barrio): hoy no entran al sistema los productos a granel | Alta de producto sin EAN con código interno secuencial asignado por la app; buscable por ese código o descripción (propuesta del dueño, 2026-10-30) — **HECHA en v0.3.5 con diseño v2 `S-<TOK>-<NNNN>` sin colisiones** |
| 8 | Búsqueda solo por escaneo de EAN: no hay búsqueda manual de producto | Búsqueda combinada por número de EAN o descripción, que arranca a partir de 3 caracteres (propuesta del dueño, 2026-10-30) — **HECHA en v0.3.5** |
| 9 | El uso principal es escanear para consultar/agregar, pero la app abre en Inicio | Que el escáner sea la pantalla por defecto al abrir la app (propuesta del dueño, 2026-10-30) — **HECHA en v0.3.5** |
| 10 | Packs y combos: galletitas sueltas o pack x3/x5; yerba o fideos en pack x10 — el precio publicado es por pack y el precio normalizado sale mal si no se carga el contenido TOTAL del pack. Casos extra del debate (2026-10-30): packs SIN código propio (escanear el unitario y querer registrar el precio del pack) y papel higiénico (packs de 2/4/6/12 con rollos de distinta longitud → normalizar en METROS) | Debate de diseño abierto con el dueño: modelo «producto = presentación con contenido total; precio opcionalmente por N unidades»; evaluar calculadora de pack (sin migraciones), `precio.unidades` (migración 0006) y unidad «m» para rollos — **prioridad alta, en discusión** |

## Riesgos

| # | Riesgo | Mitigación |
| --- | --- | --- |
| 1 | Pausa del backend gratuito (Supabase, ~7 días sin uso) | Ping mínimo desde la app al iniciar (R14); cron como complemento; reactivación manual sin costo. Los datos viven en el teléfono (R3 nunca comprometida) |
| 2 | Productos duplicados entre usuarios (mismo producto, nombre distinto) | Dedup por EAN en Fase 2; coincidencia difusa en Fase 3 |
| 3 | Escáner con cámaras de baja calidad | ML Kit on-device es robusto; ingreso manual siempre disponible (R6) |
| 4 | Dependencia de paquetes de terceros de Flutter | Elegir paquetes muy adoptados; capa de datos aislada para poder reemplazarlos |
| 5 | Cobertura argentina parcial de Open Food Facts (no está todo el mercado) | Alta manual + colaborativa, enriquecimiento progresivo por API y datos.gob.ar (Precios Claros) como fuente complementaria |
| 6 | Productos sin contenido neto o sin artículo no comparables | Alta guiada que pide unidad y contenido; asignación de artículo sugerida por categoría/nombre |
| 7 | Liberación al público: abuso de escrituras anónimas y moderación | Rate limiting + RLS revisada; etapa planificada como condicional en Fase 4 (AD-011) |
| 8 | Atribución por etiqueta sin seguridad (alguien puede firmar como otro) | Aceptado en etapa de pruebas (grupo de confianza); la cuenta opcional de Fase 3 lo resuelve si hiciera falta |
