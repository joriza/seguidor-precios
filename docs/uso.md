# Manual de usuario

> **Estado:** la app está en fase de diseño. Este manual describe la experiencia prevista de las
> Fases 1 y 2; sirve de referencia de producto y de base para las pruebas de aceptación.

## ¿Qué es Seguidor de Precios?

Una app Android para anotar y comparar precios de productos de consumo masivo. Funciona **sin
internet** (los datos viven en tu teléfono) y, si querés, comparte tus aportes con otros usuarios.

## Primer inicio

- La app ya trae un **catálogo base de productos argentinos** con código de barras, generado a
  partir de bases de datos abiertas (Open Food Facts). No arranca vacía.
- La atribución a las fuentes queda siempre disponible en **Acerca de**.

## Escanear o buscar un producto

1. Tocá **Escanear** y apuntá la cámara al código de barras, o ingresá el código a mano.
2. Si el producto ya existe (del catálogo base o cargado por vos u otros usuarios), se abre su ficha.
3. Si no existe, lo creás: nombre, marca, unidad (kg, g, L, mL, unidad, m) y contenido neto (ej. 500 g).
4. Con conexión, si el código es desconocido, la app puede **precargar** los datos desde la base
   abierta antes de crearlo a mano (siempre con tu confirmación).

## Cargar un precio

1. Desde la ficha del producto: **Registrar precio**.
2. Elegí el **comercio** de la lista o crealo en el momento (solo el nombre es obligatorio).
3. Ingresá el **precio** y la **fecha de toma** (hoy por defecto, editable).

## Productos sin código de barras

Para carnicería, verdulería, madera o construcción: creá el producto sin código, elegí la unidad
(kg, unidad, m, L) y, si aplica, el contenido neto. Ejemplos: "Asado" (kg), "Tornillo de 2
pulgadas" (unidad), " listón de madera" (m).

## Comparar por artículo: el ejemplo de la mayonesa

1. Buscá el **artículo** — el tipo de producto — "Mayonesa" y abrí su **comparador**.
2. Vas a ver cada marca y presentación con su **precio por kilo**, ordenado de menor a mayor, con
   el **más económico resaltado**:

| Producto | Precio | Contenido | Precio por kg |
| --- | --- | --- | --- |
| Marca A · 1 kg | $ 2.700 | 1 kg | **$ 2.700** ⭐ |
| Marca A · 500 g | $ 1.500 | 500 g | $ 3.000 |
| Marca B · 250 g | $ 900 | 250 g | $ 3.600 |

Debajo del comparador, el **mínimo, el promedio y el máximo** del artículo: por defecto sobre los últimos 30
días, con opción de ver todo el histórico o filtrar por comercio.

Así funciona para cualquier tipo de producto: aceite por litro, arroz por kilo, tornillos por
unidad, madera por metro.

## Historial

En la ficha de cada producto: precios cronológicos con su **fecha de toma** y la **variación %**
entre tomas consecutivas.

## Sincronizar (opcional)

Con internet, la app sube tus aportes y baja los de otros usuarios. Sin internet todo sigue
funcionando igual y se sincroniza después solo. Hay un indicador de estado y sync manual
(deslizar para actualizar).

## Copia de seguridad

Exportá todos tus datos a JSON/CSV y restauralos en otro teléfono.

## Preguntas frecuentes

- **¿Necesito internet?** No, salvo para sincronizar o precargar un producto desconocido.
- **¿De dónde salen los productos que ya están cargados?** De bases de datos abiertas (Open Food
  Facts) y de lo que cargan los usuarios.
- **¿Por qué mi producto no aparece en el comparador?** Le falta contenido neto o artículo
  asignado; completalo desde su ficha.
- **¿Qué pasa si dos personas cargan el mismo producto?** Se unen por código de barras: un solo
  producto con todos los precios.
- **¿Se pierde algo si el servidor no está disponible?** No: tus datos viven en el teléfono y se
  sincronizan cuando vuelve.
