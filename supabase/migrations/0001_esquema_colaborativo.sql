-- =============================================================================
-- seguidor-precios — Fase 2 colaborativa — Migración 0001
-- Esquema backend: 6 tablas espejo, índices, triggers, RPC y RLS mínima.
--
-- Espejo del esquema local v2 (app/lib/data/local/tablas.dart, drift): mismos
-- nombres de columna en snake_case. Tipos Postgres según docs/modelo-de-datos.md
-- (uuid / timestamptz / numeric / date); la conversión texto ISO-8601 local
-- <-> tipos nativos la hace la capa de sync (T2).
--
-- Idempotente: puede re-ejecutarse (CREATE IF NOT EXISTS / OR REPLACE /
-- DROP IF EXISTS). Para pegar de una pieza en Supabase Studio usar
-- supabase/migracion-completa.sql (mismo DDL concatenado).
--
-- ANTES DE USAR (AD-015): reemplazar el placeholder <<UID_DUENO>> por el
-- auth_uid real del dueño. Mientras no se reemplace, la regla de admin evalúa
-- falso (comparación por texto, sin error): operación segura por defecto.
--
-- Referencias: docs/arquitectura.md (reglas de sync 1-9), docs/modelo-de-datos.md,
-- docs/decisiones.md (AD-015, AD-016).
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 0) Extensión (gen_random_uuid() en Postgres < 13; no-op en Supabase actual)
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- 1) Tablas espejo (misma forma que SQLite local; borrado siempre lógico)
-- -----------------------------------------------------------------------------

-- Instalación de la app (identidad anónima). Regla de sync 9: usuario.id es el
-- id local del dispositivo; auth_uid (del signInAnonymously) resuelve la
-- identidad de lo creado offline. Único por cuenta (mapeo 1:1).
CREATE TABLE IF NOT EXISTS usuario (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    etiqueta       text NOT NULL,
    auth_uid       text,
    creado_en      timestamptz NOT NULL DEFAULT now(),
    actualizado_en timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_usuario_auth_uid UNIQUE (auth_uid)
);

-- Tipo de producto genérico (R11/R12): agrupa productos y define la unidad de
-- comparación.
CREATE TABLE IF NOT EXISTS articulo (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre         text NOT NULL,
    categoria      text,
    unidad_base    text NOT NULL,
    creado_por     uuid NOT NULL,
    creado_en      timestamptz NOT NULL DEFAULT now(),
    actualizado_en timestamptz NOT NULL DEFAULT now(),
    borrado_en     timestamptz,
    CONSTRAINT ck_articulo_unidad_base CHECK (unidad_base IN ('kg', 'L', 'unidad', 'm')),
    CONSTRAINT fk_articulo_creado_por FOREIGN KEY (creado_por) REFERENCES usuario (id)
);

-- Marca + presentación concreta. codigo_barras: único parcial si existe (dedup
-- por EAN, R4/R13); articulo_id nullable hasta clasificar (R11).
CREATE TABLE IF NOT EXISTS producto (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_barras  text,
    articulo_id    uuid,
    nombre         text NOT NULL,
    marca          text,
    categoria      text,
    unidad         text NOT NULL,
    contenido_neto numeric,
    origen         text,
    notas          text,
    creado_por     uuid NOT NULL,
    creado_en      timestamptz NOT NULL DEFAULT now(),
    actualizado_en timestamptz NOT NULL DEFAULT now(),
    borrado_en     timestamptz,
    CONSTRAINT ck_producto_unidad CHECK (unidad IN ('kg', 'g', 'L', 'mL', 'unidad', 'm')),
    CONSTRAINT fk_producto_articulo FOREIGN KEY (articulo_id) REFERENCES articulo (id),
    CONSTRAINT fk_producto_creado_por FOREIGN KEY (creado_por) REFERENCES usuario (id)
);

CREATE TABLE IF NOT EXISTS comercio (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre         text NOT NULL,
    tipo           text,
    direccion      text,
    creado_por     uuid NOT NULL,
    creado_en      timestamptz NOT NULL DEFAULT now(),
    actualizado_en timestamptz NOT NULL DEFAULT now(),
    borrado_en     timestamptz,
    CONSTRAINT ck_comercio_tipo CHECK (tipo IN ('almacen', 'carniceria', 'verduleria', 'ferreteria', 'otro')),
    CONSTRAINT fk_comercio_creado_por FOREIGN KEY (creado_por) REFERENCES usuario (id)
);

