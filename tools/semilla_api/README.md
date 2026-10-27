# semilla_api — generador del pack curado (v0.1.1)

Genera el pack semilla que viaja como asset del APK
(`app/assets/semilla/pack_semilla.json`) desde la API de Open Food Facts,
filtrado a productos con prefijo GS1 Argentina (777/778/779).

A diferencia de `tools/seed` (pipeline del dump CSV completo — paso del
operador, pensado para la Fase 2), este generador produce un pack CHICO
(~400 productos populares) suficiente para que el escáner reconozca
productos de consumo masivo en la validación en teléfono.

## Uso

```bash
# Descarga (OFF suele devolver 503 a clientes scripting: el reintento con
# curl es deliberado; el script arma el pack desde los JSON locales)
mkdir -p /tmp/off_pages
for page in $(seq 1 20); do
  f=/tmp/off_pages/pagina_$(printf %02d $page).json
  until [ "$(curl -s --max-time 30 -o "$f" -w '%{http_code}' \
    'https://world.openfoodfacts.org/api/v2/search?countries_tags=argentina&fields=code,product_name,brands,quantity&sort_by=unique_scans_n&page_size=100&page='"$page")" = "200" ]; do
    sleep 40
  done
done

# Armado del pack (requiere python3 + requests)
python generar_pack.py --desde-dir /tmp/off_pages ../../app/assets/semilla/pack_semilla.json
```

El importador (`app/lib/data/local/importar_semilla.dart`, T3 de Fase 1)
descarta filas sin nombre, sin unidad interpretable o con EAN no argentino;
la dedup por EAN hace que regenerar el pack sea seguro.

## Nota

10 páginas (1000 candidatas) rindieron 424 productos (v0.1.1). Para un
catálogo completo, usar el dump CSV completo vía `tools/seed`.
