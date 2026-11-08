#!/usr/bin/env python3
"""Genera el pack semilla (R10) desde la API de Open Food Facts.

A diferencia de tools/seed (que transforma el dump CSV completo — paso del
operador), este generador produce un pack CURADO de productos populares con
prefijo GS1 Argentina (777/778/779), pensado para viajar como asset del APK.

Reglas (equivalentes a tools/seed): solo EAN-13 argentino, sin nombre o sin
cantidad interpretable se descarta, cantidades normalizadas a g/mL/unidad
(kg/L/cl/cc convertidos), dedup por EAN.

Uso:
  python generar_pack.py [paginas] [salida]        # descarga y arma
  python generar_pack.py --desde-dir DIR [salida]  # arma desde JSONs locales
  (archivos pagina_NN.json descargados con curl; OFF suele 503 a clientes
  scripting, el reintento con curl es el paso del operador)
"""

import json
import pathlib
import re
import sys
import time

import requests

API = (
    "https://world.openfoodfacts.org/api/v2/search"
    "?countries_tags=argentina"
    "&fields=code,product_name,brands,quantity"
    "&sort_by=unique_scans_n&page_size=100&page={page}"
)
UA = "seguidor-precios-seed/0.1 (github.com/joriza/seguidor-precios)"
PREFIJOS_ARGENTINA = ("777", "778", "779")

_CANTIDAD = re.compile(r"^([0-9]+(?:[.,][0-9]+)?)\s*([a-zA-Z]*)")

# Multipack OFF (v0.3.15, S5): «N x M unidad» / «N unidades de M unidad»
# métrica. La semilla no tiene campo pack (el JSON v1 no lo lleva) →
# contenido TOTAL (N×M) en unidad canónica.
_MULTIPACK = re.compile(
    r"^\s*([0-9]+)\s*(?:x|unidades?\s+de)\s*([0-9]+(?:[.,][0-9]+)?)\s*"
    r"(kg|g|cl|ml|l)\s*(?:e|℮)?\s*$"
)

# Unidad métrica cruda → (canónica {g, mL}, factor de conversión).
_METRICAS = {
    "kg": ("g", 1000),
    "g": ("g", 1),
    "cl": ("mL", 10),
    "ml": ("mL", 1),
    "l": ("mL", 1000),
}


def normalizar_cantidad(quantity: str):
    """Devuelve (unidad, contenido_neto) o None si no es interpretable.

    v0.3.15 (S5): multipack «N x M unidad» / «N unidades de M unidad» →
    contenido TOTAL (N×M) en unidad canónica {g, mL}; '10 unidades' →
    ('unidad', N) (antes se perdía N); sufijos informativos como la «e»
    del estiario europeo ('500 g e') se toleran.
    """
    texto = (quantity or "").strip().lower()
    multi = _MULTIPACK.match(texto)
    if multi:
        pack = float(multi.group(1))
        por_unidad = float(multi.group(2).replace(",", "."))
        metrica = _METRICAS.get(multi.group(3))
        if pack <= 0 or por_unidad <= 0 or metrica is None:
            return None
        canonica, factor = metrica
        return (canonica, round(pack * por_unidad * factor, 2))
    m = _CANTIDAD.match(texto)
    if not m:
        return None
    valor = float(m.group(1).replace(",", "."))
    unidad = m.group(2)
    if unidad in ("u", "un", "uni", "unidades", "unidad"):
        # v0.3.15 (S5): ('unidad', N) — antes se devolvía 1.0 fijo.
        return ("unidad", valor)
    if unidad in ("g", "gr", "grs", "gramos"):
        return ("g", round(valor, 2))
    if unidad == "kg":
        return ("g", round(valor * 1000, 2))
    if unidad in ("ml", "cc"):
        return ("mL", round(valor, 2))
    if unidad in ("l", "lt", "lts", "litros"):
        return ("mL", round(valor * 1000, 2))
    if unidad == "cl":
        return ("mL", round(valor * 10, 2))
    return None


OPENER = None  # (requests gestiona conexiones; sin openers urllib)


def descargar(paginas: int) -> list:
    productos = []
    for page in range(1, paginas + 1):
        lote = []
        data = {}
        for intento in range(1, 5):
            try:
                r = requests.get(
                    API.format(page=page),
                    headers={"User-Agent": UA},
                    timeout=30,
                )
                r.raise_for_status()
                data = r.json()
                lote = data.get("products", [])
                break
            except (requests.RequestException, ValueError) as e:
                espera = 3 * intento
                print(f"pagina {page} intento {intento}: {e} — espero {espera}s")
                time.sleep(espera)
        productos.extend(lote)
        print(f"pagina {page}: {len(lote)} filas (total {len(productos)})")
        if not lote:
            break
        if page >= data.get("page_count", page):
            break
        time.sleep(1)
    return productos


def armar_pack(filas: list) -> dict:
    pack = {}
    for fila in filas:
        codigo = (fila.get("code") or "").strip()
        nombre = (fila.get("product_name") or "").strip()
        if (
            len(codigo) != 13
            or not codigo.isdigit()
            or not codigo.startswith(PREFIJOS_ARGENTINA)
            or len(nombre) < 3
            or codigo in pack
        ):
            continue
        cantidad = normalizar_cantidad(fila.get("quantity") or "")
        if cantidad is None:
            continue
        unidad, contenido = cantidad
        marca = (fila.get("brands") or "").split(",")[0].strip()
        pack[codigo] = {
            "codigo_barras": codigo,
            "nombre": nombre[:80],
            "marca": marca[:60],
            "unidad": unidad,
            "contenido_neto": contenido,
        }
    return {
        "formato": "seguidor-precios-pack-semilla",
        "version": 1,
        "productos": sorted(pack.values(), key=lambda p: p["codigo_barras"]),
    }


def descargar_desde_dir(directorio: str) -> list:
    """Lee pagina_NN.json de [directorio] en orden y concatena los lotes."""
    filas = []
    rutas = sorted(pathlib.Path(directorio).glob("pagina_*.json"))
    for ruta in rutas:
        try:
            with open(ruta, encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError) as e:
            print(f"{ruta.name}: IGNORADO ({e})")
            continue
        lote = data.get("products", [])
        filas.extend(lote)
        print(f"{ruta.name}: {len(lote)} filas (total {len(filas)})")
    return filas


def main() -> None:
    args = sys.argv[1:]
    if args and args[0] == "--desde-dir":
        if len(args) < 2:
            sys.exit("uso: generar_pack.py --desde-dir DIR [salida]")
        directorio = args[1]
        salida = args[2] if len(args) > 2 else "../../app/assets/semilla/pack_semilla.json"
        pack = armar_pack(descargar_desde_dir(directorio))
    else:
        paginas = int(args[0]) if args else 20
        salida = args[1] if len(args) > 1 else "../../app/assets/semilla/pack_semilla.json"
        pack = armar_pack(descargar(paginas))
    with open(salida, "w", encoding="utf-8") as f:
        json.dump(pack, f, ensure_ascii=False, indent=1)
    print(f"pack: {len(pack['productos'])} productos -> {salida}")


if __name__ == "__main__":
    main()
