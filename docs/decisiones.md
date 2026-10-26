# Decisiones de diseño (ADR)

Formato: cada decisión registra contexto, decisión y consecuencias. Las decisiones aprobadas
explícitamente por el dueño se marcan así.

## AD-001 — Flutter como framework de la app ✅ aprobado

- **Contexto:** app Android (R2), con escáner (R6) y BD local (R3). Alternativas evaluadas: Kotlin nativo, React Native/Expo.
- **Decisión:** Flutter (Dart).
- **Consecuencias:** un solo código para Android con posibilidad de iOS a futuro; paquetes maduros para todo lo necesario (`mobile_scanner`, `drift`). Contra: binario más grande y dependencia de paquetes de terceros, mitigada usando los más adoptados.

## AD-002 — Supabase como backend colaborativo ✅ aprobado

- **Contexto:** centralización web colaborativa (R4) con recursos gratuitos y perdurables (R5). Alternativas evaluadas: Firebase Spark, PocketBase self-host.
- **Decisión:** Supabase, plan gratuito (Postgres + Auth + RLS).
- **Consecuencias:** datos en Postgres estándar, exportables y migrables; API y reglas de acceso incluidas. Contra: **el plan gratuito pausa el proyecto tras ~7 días sin actividad**; mitigación con ping programado (GitHub Actions) o reactivación manual sin costo. La app local nunca depende del backend (R3).

## AD-003 — Identidad anónima + ID de dispositivo ✅ aprobado

- **Contexto:** colaboración sin fricción (uso familiar/amistoso) versus control y moderación.
- **Decisión:** sin registro. Cada instalación usa el **auth anónimo de Supabase** (`signInAnonymously`) y un id local; los aportes se atribuyen a ese usuario anónimo.
- **Consecuencias:** cero fricción para cargar precios. Contra: sin sincronización multi-dispositivo del mismo usuario (futuro: login opcional que convierte el usuario anónimo en cuenta real, sin migrar datos) y moderación limitada.

## AD-004 — SQLite vía `drift` como base local

- **Contexto:** R3 exige datos en el dispositivo sin conexión.
- **Decisión:** SQLite con el paquete `drift` (SQL tipado, migraciones versionadas, DAOs testeables).
- **Consecuencias:** formato eterno, respaldable y exportable (R5); consultas SQL completas para historial, comparador y agregados. Contra: algo más de código que un ORM simple.

## AD-005 — Escáner ML Kit on-device

- **Contexto:** R6 exige escaneo de códigos; R3 exige que funcione offline; R5 exige gratuidad.
- **Decisión:** `mobile_scanner` (ML Kit Barcode de Google), ejecución 100% en el dispositivo.
- **Consecuencias:** funciona sin red, sin costo por escaneo y sin servidores. El ingreso manual queda siempre disponible como alternativa (R6).

## AD-006 — Distribución por APK en GitHub Releases

- **Contexto:** Play Store cuesta USD 25 (pago único, no gratuito) y exige cuenta de Google.
- **Decisión:** distribuir el APK directamente vía GitHub Releases.
- **Consecuencias:** costo cero y sin intermediarios. Contra: actualizaciones manuales (instalar el APK nuevo); a futuro puede agregarse un aviso de nueva versión dentro de la app.

## AD-007 — Idiomas del proyecto

- **Decisión:** documentación del proyecto en **español** (pedido explícito del dueño); código, identificadores y mensajes de commit en inglés (convención de la industria); **UI de la app en español rioplatense** (los usuarios son locales).
- **Consecuencias:** consistencia clara por tipo de artefacto.

## AD-008 — Catálogo semilla desde Open Food Facts / Open Products Facts ✅ fuente decidida

- **Contexto:** R10 pide que la app no inicie vacía, con una base gratuita de productos argentinos que incluya EAN-13. Alternativas evaluadas: GS1 Argentina (arancelada), dataset Precios Claros de datos.gob.ar (abierto pero con continuidad histórica irregular), Open Food Facts + Open Products Facts (abiertas, dumps públicos completos, API gratuita, licencia ODbL).
- **Decisión:** Open Food Facts (alimentos) y Open Products Facts (no alimentos) como fuente primaria. El dump público se filtra por `countries_tags = argentina` y `tools/seed` lo normaliza en un pack JSON que viaja dentro del APK (R10). Enriquecimiento puntual por API en Fase 2: EAN desconocido con conexión → precarga de nombre/marca/contenido, siempre confirmada por el usuario.
- **Consecuencias:** + gratuito, durable, con licencia abierta y atribución simple en "Acerca de". − cobertura argentina **parcial**: no está todo el mercado; se mitiga con alta manual, carga colaborativa y enriquecimiento progresivo. La ODbL exige atribución y compatibilidad share-alike sobre el catálogo derivado (registrado también en [Requisitos R10](requisitos.md#r10--catálogo-inicial-semilla-de-productos-argentinos)).

## AD-009 — Artículo como agrupador de comparación (R11/R12)

- **Contexto:** comparar marcas y presentaciones distintas de un mismo tipo de producto exige un nivel de agrupación que el producto alone no da.
- **Decisión:** nueva entidad `articulo` (tipo de producto genérico con `unidad_base`); cada `producto` (marca + presentación) pertenece opcionalmente a un artículo. La comparación usa el **precio por unidad de medida normalizado**; artículos sin clasificar quedan fuera del comparador, no del historial.
- **Consecuencias:** + comparaciones justas entre presentaciones (500 g contra 1 kg) y agregados (mínimo/promedio/máximo) por artículo. − un paso extra de clasificación, aliviado con sugerencias por categoría/nombre y con los datos del pack semilla (que ya traen categoría).

## Decisiones abiertas

| Tema | Estado | Cuándo se decide |
| --- | --- | --- |
| Licencia del repositorio | abierta | antes del primer release |
| Nombre definitivo de la app | abierta | Fase 0 |
| Profundidad del catálogo semilla (cuántos productos lleva el pack) | abierta | Fase 1 |
| Política de moderación de datos colaborativos | abierta | Fase 2 |
| Coincidencia difusa de productos sin EAN | abierta | Fase 3 |
