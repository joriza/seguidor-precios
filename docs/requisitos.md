# Requisitos funcionales

Fuente: pedido original del dueño del proyecto. R1–R9 provienen del pedido inicial; R10–R12 se
agregaron en la revisión del plan (catálogo inicial y comparación por artículo), R13–R15 en la
siguiente (jerarquía de comparación y política de conexión), R16 al proyectar la escala pública y
R17–R18 al definir la etapa de pruebas (identidad del aportante y mantenimiento de datos). Los
requisitos se transcriben textualmente; cada uno incluye su interpretación y criterios de
aceptación verificables.

## R1 — Control personal de precios

- **Requisito:** llevar el control personal de precios de productos de consumo masivo, generalmente productos alimenticios de almacén.
- **Interpretación:** la unidad básica de información es *el precio de un producto en un comercio en una fecha*.
- **Aceptación:**
  - Puedo registrar el precio de un producto en un comercio con su fecha.
  - Puedo listar productos con su último precio conocido.
  - El registro funciona sin conexión.

## R2 — Android

- **Requisito:** la aplicación debe poder utilizarse en un celular con Android.
- **Aceptación:**
  - La app se distribuye como APK instalable sin tienda (GitHub Releases).
  - Objetivo inicial: Android 7.0 (API 24) o superior, a validar en la Fase 0.
  - No depende de servicios de Google Play para funcionar.

## R3 — Datos en el dispositivo, sin conexión

- **Requisito:** los datos deben alojarse en el dispositivo para disponer de ellos sin conexión a internet.
- **Aceptación:**
  - Con modo avión activo funcionan: escanear, registrar, consultar historial y respaldar.
  - Los datos persisten entre reinicios de la app y del teléfono.
  - Ninguna pantalla exige red para operar; la sincronización es opcional y en segundo plano.

## R4 — Centralización colaborativa

- **Requisito:** los datos deben poder centralizarse en un lugar de la web para que sea colaborativo con los datos nuevos.
- **Aceptación:**
  - Con conexión, lo que cargo se publica en el repositorio central.
  - Con conexión, puedo bajar productos, comercios y precios cargados por otros usuarios.
  - Dos usuarios que cargan el mismo producto con igual código de barras terminan en un único producto (sin duplicados por EAN).

## R5 — Recursos gratuitos y perdurables

- **Requisito:** todos los recursos que sean posibles deben ser de uso gratuito, perdurables en el tiempo.
- **Aceptación:**
  - Ningún componente del stack requiere pago para escala personal/familiar.
  - Los datos son exportables sin herramientas propietarias (SQLite, CSV/JSON, Postgres).
  - Si un servicio gratuito se pausa, la app sigue funcionando y no se pierden datos.

## R6 — Escaneo y ingreso manual

- **Requisito:** debe poder escanear el código de barras; también debe permitir el ingreso manual del código de barras.
- **Aceptación:**
  - La cámara lee EAN-13, EAN-8 y UPC-A, y completa el campo del formulario.
  - El campo código de barras es editable a mano en todo momento.
  - Sin cámara o con escaneo fallido, el flujo 100% manual está disponible.

## R7 — Productos sin código de barras

- **Requisito:** debe permitir ingresar productos que no tengan códigos de barra, como productos de carnicería, verdulería, madera o materiales de construcción.
- **Aceptación:**
  - Puedo crear un producto sin código de barras (identificador interno propio).
  - El producto declara unidad de medida (unidad / kg / g / L / mL / m) y, si aplica, contenido neto.
  - Un producto sin código no limita ninguna otra función (precios, historial, sincronización).

## R8 — Historial con fecha de toma

- **Requisito:** debe llevar un historial de los precios y fecha de toma del dato.
- **Aceptación:**
  - Cada precio guarda fecha de toma (hoy por defecto, editable) además de la fecha de carga.
  - Por producto (y por comercio) se ve el histórico cronológico completo.
  - Se muestra la variación porcentual entre tomas consecutivas.

## R9 — Comercio con alta en el momento

