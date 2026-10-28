#!/usr/bin/env python3
"""cargar_semilla_supabase.py — T3 (Fase 2, S5/R10): carga inicial del semillero por lotes.

Sube el pack semilla existente (`app/assets/semilla/pack_semilla.json`, reutilizado
tal cual) a Supabase por lotes, en el orden de dependencias de la sync (T2):

    usuario -> articulo -> producto -> comercio -> precio -> valoracion

El pack v1 solo trae `productos`; el resto de las tablas queda sin filas (se
informan con 0). Los productos se suben con `articulo_id` NULL, igual que la
importacion local: clasificar articulos es tarea del dueno (Fase 1.6 / Fase 3).

Idempotencia: cada producto recibe un UUID determinista derivado de su EAN
(uuid5), y cada tabla se sube con upsert (`on_conflict=id`,
`resolution=merge-duplicates`). Re-ejecutar no duplica filas: actualiza las
mismas. El usuario semilla tambien es determinista.

Configuracion (nunca commiteada): archivo `.env` en la raiz del repo con

    SUPABASE_URL=https://<proyecto>.supabase.co
    SUPABASE_SERVICE_KEY=<service_role key>

La clave de servicio salta RLS: no compartirla ni registrarla. Si falta una de
las dos variables, el script corta con un mensaje claro (fail fast).

Requisitos: Python 3.11+ SOLO con libreria estandar (sin pip install). La
migracion de T1 debe estar aplicada en el proyecto Supabase antes de correr.

Uso:
    python tools/cargar_semilla_supabase.py                # carga real
    python tools/cargar_semilla_supabase.py --dry-run      # valida y cuenta, sin red
    python tools/cargar_semilla_supabase.py --lote 200     # tamanio de lote (defecto 100)
    python tools/cargar_semilla_supabase.py --pack RUTA --env RUTA

Salida 0 = ok; salida 1 = error de configuracion, pack o HTTP (con detalle).
"""

from __future__ import annotations

import argparse
import http.client
import json
import pathlib
import sys
import urllib.parse
import uuid
from datetime import UTC, datetime

# --- Constantes del modelo (docs/modelo-de-datos.md) -----------------------

FORMATO_PACK = "seguidor-precios-pack-semilla"

# Orden de dependencias del push (T2 / S5).
TABLAS_EN_ORDEN = ("usuario", "articulo", "producto", "comercio", "precio", "valoracion")

# Claves de pack que este cargador todavia no mapea (pack v1 solo productos).
CLAVES_NO_SOPORTADAS = {"articulos": "articulo", "comercios": "comercio", "precios": "precio", "valoraciones": "valoracion"}

# producto.unidad (R7/R12): kg, g, L, mL, unidad, m.
UNIDADES_VALIDAS = frozenset({"kg", "g", "L", "mL", "unidad", "m"})

ETIQUETA_USUARIO_SEMILLA = "Semillero (R10)"

# Espacio de nombres fijo para los UUID deterministas del semillero.
_NAMESPACE = uuid.uuid5(uuid.NAMESPACE_URL, "seguidor-precios/semilla")


class ErrorConfiguracion(Exception):
    """Configuracion, pack o peticion invalida: mensaje para el operador."""


# --- Configuracion (.env) ---------------------------------------------------

def leer_env(texto: str) -> dict[str, str]:
    """Parsea un .env simple: CLAVE=VALOR, sin espacios en la clave;
    ignora comentarios (#) y lineas vacias; quita comillas envolventes."""
    env: dict[str, str] = {}
    for linea in texto.splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#") or "=" not in linea:
            continue
        clave, _, valor = linea.partition("=")
        clave = clave.strip()
        valor = valor.strip()
        if len(valor) >= 2 and valor[0] == valor[-1] and valor[0] in ("'", '"'):
            valor = valor[1:-1]
        if clave:
            env[clave] = valor
    return env


def validar_env(env: dict[str, str]) -> tuple[str, str]:
    """Fail fast: exige SUPABASE_URL y SUPABASE_SERVICE_KEY."""
    faltantes = [k for k in ("SUPABASE_URL", "SUPABASE_SERVICE_KEY") if not env.get(k)]
    if faltantes:
        raise ErrorConfiguracion(
            "Faltan variables en el archivo .env de la raiz del repo: "
            + ", ".join(faltantes)
            + ". Crealo con:\n"
            "  SUPABASE_URL=https://<proyecto>.supabase.co\n"
            "  SUPABASE_SERVICE_KEY=<service_role key>\n"
            "(el .env no se commitea: esta en .gitignore)"
        )
    url = env["SUPABASE_URL"].rstrip("/")
    if not url.startswith(("http://", "https://")):
        raise ErrorConfiguracion(f"SUPABASE_URL invalida: {url!r} (esperaba https://<proyecto>.supabase.co)")
    return url, env["SUPABASE_SERVICE_KEY"]


