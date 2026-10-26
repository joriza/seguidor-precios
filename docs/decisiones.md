# Decisiones de diseño (ADR)

Formato: cada decisión registra contexto, decisión y consecuencias. Las decisiones aprobadas
explícitamente por el dueño se marcan así. Los ADRs sin marca fueron decisiones técnicas acordadas
al confeccionar el plan; las decisiones pendientes están listadas en Decisiones abiertas (queda
abierta D3, con postergación a Fase 4 aceptada por el dueño).

## AD-001 — Flutter como framework de la app ✅ aprobado

- **Contexto:** app Android (R2), con escáner (R6) y BD local (R3). Alternativas evaluadas: Kotlin nativo, React Native/Expo.
- **Decisión:** Flutter (Dart).
- **Consecuencias:** un solo código para Android con posibilidad de iOS a futuro; paquetes maduros para todo lo necesario (`mobile_scanner`, `drift`). Contra: binario más grande y dependencia de paquetes de terceros, mitigada usando los más adoptados.

## AD-002 — Supabase como backend colaborativo ✅ aprobado

- **Contexto:** centralización web colaborativa (R4) con recursos gratuitos y perdurables (R5). Alternativas evaluadas: Firebase Spark, PocketBase self-host.
- **Decisión:** Supabase, plan gratuito (Postgres + Auth + RLS).
- **Consecuencias:** datos en Postgres estándar, exportables y migrables; API y reglas de acceso incluidas. Contra: **el plan gratuito pausa el proyecto tras ~7 días sin actividad**; mitigación con ping al iniciar (R14) o reactivación manual sin costo. La app local nunca depende del backend (R3). Camino propio (R16): si el proyecto escala a público, Supabase self-hosted o Postgres + PostgREST corren en infraestructura propia sin reescribir la app (ver AD-011).

## AD-003 — Identidad anónima + ID de dispositivo ✅ aprobado (revisado: + cuenta opcional)

- **Contexto:** colaboración sin fricción (uso familiar/amistoso) versus control y moderación; con la reevaluación multi-dispositivo, el dueño eligió mantener anonimato por defecto y sumar la posibilidad de sincronizar sus propios dispositivos.
- **Decisión:** cada instalación empieza **anónima** (auth anónimo de Supabase, `signInAnonymously`) y un id local; los aportes se atribuyen a ese usuario anónimo. **Revisión (R17):** desde ajustes se puede iniciar sesión por email con **enlace mágico** (`signInWithOtp`), lo que convierte el usuario anónimo en cuenta real **sin migrar datos**; con la misma cuenta en otro dispositivo, el historial y los aportes propios siguen a la persona.
- **Consecuencias:** + cero fricción por defecto y sync multi-dispositivo para quien quiera. − el login opcional (diferido a Fase 3) será una superficie de auth a cuidar; la política de sync (R15) sigue mandando.
- **Etapa de pruebas (revisión R17/R18):** el login por enlace mágico queda **diferido**; la atribución de aportes se hace con una **etiqueta de aportante** elegida en el dispositivo (sin seguridad real, aceptado en grupo de confianza).

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
- **Jerarquía (R13):** si existe el producto con el mismo código, la comparación más valiosa es la del producto exacto entre comercios; solo si no hay coincidencia por código (o no hay código) se compara por artículo. Interpretación **confirmada por el dueño** (D4): es la comparación principal de la app.

## AD-010 — Política de red al iniciar: ping anti-pausa y sync bajo confirmación ✅ aprobada

- **Contexto:** el free tier de Supabase se pausa tras ~7 días sin actividad (AD-002); la sincronización automática consume datos y sorprende al usuario.
- **Decisión (R14/R15):** al iniciar y con conectividad, la app envía una consulta mínima (`ping`) que mantiene activo el backend. La sincronización de datos, en cambio, solo se ofrece al iniciar bajo **todas** estas condiciones: conexión **WiFi** y (**cambios locales pendientes** o **más de 7 días** desde el último sync), siempre con **confirmación del usuario**. La sync manual queda disponible siempre con cualquier conexión.
- **Consecuencias:** + control del usuario, ahorro de datos móviles y backend mantenido despierto por la propia app. − un diálogo ocasional al iniciar; requiere estado local (`ultimo_sync`, outbox) que no se sincroniza.

## AD-011 — Escala pública sobre stack open source, sin lock-in

- **Contexto (R16):** la app nace para un grupo reducido, pero si tiene aceptación se liberaría al público; el dueño exige contemplar alojamiento en infraestructura propia con base de datos propia.
- **Decisión:** todo el backend es open source y self-hosteable: Supabase completo (Docker Compose propio) o Postgres + PostgREST en un VPS. La app configura URL + clave del backend en un único punto, sin tocar su lógica; las migraciones SQL del repo son el esquema canónico y `pg_dump`/`restore` es la vía de migración de datos.
- **Consecuencias:** + cero reescritura al migrar, datos siempre exportables (R5), costo $0 en la etapa de grupo reducido. − la operación propia (backups, monitoreo, seguridad del servidor) queda a cargo del dueño cuando llegue esa etapa; se planifica condicionalmente en la Fase 4.

## AD-012 — Alternativa PWA evaluada y descartada (por ahora)

