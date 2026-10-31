-- =============================================================================
-- seguidor-precios — v0.3.8 — Migración 0006: pack del producto (S1, backlog #10)
--
-- El producto gana `pack`: cuántas unidades del contenido neto trae la
-- presentación (fideos: contenido 500 g + pack 10 → el pack trae 5 kg).
-- El pack sirve SOLO para normalizar el precio: precio normalizado =
-- precio ÷ (pack × contenido_neto). La identificación no cambia (S3): cada
-- presentación tiene su propio código de barras y su propia fila.
--
-- Compatibilidad (S6): las filas existentes quedan con pack = 1 (el default
-- del ADD COLUMN aplica a toda fila pre-existente); la semilla no cambia;
-- los backups viejos importan con pack = 1 (la app no exige la clave).
--
-- ORDEN DE DESPLIEGUE (S6): aplicar ESTE script en Supabase Studio ANTES de
-- instalar la app v0.3.8 en cualquier dispositivo. Si un dispositivo con
-- v0.3.8 empuja productos a un servidor sin `pack`, el push falla por
-- columna desconocida.
--
-- Idempotente en intención: ADD COLUMN IF NOT EXISTS evita error si ya se
-- aplicó. Puede re-ejecutarse.
--
-- Referencias: docs/modelo-de-datos.md (columna espejo de SQLite local v5),
-- odd/tasks/v0.3.8-packs.md (S1, S2, S6).
-- =============================================================================

BEGIN;

-- S1: entero ≥ 1, default 1 (presentación simple). Sin CHECK: la validación
-- vive en la app (formulario); el servidor queda espejo tolerante, igual que
-- `tipo` en comercio desde 0004.
ALTER TABLE producto ADD COLUMN IF NOT EXISTS pack integer NOT NULL DEFAULT 1;

COMMENT ON COLUMN producto.pack IS
    'Cuántas unidades del contenido neto trae la presentación (default 1). Sirve solo para normalizar el precio: precio ÷ (pack × contenido_neto).';

COMMIT;
