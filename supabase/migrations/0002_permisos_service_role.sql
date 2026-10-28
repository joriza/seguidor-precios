-- =============================================================================
-- seguidor-precios — Fase 2 — Migración 0002: privilegios de service_role
--
-- Corrección: la migración 0001 otorgó privilegios a authenticated (AD-016)
-- pero no a service_role, que no hereda por defecto (el REVOKE de PUBLIC deja
-- las tablas solo para su dueño). Sin esto, el cargador del semillero (clave
-- service) recibe "permission denied for table" al subir filas.
--
-- Idempotente: puede re-ejecutarse. RLS sigue filtrando las filas; esto solo
-- habilita el acceso a nivel de tabla para el rol de servicio.
--
-- Referencias: docs/arquitectura.md (reglas de sync 1-9), docs/decisiones.md
-- (AD-015, AD-016).
-- =============================================================================

BEGIN;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

COMMIT;
