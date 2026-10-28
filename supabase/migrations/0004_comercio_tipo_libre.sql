-- =============================================================================
-- seguidor-precios — Fase 2 — Migración 0004: tipo de comercio sin CHECK
--
-- Corrección: el CHECK ck_comercio_tipo restringía `tipo` a un enum viejo
-- ('almacen','carniceria','verduleria','ferreteria','otro') que no incluye
-- los tipos que la app ofrece desde v0.1.3 ('supermercado','hipermercado').
-- Localmente la columna es texto libre sin restricción (la validación vive
-- en la UI); el backend queda espejo: sin CHECK.
--
-- Idempotente en intención; DROP ... IF EXISTS evita error si ya se soltó.
--
-- Referencias: docs/arquitectura.md (reglas de sync 1-9), app/lib/features/
-- comercios/alta_comercio_dialog.dart (tiposComercio).
-- =============================================================================

BEGIN;

ALTER TABLE comercio DROP CONSTRAINT IF EXISTS ck_comercio_tipo;

COMMIT;
