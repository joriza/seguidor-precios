# Hoja de ruta

## Fase 0 — Fundaciones

*Prevista: ~1 semana. Estado: pendiente.*

| # | Tarea |
| --- | --- |
| 0.1 | Repo Git + `.gitignore` estándar (Flutter/Dart) |
| 0.2 | Proyecto Flutter + estructura de carpetas (feature-first) |
| 0.3 | Esqueleto de navegación con pantallas placeholder (inicio, escanear, artículos, historial, comercios) |
| 0.4 | CI básica: `flutter analyze` + `flutter test` en GitHub Actions |

**Criterio de salida:** la app corre en un dispositivo/emulador y navega entre pantallas vacías; CI en verde.

## Fase 1 — MVP 100% local (R1, R2, R3, R5, R6, R7, R8, R9, R10, R11, R12)

*Prevista: ~3-4 semanas (creció por el catálogo semilla y el comparador por artículo). Estado: pendiente.*

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
| 1.10 | Historial por producto con variación % | R8 |
| 1.11 | Mínimo, promedio y máximo por artículo (30 días por defecto / histórico, filtro por comercio) | R12 |
| 1.12 | Búsqueda y listado por producto y por artículo | R1 |
| 1.13 | Backup/export JSON + CSV, e importación | R3, R5 |

**Criterio de salida:** con modo avión: escanear un EAN del catálogo semilla → registrar su precio
en un comercio nuevo → abrir el comparador del artículo y ver el precio por unidad con mínimo y
promedio; el backup restaura en otra instalación.

## Fase 2 — Colaborativo (R4, R5, R10, R14, R15, R17)

*Prevista: ~2-3 semanas. Estado: pendiente.*

| # | Tarea | Cubre |
| --- | --- | --- |
| 2.1 | Proyecto Supabase + esquema espejo + RLS + auth anónimo | AD-002, AD-003 |
| 2.2 | Outbox local + push/pull incremental por `actualizado_en` | arquitectura |
| 2.3 | Dedup por código de barras (RPC/trigger en Postgres) | R4 |
| 2.4 | Ping mínimo keep-alive al iniciar (con conectividad); cron de GitHub Actions como complemento opcional | R14, AD-010 |
| 2.5 | Indicador de estado de sync + sync manual (pull-to-refresh) | UX |
| 2.6 | Carga inicial del catálogo semilla en Supabase (por lotes) | R10 |
| 2.7 | Enriquecimiento: EAN desconocido con red → precarga desde la API abierta, confirmada por el usuario | R10 |
| 2.8 | Aviso de sync al iniciar: solo WiFi + (cambios locales pendientes o >7 días), con confirmación del usuario | R15, AD-010 |
| 2.9 | Login opcional: enlace mágico por email que vincula el usuario anónimo a una cuenta | R17, AD-003 |

**Criterio de salida:** dos instalaciones se ven los datos mutuamente; el mismo EAN de dos usuarios
converge en un solo producto; sin conexión todo sigue funcionando; un EAN desconocido se precarga
desde la fuente abierta. El aviso de sync respeta las condiciones de R15 y la app nunca
sincroniza sin confirmación. Con la misma cuenta en dos instalaciones, un usuario recupera sus
datos propios (R17).

## Fase 3 — Valor agregado (post-MVP)

Agregados filtrados por comercio en la pantalla del artículo · inflación por artículo (variación %
mensual) · listas de compras · alertas de subas · coincidencia difusa para sugerir artículos
(productos sin EAN) · aviso de nueva versión.

## Fase 4 — Público e infraestructura propia (condicional, R16)

*Se ejecuta **solo si** el proyecto tiene aceptación real y se decide liberarlo al público. Estado: condicional.*

| # | Tarea | Cubre |
| --- | --- | --- |
| 4.1 | Decidir infraestructura propia: VPS/servidor del dueño; Supabase self-hosted (Docker) o Postgres + PostgREST | R16, AD-011 |
| 4.2 | Migración de datos: `pg_dump`/`restore` + verificación; cambio de URL del backend (config) | R16 |
| 4.3 | Anti-abuso para público: rate limiting, revisión de RLS, política de moderación | AD-010, decisión abierta |
| 4.4 | Operación: backups automáticos, monitoreo, actualizaciones de seguridad | AD-011 |
| 4.5 | Distribución pública: APK + aviso de actualización, o Play Store (decisión abierta) | AD-006 |
| 4.6 | Política de privacidad y atribuciones visibles (ODbL, Open Food Facts) | AD-008 |

**Criterio de salida:** la app pública funciona contra infraestructura propia con los mismos datos
migrados; backups y monitoreo activos.

## Riesgos

| # | Riesgo | Mitigación |
| --- | --- | --- |
| 1 | Pausa del backend gratuito (Supabase, ~7 días sin uso) | Ping programado o reactivación manual; los datos viven en el teléfono (R3 nunca comprometida) |
| 2 | Productos duplicados entre usuarios (mismo producto, nombre distinto) | Dedup por EAN en Fase 2; coincidencia difusa en Fase 3 |
| 3 | Escáner con cámaras de baja calidad | ML Kit on-device es robusto; ingreso manual siempre disponible (R6) |
| 4 | Dependencia de paquetes de terceros de Flutter | Elegir paquetes muy adoptados; capa de datos aislada para poder reemplazarlos |
| 5 | Cobertura argentina parcial de Open Food Facts (no está todo el mercado) | Alta manual + colaborativa, enriquecimiento progresivo por API y datos.gob.ar (Precios Claros) como fuente complementaria |
| 6 | Productos sin contenido neto o sin artículo no comparables | Alta guiada que pide unidad y contenido; asignación de artículo sugerida por categoría/nombre |
| 7 | Liberación al público: abuso de escrituras anónimas y moderación | Rate limiting + RLS revisada; etapa planificada como condicional en Fase 4 (AD-011) |