# --- Pack -------------------------------------------------------------------

def validar_pack(pack: dict) -> None:
    """Formato esperado y claves aun no soportadas por este cargador."""
    if pack.get("formato") != FORMATO_PACK:
        raise ErrorConfiguracion(
            f"Pack con formato desconocido: {pack.get('formato')!r} (esperaba {FORMATO_PACK!r})"
        )
    for clave, tabla in CLAVES_NO_SOPORTADAS.items():
        if pack.get(clave):
            raise ErrorConfiguracion(
                f"El pack trae {clave!r} pero este cargador (pack v1) solo sube "
                f"'productos'; tabla destino: {tabla!r}. Actualizar el cargador o "
                "regenerar el pack sin esa clave."
            )


def _texto(valor) -> str:
    return valor if isinstance(valor, str) else ("" if valor is None else str(valor))


def contar_invalidos(pack: dict) -> int:
    """Filas del pack que se descartan: sin EAN, sin nombre o unidad fuera del dominio."""
    invalidos = 0
    for p in pack.get("productos") or []:
        if (
            not _texto(p.get("codigo_barras"))
            or not _texto(p.get("nombre"))
            or _texto(p.get("unidad")) not in UNIDADES_VALIDAS
        ):
            invalidos += 1
    return invalidos


# --- Mapeo a filas del servidor (snake_case, docs/modelo-de-datos.md) --------

def id_usuario_semilla() -> str:
    return str(uuid.uuid5(_NAMESPACE, "usuario"))


def mapear_producto(p: dict, usuario_id: str, instante: str) -> dict:
    """Fila de `producto`. Id determinista por EAN -> upsert idempotente.
    articulo_id NULL: clasificar es tarea del dueno (igual que la import local)."""
    codigo = _texto(p.get("codigo_barras"))
    marca = _texto(p.get("marca"))
    contenido = p.get("contenido_neto")
    return {
        "id": str(uuid.uuid5(_NAMESPACE, f"producto/{codigo}")),
        "codigo_barras": codigo,
        "articulo_id": None,
        "nombre": _texto(p.get("nombre")),
        "marca": marca or None,
        "categoria": _texto(p.get("categoria")) or None,
        "unidad": _texto(p.get("unidad")),
        "contenido_neto": float(contenido) if contenido is not None else None,
        "notas": None,
        "creado_por": usuario_id,
        "creado_en": instante,
        "actualizado_en": instante,
        "borrado_en": None,
    }


def mapear_productos(pack: dict, usuario_id: str, instante: str) -> list[dict]:
    """Filas validas del pack, en el orden original."""
    return [
        mapear_producto(p, usuario_id=usuario_id, instante=instante)
        for p in (pack.get("productos") or [])
        if _texto(p.get("codigo_barras"))
        and _texto(p.get("nombre"))
        and _texto(p.get("unidad")) in UNIDADES_VALIDAS
    ]


def en_lotes(filas: list[dict], tamanio: int) -> list[list[dict]]:
    """Parte la lista en lotes de `tamanio` respetando el orden."""
    if tamanio < 1:
        raise ValueError("el tamanio de lote debe ser >= 1")
    return [filas[i : i + tamanio] for i in range(0, len(filas), tamanio)]


# --- HTTP (PostgREST) ---------------------------------------------------------

def describir_error_http(tabla: str, codigo: int, razon: str, cuerpo: str = "") -> str:
    """Mensaje de error para el operador. Nunca incluye la clave de servicio."""
    detalle = (cuerpo or "").strip().replace("\n", " ")[:500]
    return f"[{tabla}] HTTP {codigo} {razon}: {detalle}"


def _conexion_segura(url: str, tabla: str) -> tuple[http.client.HTTPConnection, str]:
    """Conexion http.client con esquema exigido: https (o http solo local).
    Devuelve (conexion, ruta_de_peticion)."""
    partes = urllib.parse.urlsplit(f"{url}/rest/v1/{tabla}?on_conflict=id")
    host = partes.hostname
    if not host:
        raise ErrorConfiguracion(
            f"SUPABASE_URL sin host: {url!r} (usar https://<proyecto>.supabase.co)"
        )
    if partes.scheme == "https":
        fabrica: type[http.client.HTTPConnection] = http.client.HTTPSConnection
    elif partes.scheme == "http" and host in ("localhost", "127.0.0.1", "::1"):
        fabrica = http.client.HTTPConnection
    else:
        raise ErrorConfiguracion(
            f"SUPABASE_URL con esquema/host no permitido ({partes.scheme!r} {host!r}): usar https://<proyecto>.supabase.co"
        )
    conexion = fabrica(host, partes.port, timeout=30)
    return conexion, f"{partes.path}?{partes.query}"


