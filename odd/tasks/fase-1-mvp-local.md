# Fase 1 — MVP 100% local

Implementación de la Fase 1 de Seguidor de Precios: base local completa, escáner, altas,
precios, comparador por artículo, historial, búsqueda, backup y atribución por etiqueta —
todo sin conexión. Fuente normativa: `docs/requisitos.md` (R1–R18), `docs/modelo-de-datos.md`,
`docs/decisiones.md` (AD-004, AD-005, AD-008, AD-013, AD-014), `docs/hoja-de-ruta.md` (Fase 1).

## Specs

S1 — "**Esquema local (drift): artículo, producto, comercio, precio, usuario + índices y vista `resumen_articulo`**" (1.1). Tablas, columnas, índices y reglas según `docs/modelo-de-datos.md` (precios append-only; EAN único parcial; granel contenido neto implícito = 1, AD-014).
S2 — "**Script `tools/seed`: dump de Open Food Facts / Open Products Facts → pack JSON filtrado por Argentina (EAN-13, nombre, marca, contenido neto)**" (1.2, R10).
S3 — "**Import del pack semilla en el primer inicio (en segundo plano, origen `semilla`)**" (1.3, R10).
S4 — "**Escáner con cámara + campo manual de código**" (1.4, R6): ML Kit (`mobile_scanner`), lectura EAN-13/EAN-8/UPC-A, campo editable a mano.
S5 — "**Alta/edición de producto: con/sin EAN, marca, unidad, contenido neto, artículo sugerido**" (1.5, R1, R7, R11).
S6 — "**Administración de artículos: alta, renombre, asignar producto ↔ artículo**" (1.6, R11).
S7 — "**Alta de comercio en el momento desde el registro de precio**" (1.7, R9).
S8 — "**Registro de precio con fecha de toma (hoy por defecto, editable)**" (1.8, R8, R1).
S9 — "**Precio por unidad de medida + comparador con jerarquía: producto por EAN primero, artículo después (orden por $/unidad, mínimo resaltado)**" (1.9, R11, R13).
S10 — "**Historial por producto y por comercio, con variación %**" (1.10, R8).
S11 — "**Mínimo, promedio y máximo por artículo (30 días por defecto / histórico, filtro por comercio)**" (1.11, R12).
S12 — "**Búsqueda y listado por producto y por artículo**" (1.12, R1).
S13 — "**Backup/export JSON + CSV, e importación**" (1.13, R3, R5).
S14 — "**Etiqueta de aportante en el primer inicio (guardada en el dispositivo, viaja con cada dato)**" (1.14, R17).
S15 — "**Primer APK de pruebas publicado en GitHub Releases**" (1.15, R2, AD-006).

**Criterio de salida (hoja-de-ruta):** "con modo avión: escanear un EAN del catálogo semilla →
registrar su precio en un comercio nuevo → abrir el comparador del artículo y ver el precio por
unidad con mínimo y promedio; el backup restaura en otra instalación."

## Tasks

- T1 — [S1] Esquema local v1 (drift) + índices + normalización + tests DAO en memoria. ✅ commit `564555d` — 18/18 tests verdes (6 esquema, 11 normalización, 1 navegación), analyze limpio
- T2 — [S2] Script `tools/seed` (CLI Dart): CSV OFF/OPF → pack JSON Argentina con atribución (fuente/ODbL). ✅ commits de esta fase — 19/19 tests del paquete (EAN, cantidades, marcas, filtros, límites, metadata)
- T3 — [S3] Servicio de import del pack en primer arranque + tests. ✅ commit de esta fase — 20/20 tests verdes (dedup por EAN: la carga manual del dueño gana; inválidos omitidos; `origen = 'semilla'`)
- T4 — [S4] Escáner (mobile_scanner, on-device) + ingreso manual con búsqueda en la base. ✅ commits de esta fase — 23/23 tests verdes (3 widget del escáner con base en memoria; cámara desactivada por flag testeable)
- T5 — [S5] ABM de producto (alta/edición) con unidad, contenido neto, granel AD-014 y artículo opcional. ✅ commits de esta fase — 29/29 tests verdes (5 widget del formulario + integración escáner→crear)
- T6 — [S6] Administración de artículos: alta (con unidad base), renombre y conteo de productos por artículo. ✅ commits de esta fase — 32/32 tests verdes (creación, renombre, conteo; la unidad base no cambia al renombrar)
- T7 — [S7] Alta de comercio inline. → commit `feat`
- T8 — [S8] Registro de precio con fecha de toma. → commit `feat`
- T9 — [S9] Comparador con jerarquía (R13) y $/unidad. → commit `feat`
- T10 — [S10] Historial con variación %. → commit `feat`
- T11 — [S11] Agregados por artículo (ventana 30 días / histórico). → commit `feat`
- T12 — [S12] Búsqueda/listado producto y artículo. → commit `feat`
- T13 — [S13] Backup export/import JSON + CSV. → commit `feat`
- T14 — [S14] Etiqueta de aportante en primer inicio. → commit `feat`
- T15 — [S15] Release del APK (GitHub Releases). → commit/tag