-- Append-only (modelo, regla de integridad 1): ni sync ni usuario modifican
-- valor, comercio ni fecha. Única excepción: re-apunte de producto_id en la
-- dedup por EAN (lo ejecuta el servidor, RPC dedup_ean). cargado_en es el
-- cursor de pull de la tabla y la normaliza el servidor (regla de sync 3).
CREATE TABLE IF NOT EXISTS precio (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id  uuid NOT NULL,
    comercio_id  uuid NOT NULL,
    precio       numeric(12, 2) NOT NULL,
    fecha_toma   date NOT NULL,
    cargado_por  uuid NOT NULL,
    cargado_en   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_precio_positivo CHECK (precio > 0),
    CONSTRAINT fk_precio_producto FOREIGN KEY (producto_id) REFERENCES producto (id),
    CONSTRAINT fk_precio_comercio FOREIGN KEY (comercio_id) REFERENCES comercio (id),
    CONSTRAINT fk_precio_cargado_por FOREIGN KEY (cargado_por) REFERENCES usuario (id)
);

-- Valoración personal (v2, v0.1.5). En Fase 2 viaja en la sync; la ponderación
-- con valoraciones ajenas queda postergada (S2). Volver a neutro sin
-- observación elimina la fila (DELETE propio, ver RLS).
CREATE TABLE IF NOT EXISTS valoracion (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id     uuid NOT NULL,
    producto_id    uuid NOT NULL,
    gusto          text,
    observacion    text,
    creado_en      timestamptz NOT NULL DEFAULT now(),
    actualizado_en timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_valoracion_gusto CHECK (gusto IN ('si', 'no')),
    CONSTRAINT uq_valoracion_usuario_producto UNIQUE (usuario_id, producto_id),
    CONSTRAINT fk_valoracion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id),
    CONSTRAINT fk_valoracion_producto FOREIGN KEY (producto_id) REFERENCES producto (id)
);

-- -----------------------------------------------------------------------------
-- 2) Índices (docs/modelo-de-datos.md — Índices principales)
-- -----------------------------------------------------------------------------

-- Único parcial sobre codigo_barras: solo filas vigentes (borrado_en IS NULL).
-- Base de la dedup colaborativa por EAN (R4/R13).
CREATE UNIQUE INDEX IF NOT EXISTS uq_producto_codigo_barras
    ON producto (codigo_barras)
    WHERE codigo_barras IS NOT NULL AND borrado_en IS NULL;

CREATE INDEX IF NOT EXISTS idx_articulo_nombre       ON articulo (nombre);
CREATE INDEX IF NOT EXISTS idx_producto_articulo     ON producto (articulo_id);
CREATE INDEX IF NOT EXISTS idx_producto_nombre       ON producto (nombre);
CREATE INDEX IF NOT EXISTS idx_producto_marca        ON producto (marca);
CREATE INDEX IF NOT EXISTS idx_comercio_nombre       ON comercio (nombre);
CREATE INDEX IF NOT EXISTS idx_precio_producto_fecha ON precio (producto_id, fecha_toma DESC);
CREATE INDEX IF NOT EXISTS idx_precio_fecha          ON precio (fecha_toma);
CREATE INDEX IF NOT EXISTS idx_precio_cargado_en     ON precio (cargado_en); -- cursor de pull (regla de sync 3)
CREATE INDEX IF NOT EXISTS idx_valoracion_producto   ON valoracion (producto_id);
CREATE INDEX IF NOT EXISTS idx_valoracion_usuario    ON valoracion (usuario_id);

-- -----------------------------------------------------------------------------
-- 3) Triggers: columnas de sync son propiedad del servidor
-- -----------------------------------------------------------------------------

-- El servidor estampa actualizado_en en todo insert/update: es el árbitro de
-- la última-escritura-gana y el cursor de pull (reglas de sync 3 y 4).
CREATE OR REPLACE FUNCTION fn_actualizado_en()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $fn$
BEGIN
    NEW.actualizado_en := now();
    RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS trg_actualizado_en ON articulo;