def subir(url: str, clave: str, tabla: str, filas: list[dict]) -> None:
    """Upsert de un lote: POST /rest/v1/<tabla>?on_conflict=id con
    Prefer: resolution=merge-duplicates (idempotente)."""
    if not filas:
        return
    conexion, ruta = _conexion_segura(url, tabla)
    encabezados = {
        "apikey": clave,
        "Authorization": f"Bearer {clave}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates",
    }
    try:
        conexion.request("POST", ruta, body=json.dumps(filas).encode("utf-8"), headers=encabezados)
        respuesta = conexion.getresponse()
        cuerpo = respuesta.read().decode("utf-8", "replace")
        if respuesta.status >= 400:
            raise ErrorConfiguracion(
                describir_error_http(tabla, respuesta.status, respuesta.reason, cuerpo)
            )
    except (OSError, http.client.HTTPException) as err:
        raise ErrorConfiguracion(f"[{tabla}] error de red: {err}") from err
    finally:
        conexion.close()


def subir_por_lotes(url: str, clave: str, tabla: str, filas: list[dict], tamanio: int) -> int:
    lotes = en_lotes(filas, tamanio)
    for i, lote in enumerate(lotes, start=1):
        print(f"  {tabla}: lote {i}/{len(lotes)} ({len(lote)} filas)...", flush=True)
        subir(url, clave, tabla, lote)
    return len(filas)


# --- Principal -----------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    raiz = pathlib.Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description="Carga el pack semilla (R10) a Supabase por lotes.")
    parser.add_argument("--pack", type=pathlib.Path, default=raiz / "app" / "assets" / "semilla" / "pack_semilla.json",
                        help="ruta del pack semilla (defecto: app/assets/semilla/pack_semilla.json)")
    parser.add_argument("--env", type=pathlib.Path, default=raiz / ".env",
                        help="ruta del .env (defecto: .env en la raiz del repo)")
    parser.add_argument("--lote", type=int, default=100, help="filas por lote (defecto: 100)")
    parser.add_argument("--dry-run", action="store_true", help="valida y cuenta sin conectarse")
    args = parser.parse_args(argv)

    # 1) Configuracion: fail fast con mensaje claro (T3.3).
    if not args.env.is_file():
        raise ErrorConfiguracion(
            f"No existe el archivo .env en {args.env}. Crealo en la raiz del repo con "
            "SUPABASE_URL y SUPABASE_SERVICE_KEY (no se commitea: esta en .gitignore)."
        )
    url, clave = validar_env(leer_env(args.env.read_text(encoding="utf-8")))

    # 2) Pack existente: se reutiliza tal cual (T3.1).
    if not args.pack.is_file():
        raise ErrorConfiguracion(f"No existe el pack semilla en {args.pack}.")
    pack = json.loads(args.pack.read_text(encoding="utf-8"))
    validar_pack(pack)

    instante = datetime.now(UTC).isoformat(timespec="seconds")
    usuario_id = id_usuario_semilla()
    filas_producto = mapear_productos(pack, usuario_id=usuario_id, instante=instante)
    invalidos = contar_invalidos(pack)

    usuario_semilla = {
        "id": usuario_id,
        "etiqueta": ETIQUETA_USUARIO_SEMILLA,
        "auth_uid": None,
        "creado_en": instante,
        "actualizado_en": instante,
    }

    print(f"Pack: {args.pack}")
    print(f"Productos validos: {len(filas_producto)} (invalidos descartados: {invalidos})")
    print(f"Lote: {args.lote} filas | Orden: {' -> '.join(TABLAS_EN_ORDEN)}")

    if args.dry_run:
        print("dry-run: no se conecto a Supabase.")
        return 0

    # 3) Carga por lotes en orden de dependencias (T3.2). El pack v1 solo
    #    trae productos: el resto de las tablas viaja sin filas.
    subir(url, clave, "usuario", [usuario_semilla])
    print("  usuario: 1 fila (semilla determinista) ok", flush=True)
    for tabla in ("articulo", "comercio", "precio", "valoracion"):
        print(f"  {tabla}: 0 filas (el pack v1 no trae datos)", flush=True)
    total = subir_por_lotes(url, clave, "producto", filas_producto, args.lote)
    print(f"Listo: {total} productos en upsert idempotente (re-ejecutar no duplica).")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ErrorConfiguracion as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
