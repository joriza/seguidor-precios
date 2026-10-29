# Fase 3 — Cuenta multi-dispositivo (post-MVP) + críticos C1/C2 del juicio

Fase 3 del Seguidor de Precios: primero los 2 críticos del pull confirmados por el juicio dual
(C1/C2, prioridad máxima), luego la cuenta opcional multi-dispositivo con enlace mágico (tarea 3.7).
Fuente normativa: docs/hoja-de-ruta.md (Fase 3), docs/requisitos.md (R17), docs/decisiones.md
(AD-003), Log L20 de odd/tasks/fase-2-colaborativo.md, ledger del juicio en
apk-debug/judgment-fase2-ledger.json (gitignored, local).

## Specs

- S1 — Crítico C1 (juicio dual ciego, Log L20 fase-2): "inanición de paginación del pull con ≥100
  timestamps iguales — un dispositivo nuevo solo baja 100/424 del catálogo". El pull debe bajar
  TODO lo nuevo sin importar cuántas filas compartan el mismo `actualizado_en`, y el cursor solo
  avanza hasta el último dato efectivamente guardado.
- S2 — Crítico C2 (juicio dual ciego, Log L20 fase-2): "colisión de EAN en el pull — ids
  sem-<ean> locales vs uuid5 del servidor violan el UNIQUE local → el pull del teléfono del dueño
  está roto: sube pero nunca baja, crash antes de guardarCursor". El pull de un producto cuyo EAN
  ya existe como fila de semilla debe converger con el servidor sin violar el UNIQUE local, sin
  crash, guardando el cursor y sin perder precios/comercios vinculados.
- S3 — Tarea 3.7 de docs/hoja-de-ruta.md: "Cuenta opcional multi-dispositivo con enlace mágico
  (diferida de la etapa de pruebas)" (cubre R17, AD-003): login opcional por email con magic
  link, la identidad local queda vinculada a la cuenta y puede restaurarse en otra instalación.

## Tasks

- T1 (S1) — Fix C1: paginación del pull sin inanición. Ruta: worker + tests. Commit:
  d04dea1 (fix(sync), unidad única junto con T2: comparten la ruta del pull y el grupo de
  tests).
- T2 (S2) — Fix C2: convergencia de ids de semilla con el servidor en el pull. Ruta: worker +
  tests. Commit: d04dea1 (ídem T1).
- T3 (S3) — Cuenta por email (magic link): UI de login opcional + vinculación de identidad +
  ajuste de auth en backend. Ruta: worker + tests. Commit: feat(cuenta).
- T4 (S3) — Multi-dispositivo: restaurar identidad/datos en instalación nueva vía login. Ruta:
  worker + tests. Commit: feat(cuenta).
- T5 (S1-S3) — Estado en docs/hoja-de-ruta.md (Fase 3 en curso), release v0.3.0 y validación en
  dispositivo del dueño. Ruta: parent + dueño.

## Log

- L1 — "Dame los comandos de punto 1 que debo aplicar. / He instalado la version 0.2.2 y parece
  que vá bien / incia con la fase 3": el dueño pide el SQL de es_admin (entregado en la
  conversación), reporta v0.2.2 instalada y funcionando, y autoriza iniciar la Fase 3. Alcance
  acordado: C1/C2 (prioridad máxima del juicio) + cuenta multi-dispositivo (3.7); el resto de las
  tareas 3.x y el backlog de mejoras #1-#6 quedan candidatos a priorizar con datos de uso.
- L2 — "Recuera aplicar todo lo mas posible en 1 agente en paralelo para preservar el contexto
  actual": el trabajo pesado se delega a UN worker por vez, en background/paralelo, para preservar
  el contexto de la sesión padre.
- L3 — T1+T2 ejecutados por worker en background (task mvtu0zzt-1-iyt8) con TDD: RED reproduce
  C1 (solo 100/251 bajan; inanición) y C2 (SqliteException UNIQUE codigo_barras desde
  _aplicarFilaRemota, crash antes de guardarCursor — síntoma exacto del teléfono del dueño);
  GREEN: pull keyset (actualizado_en, id) con cursor por página aplicada (C1) y convergencia
  atómica por EAN (libera EAN → merge LWW bajo id del servidor, re-encola edit local ganador,
  re-apunta precios/valoraciones, descarta duplicado + entrada de outbox) sin migración de
  esquema (v4 intacta, supabase/migrations sin tocar). Verificación del padre: suite 204/204
  (201 previos + 3 nuevos) y analyze --fatal-infos limpio, observados inline. Commits: aad13e8
  (docs ODD) + d04dea1 (fix, 372 líneas). Riesgo declarado por el worker: el filtro keyset
  or(...) de PostgREST no se ejercitó contra Supabase vivo en tests (fake emula el contrato);
  la primera pull real del dueño (T5) lo valida en campo.
