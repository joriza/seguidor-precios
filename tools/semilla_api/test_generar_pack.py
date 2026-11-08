#!/usr/bin/env python3
"""Tabla de referencia de normalizar_cantidad (v0.3.15, #13 S5).

Las 7 cadenas del diagnóstico + variantes multipack contra el parser de
semilla Python de generar_pack.py. Semántica: multipack «N x M unidad» /
«N unidades de M unidad» métrica → contenido TOTAL (N×M) en unidad
canónica {g, mL} (la semilla no tiene campo pack); '10 unidades' →
('unidad', N); sufijos informativos como la «e» del estiario europeo se
toleran.

Uso:  python test_generar_pack.py
Sale con código 1 si algún caso falla.
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import generar_pack  # noqa: E402

# (quantity, esperado (unidad, contenido_neto) o None)
TABLA = [
    # Las 7 cadenas del diagnóstico (S2).
    ("35 cl", ("mL", 350.0)),
    ("10 unidades", ("unidad", 10.0)),  # antes devolvía 1.0 (se perdía N)
    ("2 x 475 ml", ("mL", 950.0)),  # total N×M (antes se descartaba)
    ("1,5 L", ("mL", 1500.0)),
    ("500 g e", ("g", 500.0)),  # sufijo informativo tolerado
    ("6 unidades de 500 ml", ("mL", 3000.0)),  # antes ('unidad', 1.0)
    ("1 kg", ("g", 1000.0)),
    # Variantes multipack (S5).
    ("2x475ml", ("mL", 950.0)),  # sin espacios
    ("3 x 1,5 l", ("mL", 4500.0)),
    ("4 unidades de 125 g", ("g", 500.0)),
    ("2 x 1 kg", ("g", 2000.0)),
]

PRESERVADOS = [
    # Comportamiento previo que se conserva (sin descartes nuevos).
    ("500 g", ("g", 500.0)),
    ("500ml", ("mL", 500.0)),
    ("500 gramos", ("g", 500.0)),
    ("750 cc", ("mL", 750.0)),
    ("1 lt", ("mL", 1000.0)),
    ("5 u", ("unidad", 5.0)),
    ("pote grande", None),
    ("", None),
    ("2 x 475", None),  # multipack sin unidad interpretable
]


def main() -> int:
    fallas = 0
    total = 0
    for quantity, esperado in TABLA + PRESERVADOS:
        total += 1
        obtenido = generar_pack.normalizar_cantidad(quantity)
        if obtenido != esperado:
            fallas += 1
            print(f"FALLA {quantity!r}: esperado {esperado}, obtenido {obtenido}")
        else:
            print(f"ok    {quantity!r} -> {obtenido}")
    if fallas:
        print(f"{fallas} de {total} casos fallan")
        return 1
    print(f"{total} casos ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
