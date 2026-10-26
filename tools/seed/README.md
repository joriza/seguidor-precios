# seed_builder — generador del pack semilla (R10)

Convierte un dump CSV de Open Food Facts / Open Products Facts en el pack
JSON que la app importa en el primer arranque (`app/assets/seed/`).

## Uso

```bash
cd tools/seed
dart pub get

# 1) Descargá el dump CSV filtrado por Argentina (export estándar de OFF/OPF,
#    o la búsqueda v2 con format=csv). Ejemplos:
#      https://world.openfoodfacts.org/data
#      https://world.openfoodfacts.org/api/v2/search?countries_tags=en:argentina&format=csv&fields=code,product_name,brands,quantity,categories_tags
#
# 2) Generá el pack (acepta .csv o .csv.gz):
dart run bin/generar.dart \
  --entrada ~/descargas/off-argentina.csv.gz \
  --salida ../../app/assets/seed/catalogo-1.0.0.json \
  --version-pack 1.0.0
```

Opciones: `--limite N` acota la salida (útil para probar el pipeline con una
muestra chica antes de procesar el dump completo).

## Reglas de transformación

- Solo **EAN-13** (13 dígitos), deduplicado por código.
- Filas sin `product_name` o sin `quantity` interpretable se descartan
  (el pack garantiza nombre, marca y contenido neto).
- Cantidades normalizadas a **g / mL / unidad** (kg, L, cl se convierten).
- Si la fila declara países y ninguno es Argentina, se descarta.
- El pack incluye `fuente` y `licencia` (ODbL): la app muestra esa atribución
  en "Acerca de".

## Tests

```bash
dart test
```