- **Contexto:** el dueño consultó por una PWA para usar la app desde cualquier dispositivo, incluso PC; se reevaluó el stack completo.
- **Análisis:** es técnicamente viable — SQLite WASM sobre OPFS para el modo offline (verificado 2026: WAL soportado; Chromium reserva hasta 60% del disco; Safari ~1 GB y borra datos de pestañas tras 7 días sin uso, la PWA instalada está exenta), escaneo con BarcodeDetector API (Chrome/Edge) más ZXing.js como alternativa en Safari/Firefox, hosting gratuito en GitHub/Cloudflare Pages y actualización instantánea. iOS es el eslabón débil; y el multi-dispositivo real exige cuenta opcional (adoptada en su momento, hoy diferida a Fase 3; ver AD-003).
- **Decisión:** **mantener Flutter** Android-first; la PC queda fuera del alcance por ahora. Flutter web se descartó expresamente: `mobile_scanner` no soporta web y el bundle es pesado.
- **Condición de revisión:** si vuelve a ser requisito usar la app desde PC, el camino recomendado es PWA con SvelteKit + SQLite WASM + BarcodeDetector/ZXing — **no** Flutter web. Este ADR conserva el análisis para no rehacerlo.

## AD-013 — Etapa de pruebas: atribución por etiqueta y mantenimiento vía Studio

- **Contexto:** el dueño planteó separar el mantenimiento de datos (solo él, desde la PC) de la app de usuarios — preservando el escáner nativo, requisito de mayor utilidad — e identificar al aportante sin contraseñas durante las pruebas.
- **Decisión:** (1) **Atribución:** etiqueta de aportante elegida en el primer inicio, guardada en el dispositivo y viajando con cada dato; el login por enlace mágico (cuenta multi-dispositivo, R17) queda diferido a Fase 3. (2) **Mantenimiento:** en pruebas, **Supabase Studio** (panel incluido, cero código); la **web de administración del dueño** — cliente liviano del mismo Supabase, solo dueño vía RLS de admin, siempre conectada, en `admin/` del repo — se construye cuando el panel quede corto.
- **Consecuencias:** + el escáner nativo queda intacto; mantenimiento cómodo desde la PC sin backend nuevo; cero fricción de email. − atribución sin seguridad real (aceptado en grupo de confianza); Studio es CRUD crudo para trabajo en lote (mitigado: la web admin a medida llega cuando haga falta).

## AD-014 — Bienes a granel: contenido neto implícito = 1 ✅ aprobada (D1)

- **Contexto:** los bienes vendidos por kg/L/m sin contenido neto fijo (asado, verdulería, madera) no pueden declarar un `contenido_neto` fijo; sin semántica, quedaban fuera del comparador, contradiciendo R7.
- **Decisión:** para productos a granel cuya `unidad` coincide con la de venta (kg, L, m, unidad), el contenido neto se trata como **1 implícito**: `precio_unitario = precio`. No necesitan declarar contenido neto ni quedan excluidos.
- **Consecuencias:** + carnicería/verdulería/madera comparables por $/kg, $/L, $/m desde el día uno (R7/R11/R12). − los precios de granel dependen de que la unidad declarada sea la correcta; el pack semilla no los trae (son de carga manual/colaborativa).

## AD-015 — Administrador: uid fijo del dueño ✅ aprobada (D2)

- **Contexto:** la web de mantenimiento (R18) requiere una regla RLS de administrador, pero no existía mecanismo de rol.
- **Decisión:** para la etapa de pruebas y grupo reducido, el administrador se identifica por **uid fijo del dueño** en la regla RLS (el `auth_uid` de la primera instalación del dueño). Sin tabla de roles.
- **Consecuencias:** + una línea de SQL, cero superficie extra. − sumar administradores exigirá migrar a tabla de roles (recién evaluable en Fase 4 si hiciera falta).

## Decisiones abiertas

| Tema | Estado | Cuándo se decide |
| --- | --- | --- |
| Licencia del repositorio | abierta | antes del primer release |
| Nombre definitivo de la app | abierta | Fase 0 |
| Profundidad del catálogo semilla (cuántos productos lleva el pack) | abierta | Fase 1 |
| Política de moderación de datos colaborativos | abierta | Fase 2; crítica en Fase 4 (público) |
| Coincidencia difusa de productos sin EAN | abierta | Fase 3 |
| Distribución pública (APK directo vs Play Store) | abierta | Fase 4 |
| Infraestructura propia (VPS/proveedor y costos) | abierta | Fase 4 |
| Semántica de granel: contenido neto de bienes vendidos por kg/L/m (D1) | abierta | Fase 1, antes del comparador |
| Mecanismo de administrador: uid fijo vs tabla de roles (D2) | abierta | Fase 2, antes de la web admin |
| Licencia de la base colaborativa derivada (mezcla ODbL + aportes) (D3) | abierta — el dueño aceptó decidirla en Fase 4 | Fase 4, antes de publicarla |
| Confirmación de la interpretación de R13: producto por EAN como comparación primaria (D4) | ✅ confirmada por el dueño | registrada en R13 y AD-009 |
| Disparador para construir la web admin del dueño | abierta | Fase 2, cuando Studio quede corto |
