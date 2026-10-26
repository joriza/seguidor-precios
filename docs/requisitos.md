# Requisitos funcionales

Fuente: pedido original del dueño del proyecto. R1–R9 provienen del pedido inicial; R10–R12 se
agregaron en la revisión del plan (catálogo inicial y comparación por artículo). Los requisitos se
transcriben textualmente; cada uno incluye su interpretación y criterios de aceptación verificables.

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
  - Los productos sin contenido neto declarado no participan de la comparación normalizada (pero sí del historial).