- **Requisito:** al registrar los productos debe permitir ingresar el comercio, y agregarlo en el momento si fuera necesario.
- **Aceptación:**
  - Al registrar un precio elijo un comercio existente o creo uno nuevo sin salir de la pantalla.
  - El comercio creado queda disponible para registros futuros.
  - Campos mínimos: nombre. Opcionales: tipo (almacén, carnicería, verdulería, ferretería, otro) y dirección.

## R10 — Catálogo inicial (semilla) de productos argentinos

- **Requisito:** para que la aplicación no inicie vacía, tomar datos de alguna base de datos gratuita de productos de Argentina con el código de barras (EAN-13).
- **Decisión de fuente:** Open Food Facts / Open Products Facts ([AD-008](decisiones.md#ad-008--catálogo-semilla-desde-open-food-facts--open-products-facts)).
- **Aceptación:**
  - Al primer inicio, la app ya contiene un catálogo base de productos argentinos con EAN-13, nombre, marca y contenido neto.
  - Al escanear un EAN del catálogo, el producto aparece sin carga manual.
  - La fuente es gratuita, abierta y con atribución visible dentro de la app (licencia ODbL).
  - (Fase 2) Con conexión, un EAN desconocido puede precargarse consultando la fuente abierta antes de darlo de alta a mano.

## R11 — Comparación por tipo de producto (artículo)

- **Requisito:** poder comparar precios por tipo de producto. Ejemplo: mayonesa puede ser marca A y marca B en 2 presentaciones cada una; el dato comparable es el precio por unidad de medida, y el objetivo es identificar el más económico.
- **Concepto:** **artículo** = tipo de producto genérico ("Mayonesa"); **producto** = marca + presentación concreta con su EAN.
- **Aceptación:**
  - Cada producto declara contenido neto y unidad (kg, g, L, mL, unidad, m).
  - Cada registro de precio tiene un precio por unidad de medida equivalente ($/kg, $/L, $/unidad, $/m), normalizado.
  - Presentaciones distintas de un mismo artículo son comparables entre sí (500 g contra 1 kg).
  - El comparador de un artículo lista sus productos ordenados por precio por unidad y resalta el más económico.

## R12 — Unidad de medida, mínimo y promedio por artículo

- **Requisito:** la unidad de medida de cada producto es un dato central (hay productos por kg, por litro, por unidad). Como suelen venir en varias presentaciones y marcas, interesa conocer el precio mínimo y promedio de un determinado artículo, más allá de su marca o presentación.
- **Aceptación:**
  - Por artículo se muestra el precio mínimo, promedio y máximo del precio por unidad de medida.
  - Los agregados se calculan por defecto sobre los precios de los últimos 30 días, con opción de ver todo el histórico.
  - Los agregados pueden filtrarse por comercio.
  - Los productos sin contenido neto declarado (que no sean a granel) no participan de la comparación normalizada (pero sí del historial); los bienes a granel se tratan con contenido neto = 1 ([AD-014](decisiones.md#ad-014--bienes-a-granel-contenido-neto-implícito--1)).

## R13 — Jerarquía de comparación: mismo código primero

- **Requisito (verbatim):** "La comparación si el producto con el mismo código existe, es la que más vale, pero sino solo por tipo de producto."
- **Interpretación (confirmada por el dueño, D4):** la comparación más valiosa/confiable es la del **producto exacto** (mismo EAN, entre comercios) y es la comparación principal de la app; la comparación por **artículo** (tipo de producto) es la vía cuando no existe coincidencia por código o el producto no tiene código.
- **Aceptación:**
  - Si el producto con ese EAN ya existe, el comparador muestra primero la comparación de ese producto entre comercios.
  - Si no hay coincidencia por código (o el producto no tiene código), la comparación es solo por artículo.
  - Ambos niveles usan el precio por unidad de medida normalizado (R11).

## R14 — Ping mínimo anti-pausa al iniciar

- **Requisito (verbatim):** "Para que no se apague la base de datos, al iniciar enviar una consulta mínima suficiente."
- **Interpretación:** la app misma mantiene activo el proyecto gratuito del backend con una consulta mínima al iniciar; el cron de GitHub Actions pasa a complemento opcional.
- **Aceptación:**
  - Al iniciar con conectividad, se envía una consulta mínima al backend (p. ej. `SELECT 1` vía RPC `ping`) que resetea el contador de inactividad.
  - Sin conectividad se omite en silencio (R3 intacto).
  - La consulta no sincroniza datos ni consume cuota significativa.

## R15 — Sincronización al iniciar: solo WiFi, con condiciones y confirmación

- **Requisito (verbatim):** "Al iniciar la aplicación, solo si está conectado a wifi y tiene datos locales nuevos o ha pasado más de 7 días desde la última sincronización, consultar si quiere sincronizar datos."
- **Aceptación:**
  - El aviso de sincronización aparece solo si se cumplen **todas** las condiciones: conexión **WiFi**, y además **hay cambios locales sin sincronizar** **o** pasaron **más de 7 días** desde el último sync exitoso.
  - La app **pregunta antes** de sincronizar; nunca sincroniza automáticamente sin confirmación.
  - Con datos móviles (no WiFi) no aparece el aviso; la sincronización manual sigue disponible siempre con cualquier conexión.
  - El estado que alimenta la condición (outbox pendiente y `ultimo_sync`) vive solo en el dispositivo.

## R16 — Camino a público general con infraestructura propia

- **Requisito (verbatim):** "Al principio la aplicación será para un grupo reducido de personas. Pero si tiene aceptación, es posible que la libere al público en general, con lo cual debe contemplar la posibilidad de que se aloje en infraestructura propia, con una base de datos propia."
- **Interpretación:** la etapa inicial usa el free tier de Supabase (costo $0); la arquitectura debe garantizar un camino de migración a infraestructura propia **sin reescribir la app** y sin perder datos.
- **Aceptación:**
  - Todo el stack del backend es open source y self-hosteable: Supabase completo (Docker) o Postgres + PostgREST.
  - La URL y la clave del backend son configurables en un único punto (entorno/flavor), sin tocar la lógica de la app.
  - Existe un procedimiento documentado de export/import de la base completa (cloud → propia).
  - El camino de migración está planificado como [Fase 4](hoja-de-ruta.md#fase-4--público-e-infraestructura-propia-condicional-r16), **condicional** a la adopción real.
  - En la etapa de grupo reducido el costo sigue siendo $0 (R5).

## R17 — Identificación del aportante (revisada en la etapa de pruebas)

- **Requisito original (verbatim):** "Anónimo + cuenta opcional: cada instalación empieza anónima; login opcional por email (enlace mágico) para que tus datos te sigan entre PC y teléfono."
- **Revisión (etapa de pruebas):** la identificación del aportante se hace con una **etiqueta elegida en el dispositivo**; el login por enlace mágico y la cuenta multi-dispositivo quedan **diferidos** hasta que se necesiten ([Fase 3](hoja-de-ruta.md#fase-3--valor-agregado-post-mvp)).
- **Aceptación (etiqueta):**
  - En el primer inicio la app pide un nombre o apodo y lo guarda en el dispositivo.
  - Cada precio y producto cargado queda atribuido a esa etiqueta (visible para el grupo).
  - No requiere email, registro ni conexión; se puede cambiar desde ajustes.
- **Diferido (cuenta con enlace mágico):** al implementarse, convertirá el usuario anónimo en cuenta real sin migrar datos, y permitirá que los datos sigan a la persona entre dispositivos.

## R18 — Mantenimiento de datos por el dueño

- **Requisito (verbatim):** "Seguir con flutter como está acordado y realizar una aplicación web para el mantenimiento de los datos que solo lo realizará el dueño de la aplicación."
- **Interpretación:** dos clientes sobre el mismo backend: la app Flutter (usuarios, escáner) y el mantenimiento (solo dueño, desde la PC).
- **Aceptación:**
  - En la etapa de pruebas el mantenimiento se hace con **Supabase Studio** (panel incluido, sin desarrollo).
  - La **web de administración del dueño** se construye solo cuando el panel quede corto (asignar artículos en lote, corregir duplicados con comodidad).
  - Acceso exclusivo del dueño vía login + regla RLS de administrador; siempre conectada, sin modo offline.
  - No agrega backend: es un cliente más del mismo Supabase (hereda R16).