CREATE TRIGGER trg_actualizado_en BEFORE INSERT OR UPDATE ON articulo
    FOR EACH ROW EXECUTE FUNCTION fn_actualizado_en();

DROP TRIGGER IF EXISTS trg_actualizado_en ON producto;
CREATE TRIGGER trg_actualizado_en BEFORE INSERT OR UPDATE ON producto
    FOR EACH ROW EXECUTE FUNCTION fn_actualizado_en();

DROP TRIGGER IF EXISTS trg_actualizado_en ON comercio;
CREATE TRIGGER trg_actualizado_en BEFORE INSERT OR UPDATE ON comercio
    FOR EACH ROW EXECUTE FUNCTION fn_actualizado_en();

DROP TRIGGER IF EXISTS trg_actualizado_en ON usuario;
CREATE TRIGGER trg_actualizado_en BEFORE INSERT OR UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION fn_actualizado_en();

DROP TRIGGER IF EXISTS trg_actualizado_en ON valoracion;
CREATE TRIGGER trg_actualizado_en BEFORE INSERT OR UPDATE ON valoracion
    FOR EACH ROW EXECUTE FUNCTION fn_actualizado_en();

-- precio no tiene actualizado_en: su marca es cargado_en y la normaliza el
-- servidor al recibir el push (evita sesgos de reloj entre dispositivos).
CREATE OR REPLACE FUNCTION fn_precio_normalizar_cargado_en()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $fn$
BEGIN
    NEW.cargado_en := now();
    RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS trg_precio_normalizar_cargado_en ON precio;
CREATE TRIGGER trg_precio_normalizar_cargado_en BEFORE INSERT ON precio
    FOR EACH ROW EXECUTE FUNCTION fn_precio_normalizar_cargado_en();

-- Append-only server-side: solo se permite el re-apunte de producto_id (dedup).
CREATE OR REPLACE FUNCTION fn_precio_append_only()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $fn$
BEGIN
    IF OLD.precio      IS DISTINCT FROM NEW.precio
       OR OLD.comercio_id IS DISTINCT FROM NEW.comercio_id
       OR OLD.fecha_toma  IS DISTINCT FROM NEW.fecha_toma
       OR OLD.cargado_por IS DISTINCT FROM NEW.cargado_por
       OR OLD.cargado_en  IS DISTINCT FROM NEW.cargado_en THEN
        RAISE EXCEPTION 'precio es append-only: solo se permite re-apuntar producto_id (dedup por EAN)';
    END IF;
    RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS trg_precio_append_only ON precio;
CREATE TRIGGER trg_precio_append_only BEFORE UPDATE ON precio
    FOR EACH ROW EXECUTE FUNCTION fn_precio_append_only();

-- Guardia del borrado lógico (AD-016): cada uno borra (lógico) solo lo suyo.
-- Se implementa por trigger porque los GRANT de columnas no pueden distinguir
-- filas propias de ajenas junto con la corrección abierta de clasificación.
-- auth.uid() NULL = sesión de servidor (Studio / clave de servicio / RPC
-- SECURITY DEFINER): permitido. La dedup por EAN se marca con el GUC
-- app.dedup_en_curso para poder borrar duplicados de terceros.
CREATE OR REPLACE FUNCTION fn_guardia_borrado_logico()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $fn$
BEGIN
    IF NEW.borrado_en IS DISTINCT FROM OLD.borrado_en
       AND auth.uid() IS NOT NULL
       AND coalesce(current_setting('app.dedup_en_curso', true), '') <> 'si'
       AND NOT public.es_propio(OLD.creado_por)
       AND NOT public.es_admin() THEN
        RAISE EXCEPTION 'borrado lógico permitido solo al creador de la fila (AD-016)';
    END IF;
    RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS trg_guardia_borrado_logico ON articulo;
CREATE TRIGGER trg_guardia_borrado_logico BEFORE UPDATE ON articulo
    FOR EACH ROW EXECUTE FUNCTION fn_guardia_borrado_logico();

DROP TRIGGER IF EXISTS trg_guardia_borrado_logico ON producto;
CREATE TRIGGER trg_guardia_borrado_logico BEFORE UPDATE ON producto
    FOR EACH ROW EXECUTE FUNCTION fn_guardia_borrado_logico();