## Log

- L1 — Autorización: la Fase 0 fue validada por el dueño en su teléfono (avión, sin errores,
  navegación correcta) y aprobó avanzar ("Antes: APK en CI para probar" cumplido → validación OK).
  Modo de trabajo vigente: evaluación por etapas.
- L2 — Decisiones técnicas de la fase (agente): drift con `NativeDatabase` (sqlite3_flutter_libs
  en Android); DLL `sqlite3.dll` en `app/dll/` para tests en Windows (dominio público); UUID v4
  generados en el dispositivo; UI en español, identificadores en inglés (AD-007); código de
  barra como TEXT (EAN-13/EAN-8/UPC-A); fechas como TEXT ISO-8601 para portabilidad SQL;
  precio en REAL redondeado a 2 decimales por la capa de datos (equivalente funcional a
  NUMERIC(12,2) en SQLite).
- L7 — Corrección de directiva del dueño (2026-10-26): "ok. corrijo indicacion previa, realizar comprobaciones cuando se considere necesario." — el flujo pasa a continuo: comprobaciones (analyze/test/CI) a criterio del agente, sin pausas obligatorias por fase; el dueño solo interviene en decisiones que lo requieran (publicación, hardware, etc.).
- L8 — T5 completa: `ProductoFormScreen` (alta/edición con validaciones de nombre/código/contenido, dropdown de unidad desde `unidadesDeVenta`, dropdown de artículos, manejo de EAN duplicado) + integración desde el escáner ("no existe → Crear producto" precargando el código) e IDs uuid v4 generados en el dispositivo. Aprendizaje de tests: los formularios largos exceden el surface por defecto de flutter_test (800×600) → ampliar `tester.view` o los taps no pegan.
- L9 — T6 completa: `ArticulosScreen` con alta (nombre + unidad base), renombre (la unidad base no cambia) y conteo de productos asignados vía SQL agrupado. La asignación producto↔artículo queda cubierta por el formulario de producto (T5). Aprendizajes: colisión de nombres `Column` entre drift y Flutter → `hide Column` en el import de drift; tras cargas async en initState, `pumpAndSettle` antes de tocar la UI; en tests, la aserción debe probar el efecto post-acción (formulario cerrado + mensaje), no un texto que ya estaba en un campo. Esquema v1 con 5 tablas, índices, FKs con `PRAGMA foreign_keys`, CHECK `precio > 0`, EAN único con NULL permitidos, y la normalización R11/R12 + granel AD-014 como función pura testeada. Nota de entorno: sqlite3 3.x usa **native assets** (el hook compila SQLite con MSVC en el host) — la estrategia de DLL manual quedó obsoleta y se eliminó.
- L4 — T2 completa: `tools/seed/` como paquete Dart independiente (`seed_builder`, deps: csv + args). Reglas: solo EAN-13, filas sin nombre o sin cantidad interpretable se descartan, países no-argentina se descartan, cantidades normalizadas a g/mL/unidad (kg/L/cl convertidos), dedup por EAN, pack con metadatos fuente/ODbL. La descarga del dump queda como paso documentado del operador (README del paquete); el script transforma archivos locales .csv/.gz. 19/19 tests.
- L5 — T3 completa: columna `producto.origen` ('semilla'|null) + importador transaccional `importarPackSemilla` con dedup por EAN (la carga manual del dueño gana) y filtrado de filas inválidas (unidad no reconocida). Aprendizajes: `customConstraint` de drift pisa el NOT NULL por defecto (re-declararlo); al mezclar drift + matcher, usar `import 'package:drift/drift.dart' hide isNull;`.
- L6 — T4 completa: `mobile_scanner` (ML Kit on-device) integrado; la base se inyecta por constructor (main → app → shell → pantallas) y `EscanerScreen` acepta `mostrarCamara: false` para que los widget tests validen el flujo manual contra base en memoria sin hardware. El test replica la estructura real (Scaffold del shell) porque TextField exige ancestro Material. La lectura real de cámara queda para la validación en dispositivo del cierre de fase.
