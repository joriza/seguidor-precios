-- =============================================================================
-- seguidor-precios — Fase 3 — Migración 0005: vinculación de cuenta (T3, S3)
--
-- R17/AD-003: al completar el enlace mágico (signInWithOtp + OTP de email),
-- la identidad anónima de la instalación pasa a la cuenta real de email.
-- En el servidor eso significa actualizar `usuario.auth_uid` de la fila de
-- la instalación: la política `actualizacion_propia` de 0001 solo dejaba
-- tocar la fila a quien ya era su dueño (auth_uid = auth.uid()), exactamente
-- lo que la vinculación cambia. Sin este ajuste, el push del usuario con la
-- sesión nueva falla en RLS y la sync queda rota para esa instalación.
--
-- Se permite la adopción SOLO de filas cuyo auth_uid actual es un usuario
-- ANÓNIMO (auth.users.is_anonymous, visto por una función SECURITY DEFINER,
-- mismo patrón que es_admin/es_propio): nadie puede apropiarse la identidad
-- de una cuenta con email verificada. La fila resultante siempre queda con
-- auth_uid = auth.uid() de quien actúa (WITH CHECK sin cambios).
--
-- Nota T4 (fuera de alcance acá): vincular la MISMA cuenta desde una segunda
-- instalación chocará con uq_usuario_auth_uid si el servidor ya tiene otra
-- fila de usuario con ese auth_uid; la resolución multi-dispositivo es tarea
-- propia de T4.
--
-- El resto del modelo no cambia: SELECT sigue colaborativo, INSERT exige
-- auth_uid propio, el dueño (admin_dueno) mantiene acceso total y los
-- triggers (actualizado_en, guardia de borrado) siguen aplicando.
-- Idempotente: puede re-ejecutarse.
--
-- Referencias: docs/requisitos.md (R17), docs/decisiones.md (AD-003),
-- docs/arquitectura.md (regla de sync 9).
-- =============================================================================

BEGIN;

-- ¿El auth_uid corresponde a un usuario anónimo (signInAnonymously)?
-- SECURITY DEFINER porque auth.users no es legible por authenticated; solo
-- responde true/false, nunca expone datos del usuario.
CREATE OR REPLACE FUNCTION public.es_usuario_anonimo(p_auth_uid text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $fn$
    SELECT EXISTS (
        SELECT 1
          FROM auth.users a
         WHERE a.id::text = p_auth_uid
           AND a.is_anonymous
    )
$fn$;

REVOKE ALL ON FUNCTION public.es_usuario_anonimo(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.es_usuario_anonimo(text) TO authenticated;

-- Adopción de identidad: además del dueño de la fila, una sesión con email
-- verificado puede actualizar la fila cuya identidad actual es anónima.
DROP POLICY IF EXISTS actualizacion_propia ON usuario;
CREATE POLICY actualizacion_propia ON usuario
    AS PERMISSIVE FOR UPDATE TO authenticated
    USING (
        auth_uid = auth.uid()::text
        OR (auth_uid IS NOT NULL AND public.es_usuario_anonimo(auth_uid))
    )
    WITH CHECK (auth_uid IS NOT NULL AND auth_uid = auth.uid()::text);

COMMIT;
