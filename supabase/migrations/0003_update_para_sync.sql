-- =============================================================================
-- seguidor-precios — Fase 2 — Migración 0003: UPDATE completo para la sync
--
-- Corrección: el upsert de la sync (INSERT ... ON CONFLICT DO UPDATE, reglas
-- de sync 1 y 4 — última escritura gana por fila) exige privilegio UPDATE en
-- las columnas escritas, y Postgres lo chequea al planificar aunque la fila
-- sea nueva. Los GRANT de UPDATE por columna de 0001 (pensados para la
-- corrección manual de clasificación) bloqueaban el push: 42501 permission
-- denied en la primera tabla (usuario).
--
-- El modelo de integridad NO cambia: RLS sigue definiendo qué filas toca
-- cada quien, y los triggers del servidor siguen aplicando las invariantes
-- (actualizado_en del servidor, precio append-only, borrado lógico solo del
-- creador, normalización del cursor).
--
-- Idempotente: puede re-ejecutarse.
--
-- Referencias: docs/arquitectura.md (reglas de sync 1-9), docs/decisiones.md
-- (AD-015, AD-016).
-- =============================================================================

BEGIN;

GRANT UPDATE ON usuario, articulo, producto, comercio, precio, valoracion TO authenticated;

COMMIT;
