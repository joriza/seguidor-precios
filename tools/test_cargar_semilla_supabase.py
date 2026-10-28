"""Tests de tools/cargar_semilla_supabase.py (T3, R10) — solo stdlib.

Ejecutar:  python -m unittest discover -s tools -p "test_cargar_*.py"
"""

import importlib.util
import pathlib
import unittest

_RAIZ = pathlib.Path(__file__).resolve().parent.parent
_RUTA_SCRIPT = _RAIZ / "tools" / "cargar_semilla_supabase.py"

_spec = importlib.util.spec_from_file_location("cargar_semilla_supabase", _RUTA_SCRIPT)
assert _spec is not None and _spec.loader is not None, f"no se pudo cargar {_RUTA_SCRIPT}"
mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mod)


def _pack_minimo():
    return {
        "formato": "seguidor-precios-pack-semilla",
        "version": 1,
        "productos": [
            {
                "codigo_barras": "7790000000011",
                "nombre": "Prueba A",
                "marca": "Marca",
                "unidad": "g",
                "contenido_neto": 500.0,
            },
            {
                "codigo_barras": "7790000000028",
                "nombre": "Prueba B",
                "marca": "",
                "unidad": "mL",
                "contenido_neto": 1000.0,
            },
        ],
    }


class LeerEnvTest(unittest.TestCase):
    def test_lee_claves_y_ignora_comentarios(self):
        env = mod.leer_env(
            "SUPABASE_URL=https://x.supabase.co\n"
            "# comentario\n"
            "\n"
            'SUPABASE_SERVICE_KEY="sk_123"\n'
            "OTRA=no\n"
        )
        self.assertEqual(env.get("SUPABASE_URL"), "https://x.supabase.co")
        self.assertEqual(env.get("SUPABASE_SERVICE_KEY"), "sk_123")
        # Claves ajenas no rompen el parseo; validar_env solo exige las dos de Supabase.
        self.assertEqual(env.get("OTRA"), "no")

    def test_falta_url_falla_con_mensaje_claro(self):
        with self.assertRaises(mod.ErrorConfiguracion) as ctx:
            mod.validar_env({"SUPABASE_SERVICE_KEY": "sk"})
        self.assertIn("SUPABASE_URL", str(ctx.exception))

    def test_falta_service_key_falla_con_mensaje_claro(self):
        with self.assertRaises(mod.ErrorConfiguracion) as ctx:
            mod.validar_env({"SUPABASE_URL": "https://x.supabase.co"})
        self.assertIn("SUPABASE_SERVICE_KEY", str(ctx.exception))

    def test_mensaje_http_no_filtra_secretos(self):
        mensaje = mod.describir_error_http(
            "producto", 401, "Unauthorized", '{"message":"invalid api key sk_secreto..."}'
        )
        self.assertNotIn("SUPABASE_SERVICE_KEY", mensaje)
        self.assertIn("401", mensaje)
        self.assertIn("producto", mensaje)

    def test_esquema_no_https_rechazado(self):
        with self.assertRaises(mod.ErrorConfiguracion):
            mod._conexion_segura("file:///etc", "producto")

    def test_http_solo_localhost(self):
        with self.assertRaises(mod.ErrorConfiguracion):
            mod._conexion_segura("http://ejemplo-remoto.supabase.co", "producto")


class MapeoProductoTest(unittest.TestCase):
    def test_fila_servidor_completa(self):
        usuario_id = "11111111-1111-1111-1111-111111111111"
        fila = mod.mapear_producto(
            _pack_minimo()["productos"][0], usuario_id=usuario_id, instante="2026-01-01T00:00:00+00:00"
        )
        self.assertEqual(fila["codigo_barras"], "7790000000011")
        self.assertEqual(fila["nombre"], "Prueba A")
        self.assertEqual(fila["marca"], "Marca")
        self.assertEqual(fila["unidad"], "g")
        self.assertEqual(fila["contenido_neto"], 500.0)
        self.assertIsNone(fila["articulo_id"])
        self.assertIsNone(fila["borrado_en"])
        self.assertEqual(fila["creado_por"], usuario_id)
        self.assertEqual(fila["creado_en"], "2026-01-01T00:00:00+00:00")

    def test_marca_vacia_es_null(self):
        usuario_id = "11111111-1111-1111-1111-111111111111"
        fila = mod.mapear_producto(
            _pack_minimo()["productos"][1], usuario_id=usuario_id, instante="2026-01-01T00:00:00+00:00"
        )
        self.assertIsNone(fila["marca"])

    def test_id_determinista_por_ean(self):
        """Idempotencia (T3): re-mapear el mismo EAN da el mismo id (upsert, no duplicado)."""
        p = _pack_minimo()["productos"][0]
        id1 = mod.mapear_producto(p, usuario_id="u", instante="t")["id"]
        id2 = mod.mapear_producto(p, usuario_id="u", instante="t")["id"]
        self.assertEqual(id1, id2)

    def test_ids_distintos_por_ean_distinto(self):
        p1, p2 = _pack_minimo()["productos"]
        id1 = mod.mapear_producto(p1, usuario_id="u", instante="t")["id"]
        id2 = mod.mapear_producto(p2, usuario_id="u", instante="t")["id"]
        self.assertNotEqual(id1, id2)


class UsuarioSemillaTest(unittest.TestCase):
    def test_usuario_determinista(self):
        u1 = mod.id_usuario_semilla()
        u2 = mod.id_usuario_semilla()
        self.assertEqual(u1, u2)

    def test_etiqueta_identificable(self):
        self.assertEqual(mod.ETIQUETA_USUARIO_SEMILLA, "Semillero (R10)")


class MapeoPackTest(unittest.TestCase):
    def test_filas_validas_en_orden_y_sin_articulo(self):
        filas = mod.mapear_productos(_pack_minimo(), usuario_id="u", instante="t")
        self.assertEqual(len(filas), 2)
        self.assertEqual(filas[0]["codigo_barras"], "7790000000011")

    def test_invalidos_se_descartan_con_conteo(self):
        pack = _pack_minimo()
        pack["productos"].extend(
            [
                {"codigo_barras": "", "nombre": "x", "unidad": "g", "contenido_neto": 1},
                {"codigo_barras": "7790000000035", "nombre": "", "unidad": "g", "contenido_neto": 1},
                {"codigo_barras": "7790000000042", "nombre": "x", "unidad": "litros", "contenido_neto": 1},
            ]
        )
        filas = mod.mapear_productos(pack, usuario_id="u", instante="t")
        self.assertEqual(len(filas), 2)
        self.assertEqual(mod.contar_invalidos(pack), 3)

    def test_pack_con_formato_desconocido_falla(self):
        with self.assertRaises(mod.ErrorConfiguracion):
            mod.validar_pack({"formato": "otro", "version": 1, "productos": []})

    def test_claves_de_tablas_no_soportadas_fallan_claro(self):
        pack = _pack_minimo()
        pack["precios"] = [{"id": "x"}]
        with self.assertRaises(mod.ErrorConfiguracion) as ctx:
            mod.validar_pack(pack)
        self.assertIn("precios", str(ctx.exception))


class LotesTest(unittest.TestCase):
    def test_parte_en_lotes_respetando_orden(self):
        self.assertEqual(mod.en_lotes([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]])

    def test_lotes_vacio_y_exacto(self):
        self.assertEqual(mod.en_lotes([], 10), [])
        self.assertEqual(mod.en_lotes([1, 2], 2), [[1, 2]])


if __name__ == "__main__":
    unittest.main()