DROP TRIGGER IF EXISTS trg_guardia_borrado_logico ON comercio;
CREATE TRIGGER trg_guardia_borrado_logico BEFORE UPDATE ON comercio
    FOR EACH ROW EXECUTE FUNCTION fn_guardia_borrado_logico();

-- -----------------------------------------------------------------------------
-- 4) Identidad y admin (regla de sync 9, AD-015)
-- -----------------------------------------------------------------------------

-- Admin único por uid fijo del dueño (AD-015). Comparación por texto: mientras
-- el placeholder <<UID_DUENO>> no se reemplace evalúa falso, sin error.
CREATE OR REPLACE FUNCTION es_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $fn$
    SELECT auth.uid() IS NOT NULL AND auth.uid()::text = '<<UID_DUENO>>'
$fn$;

REVOKE ALL ON FUNCTION es_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION es_admin() TO authenticated;

-- ¿La fila me pertenece? creado_por/cargado_por/usuario_id apuntan a un
-- usuario cuyo auth_uid coincide con la sesión anónima actual.
CREATE OR REPLACE FUNCTION es_propio(p_usuario_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $fn$
    SELECT EXISTS (
        SELECT 1
          FROM public.usuario u
         WHERE u.id = p_usuario_id
           AND u.auth_uid IS NOT NULL
           AND u.auth_uid = auth.uid()::text
    )
$fn$;

REVOKE ALL ON FUNCTION es_propio(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION es_propio(uuid) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5) RPC
-- -----------------------------------------------------------------------------

-- Ping anti-pausa (R14): consulta mínima que mantiene despierto el proyecto
-- gratuito; no sincroniza datos.
CREATE OR REPLACE FUNCTION ping()
RETURNS integer
LANGUAGE sql
SET search_path = ''
AS $fn$
    SELECT 1;
$fn$;

REVOKE ALL ON FUNCTION ping() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION ping() TO anon, authenticated;

-- Dedup por EAN (regla de sync 6). Devuelve el id del producto canónico para
-- el código dado (NULL si el EAN no existe en el servidor). Si había más de un
-- producto vigente con ese EAN, re-apunta sus precios al canónico (única
-- mutación de precio permitida: el puntero) y da de baja lógica los duplicados.
-- Idempotente. SECURITY DEFINER: el re-apunte lo ejecuta el servidor (AD-016);
-- usar search_path vacío y calificar el esquema.
CREATE OR REPLACE FUNCTION dedup_ean(p_codigo_barras text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $fn$
DECLARE
    v_canonico uuid;
BEGIN
    IF p_codigo_barras IS NULL THEN
        RETURN NULL;
    END IF;

    PERFORM set_config('app.dedup_en_curso', 'si', true);

    SELECT p.id INTO v_canonico
      FROM public.producto p
     WHERE p.codigo_barras = p_codigo_barras
       AND p.borrado_en IS NULL
     ORDER BY p.creado_en, p.id
     LIMIT 1;

    IF v_canonico IS NULL THEN
        RETURN NULL;
    END IF;

    UPDATE public.precio
       SET producto_id = v_canonico
     WHERE producto_id IN (
           SELECT d.id
             FROM public.producto d
            WHERE d.codigo_barras = p_codigo_barras
              AND d.id <> v_canonico
              AND d.borrado_en IS NULL);

    UPDATE public.producto
       SET borrado_en = now()
     WHERE codigo_barras = p_codigo_barras
       AND id <> v_canonico
       AND borrado_en IS NULL;

    RETURN v_canonico;
END;
$fn$;

REVOKE ALL ON FUNCTION dedup_ean(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION dedup_ean(text) TO authenticated;

-- -----------------------------------------------------------------------------
-- 6) RLS mínima (AD-016) + admin (AD-015)
--
-- Sin FORCE ROW LEVEL SECURITY: el dueño (rol postgres de Studio) corrige el
-- resto sin límites. Los autenticados anónimos (rol `authenticated`) pueden:
--   - leer todo (ese es el fin colaborativo);
--   - insertar filas a su propio nombre (identidad resuelta por auth_uid);
--   - corregir campos de clasificación de cualquiera (columnas del GRANT);
--   - borrar (lógico) solo lo suyo (guardia por trigger);
--   - precios: solo inserción (el re-apunte de dedup lo ejecuta el servidor);
--   - valoracion: leer/insertar/editar/borrar (fila) solo las propias.
-- Sin rate limiting ni cola de moderación: diferido a Fase 4 (AD-016).
-- -----------------------------------------------------------------------------

ALTER TABLE usuario    ENABLE ROW LEVEL SECURITY;
ALTER TABLE articulo   ENABLE ROW LEVEL SECURITY;
ALTER TABLE producto   ENABLE ROW LEVEL SECURITY;
ALTER TABLE comercio   ENABLE ROW LEVEL SECURITY;
ALTER TABLE precio     ENABLE ROW LEVEL SECURITY;
ALTER TABLE valoracion ENABLE ROW LEVEL SECURITY;

-- Solo la app autenticada anónimamente accede por API; el anon key sin sesión
-- no lee ni escribe nada.
REVOKE ALL ON usuario, articulo, producto, comercio, precio, valoracion FROM anon, PUBLIC;
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT, INSERT ON usuario, articulo, producto, comercio, precio, valoracion TO authenticated;

-- Correcciones de clasificación abiertas (AD-016) + borrado_en propio
-- (la propiedad de la fila la verifica el trigger fn_guardia_borrado_logico).
GRANT UPDATE (nombre, categoria, unidad_base, borrado_en) ON articulo TO authenticated;
GRANT UPDATE (articulo_id, nombre, marca, categoria, borrado_en) ON producto TO authenticated;
GRANT UPDATE (nombre, tipo, direccion, borrado_en) ON comercio TO authenticated;
GRANT UPDATE (etiqueta, auth_uid) ON usuario TO authenticated;
GRANT UPDATE (gusto, observacion) ON valoracion TO authenticated;

-- Volver a neutro sin observación elimina la fila de valoracion (modelo v2).
GRANT DELETE ON valoracion TO authenticated;
-- precio: sin UPDATE ni DELETE (append-only, AD-016).

-- --- usuario ---
DROP POLICY IF EXISTS lectura_colaborativa ON usuario;
CREATE POLICY lectura_colaborativa ON usuario
    AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS alta_colaborativa ON usuario;
CREATE POLICY alta_colaborativa ON usuario
    AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (auth_uid IS NOT NULL AND auth_uid = auth.uid()::text);

DROP POLICY IF EXISTS actualizacion_propia ON usuario;
CREATE POLICY actualizacion_propia ON usuario
    AS PERMISSIVE FOR UPDATE TO authenticated
    USING (auth_uid = auth.uid()::text)
    WITH CHECK (auth_uid = auth.uid()::text);

DROP POLICY IF EXISTS admin_dueno ON usuario;
CREATE POLICY admin_dueno ON usuario
    AS PERMISSIVE FOR ALL TO authenticated
    USING (public.es_admin())
    WITH CHECK (public.es_admin());

-- --- articulo ---
DROP POLICY IF EXISTS lectura_colaborativa ON articulo;
CREATE POLICY lectura_colaborativa ON articulo
    AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS alta_colaborativa ON articulo;
CREATE POLICY alta_colaborativa ON articulo
    AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (public.es_propio(creado_por));

-- Columnas limitadas por el GRANT; borrado lógico limitado por la guardia.
DROP POLICY IF EXISTS actualizacion_colaborativa ON articulo;
CREATE POLICY actualizacion_colaborativa ON articulo
    AS PERMISSIVE FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS admin_dueno ON articulo;
CREATE POLICY admin_dueno ON articulo
    AS PERMISSIVE FOR ALL TO authenticated
    USING (public.es_admin())
    WITH CHECK (public.es_admin());

-- --- producto ---
DROP POLICY IF EXISTS lectura_colaborativa ON producto;
CREATE POLICY lectura_colaborativa ON producto
    AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS alta_colaborativa ON producto;
CREATE POLICY alta_colaborativa ON producto
    AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (public.es_propio(creado_por));

DROP POLICY IF EXISTS actualizacion_colaborativa ON producto;
CREATE POLICY actualizacion_colaborativa ON producto
    AS PERMISSIVE FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS admin_dueno ON producto;
CREATE POLICY admin_dueno ON producto
    AS PERMISSIVE FOR ALL TO authenticated
    USING (public.es_admin())
    WITH CHECK (public.es_admin());

-- --- comercio ---
DROP POLICY IF EXISTS lectura_colaborativa ON comercio;
CREATE POLICY lectura_colaborativa ON comercio
    AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS alta_colaborativa ON comercio;
CREATE POLICY alta_colaborativa ON comercio
    AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (public.es_propio(creado_por));

DROP POLICY IF EXISTS actualizacion_colaborativa ON comercio;
CREATE POLICY actualizacion_colaborativa ON comercio
    AS PERMISSIVE FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS admin_dueno ON comercio;
CREATE POLICY admin_dueno ON comercio
    AS PERMISSIVE FOR ALL TO authenticated
    USING (public.es_admin())
    WITH CHECK (public.es_admin());

-- --- precio (solo lectura e inserción) ---
DROP POLICY IF EXISTS lectura_colaborativa ON precio;
CREATE POLICY lectura_colaborativa ON precio
    AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS alta_colaborativa ON precio;
CREATE POLICY alta_colaborativa ON precio
    AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (public.es_propio(cargado_por));

DROP POLICY IF EXISTS admin_dueno ON precio;
CREATE POLICY admin_dueno ON precio
    AS PERMISSIVE FOR ALL TO authenticated
    USING (public.es_admin())
    WITH CHECK (public.es_admin());

-- --- valoracion (personal: solo filas propias salvo lectura) ---
DROP POLICY IF EXISTS lectura_colaborativa ON valoracion;
CREATE POLICY lectura_colaborativa ON valoracion
    AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS alta_colaborativa ON valoracion;
CREATE POLICY alta_colaborativa ON valoracion
    AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (public.es_propio(usuario_id));

DROP POLICY IF EXISTS actualizacion_propia ON valoracion;
CREATE POLICY actualizacion_propia ON valoracion
    AS PERMISSIVE FOR UPDATE TO authenticated
    USING (public.es_propio(usuario_id))
    WITH CHECK (public.es_propio(usuario_id));

DROP POLICY IF EXISTS borrado_propio ON valoracion;
CREATE POLICY borrado_propio ON valoracion
    AS PERMISSIVE FOR DELETE TO authenticated
    USING (public.es_propio(usuario_id));

DROP POLICY IF EXISTS admin_dueno ON valoracion;
CREATE POLICY admin_dueno ON valoracion
    AS PERMISSIVE FOR ALL TO authenticated
    USING (public.es_admin())
    WITH CHECK (public.es_admin());

-- -----------------------------------------------------------------------------
-- 7) Comentarios de esquema
-- -----------------------------------------------------------------------------
COMMENT ON TABLE usuario IS 'Instalación de la app (identidad anónima); auth_uid mapea la sesión signInAnonymously (regla de sync 9).';
COMMENT ON TABLE articulo IS 'Tipo de producto genérico con unidad_base; agrupa productos para comparar (R11/R12).';
COMMENT ON TABLE producto IS 'Marca + presentación concreta; codigo_barras único parcial si existe (dedup por EAN, R4).';
COMMENT ON COLUMN producto.origen IS 'semilla si vino del pack de Open Food Facts; NULL si lo cargó un usuario.';
COMMENT ON TABLE comercio IS 'Lugar donde se toma el precio.';
COMMENT ON TABLE precio IS 'Append-only: nunca se actualiza ni borra, salvo el re-apunte de producto_id por dedup (servidor).';
COMMENT ON COLUMN precio.cargado_en IS 'Fecha de carga real, normalizada por el servidor; cursor de pull de la tabla (regla de sync 3).';
COMMENT ON TABLE valoracion IS 'Valoración personal por usuario y producto; se sincroniza, ponderación comunitaria postergada (S2).';
COMMENT ON COLUMN articulo.borrado_en IS 'Borrado lógico: NULL = vigente (regla de sync 5).';
COMMENT ON COLUMN producto.borrado_en IS 'Borrado lógico: NULL = vigente (regla de sync 5).';
COMMENT ON COLUMN comercio.borrado_en IS 'Borrado lógico: NULL = vigente (regla de sync 5).';

COMMIT;
