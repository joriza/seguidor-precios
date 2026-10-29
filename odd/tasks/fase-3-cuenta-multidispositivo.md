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
  ajuste de auth en backend. Ruta: worker + tests. Commit: d84bf53 (feat(cuenta)). Riesgo de la
  unidad: item 2 (seguridad/RLS) — verificación inline del padre (ver Log L4/L5); el runtime no
  admitió verificador independiente delegado (la delegación no declaraba Risk line).
- T4 (S3) — Multi-dispositivo: restaurar identidad/datos en instalación nueva vía login. Ruta:
  worker + tests. Commit: en curso (worker background).
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
- L5 — Verificación de seguridad de 0005 por el padre (ítem 2), tras rechazo del runtime al
  verificador independiente delegado: (1) en 0001 actualizacion_propia ya era FOR UPDATE →
  recrearla como FOR UPDATE no pierde cobertura (INSERT=alta_colaborativa, SELECT=
  lectura_colaborativa); (2) adopción acotada: USING exige auth_uid de sesión o fila anónima
  (es_usuario_anonimo, SECURITY DEFINER, search_path '', REVOKE PUBLIC + GRANT authenticated,
  booleano puro) y WITH CHECK fuerza auth_uid = auth.uid() → cuenta verificada jamás adoptable;
  (3) idempotente y transaccional; (4) admin_dueno no es tocado por 0005; (5) flujo cliente:
  push genérico .upsert() — post-vinculación la fila del servidor lleva el auth_uid anónimo
  VIEJO y la sesión el uid NUEVO → gobierna el UPDATE que 0005 habilita; instalación nunca
  sincronizada va por INSERT con WITH CHECK propio; colisión uq_usuario_auth_uid (segunda
  instalación misma cuenta) = frontera T4 documentada en el header de 0005. Interplay vivo
  (RLS real + SMTP + template) queda a la validación de campo T5.
- L4 — T3 ejecutado por worker en background (task mvtuuyxz-2-r0dh) con TDD (13 tests RED→GREEN:
  pedido de magic link signInWithOtp, completado con código de 6 dígitos verifyOTP in-app — el
  deep-link del email queda como follow-up fuera de superficies —, vinculación de la fila local
  EXISTENTE sin duplicar identidad, errores en español por modo de fallo). Migración 0005
  (nueva): política actualizacion_propia de usuario re-creada FOR UPDATE con adopción SOLO de
  filas cuyo auth_uid es anónimo (es_usuario_anonimo SECURITY DEFINER); WITH CHECK sin cambios.
  Verificación del padre sobre blobs commiteados: en 0001 actualizacion_propia ya era FOR UPDATE
  (INSERT vive en alta_colaborativa, SELECT en lectura_colaborativa) → sin pérdida de cobertura;
  cuenta verificada nunca adoptable. Suite 217/217 (204 + 13) y analyze limpios, observados
  inline. Commit d84bf53 (849 líneas). ASSESS nativo: nativeRisk medium, reviewDue false
  (under_budget); escalado item 2 (seguridad/RLS) → plan con verificador independiente
  (gentle-ai-verify en background, lee blobs commiteados d84bf53). Pasos del lado del dueño
  (reportados por el worker, pendientes): (1) aplicar 0005 en Studio (idempotente); (2) template
  Magic Link con {{ .Token }}; (3) SMTP propio (builtin ~2 emails/hora); (4) Site URL;
  (5) chequeo de campo en T5. Franja de commits: unidad T3 de 849 líneas excede la guía de
  ~400 — para PR usar chained-pr (slices: docs+fix 372 / feat 849) o aceptar slice único;
  decisión de entrega en T5.
