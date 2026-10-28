# Desarrollo

> **Estado:** **Fase 2 — colaborativa** con código completo (suite 199/199) y backend Supabase
> operativo con el semillero cargado (424 productos). Pendiente: validación en dispositivo y
> release v0.2.0 (ver [hoja de ruta](hoja-de-ruta.md)). Este documento describe el entorno y las
> convenciones vigentes.

## Entorno

| Herramienta | Uso |
| --- | --- |
| Flutter SDK (canal estable) | Compilar y correr la app |
| Android Studio / Android SDK | Emulador y herramientas de Android |
| JDK 17 | Requerido por las herramientas de Android |
| Git | Control de versiones |
| Cuenta de Supabase (gratuita) | Backend colaborativo (Fase 2) |

Verificación del entorno: `flutter doctor` (sin ítems en rojo).

## Comandos (desde Fase 0)

```bash
flutter pub get               # dependencias
flutter run                   # correr en dispositivo/emulador
flutter analyze               # análisis estático (debe pasar sin warnings)
flutter test                  # tests
dart format .                 # formato
flutter build apk --release   # APK para GitHub Releases
```

El script de la semilla se corre aparte (Fase 1): ver [Semilla del catálogo](#semilla-del-catálogo-toolsseed).

## Convenciones

- **Commits:** Conventional Commits, en inglés (`feat: add barcode scanner screen`).
- **Código e identificadores:** en inglés; comentarios de código en inglés.
- **Documentación y UI de la app:** en español.
- **Tests:** por cada regla nueva, un test que falle primero (test-first); DAOs probados con SQLite en memoria; widgets clave con `flutter_test`; la normalización de unidades (R11) con tests de tabla.
- **Ramas:** trabajo por rama de feature; commits en unidades revisables (~400 líneas).

## Estructura prevista (Fase 0/1)

```text
seguidor-precios/
├── app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── data/
│   │   │   ├── local/        # drift: tablas, DAOs, base
│   │   │   └── sync/         # outbox y cliente Supabase (Fase 2)
│   │   ├── features/
│   │   │   ├── escaner/
│   │   │   ├── productos/
│   │   │   ├── articulos/    # comparador por artículo (R11/R12)
│   │   │   ├── comercios/
│   │   │   ├── precios/
│   │   │   └── historial/
│   │   └── shared/           # widgets y utilidades comunes
│   └── test/
├── tools/
│   └── seed/                 # generador del pack semilla (Fase 1)
├── supabase/
│   └── migrations/           # esquema SQL versionado (Fase 2)
└── admin/                    # web de mantenimiento del dueño (Fase 2, condicional)
```

## Semilla del catálogo (`tools/seed`)

- Script de línea de comandos (Dart o Node.js) que descarga el dump público de Open Food Facts /
  Open Products Facts, filtra `countries_tags = argentina` y genera
  `app/assets/seed/catalogo-<version>.json` con: EAN-13, nombre, marca, cantidad normalizada
  (contenido neto + unidad) y categoría.
- Se corre a mano cuando se quiere refrescar el catálogo; el pack se versiona en el repo o se
  publica en GitHub Releases si pesa demasiado.
- El pack incluye su metadato de atribución (`fuente`, `licencia`, `version`) que la app muestra en "Acerca de".

## Backend colaborativo (Fase 2)

Runbook de puesta en marcha; el detalle del esquema está en
[Modelo de datos · Esquema backend (Postgres)](modelo-de-datos.md#esquema-backend-postgres).

1. **Crear el proyecto** en supabase.com (plan gratuito) con **anonymous sign-ins** activado
   (Authentication → Sign In / Up → Anonymous): la app se identifica con un login anónimo. Guardar
   la URL y la clave anónima del proyecto.
2. **Aplicar el esquema** desde el SQL Editor de Supabase Studio: en un proyecto nuevo, pegar el
   archivo único `supabase/migracion-completa.sql`; en un proyecto existente, solo las migraciones
   nuevas de `supabase/migrations/` en orden. Son idempotentes (pueden re-ejecutarse). Antes de
   ejecutar: reemplazar el placeholder `<<UID_DUENO>>` por el `auth_uid` del dueño (AD-015).
3. **Cargar el semillero** con `python tools/cargar_semilla_supabase.py`: crear un `.env` en la
   raíz del repo con `SUPABASE_URL` y `SUPABASE_SERVICE_KEY` (clave de servicio nueva
   `sb_secret_...` o legacy `service_role`). El `.env` está en `.gitignore` y **nunca se commitea**.
   `--dry-run` valida el pack sin red; `--lote N` ajusta el tamaño de lote (100 por defecto).
4. **Idempotencia:** re-ejecutar el cargador no duplica filas — cada producto lleva un UUID
   determinista derivado de su EAN y cada tabla se sube con upsert (`on_conflict=id`).
5. **Apuntar la app:** la URL del proyecto y la clave anónima (pública por diseño, AD-002) viven en
   un único punto, `app/lib/data/sync/config_backend.dart`; apuntar a otra infraestructura es un
   cambio de configuración, no de código (R16, AD-011).

Convenciones vigentes:

- El esquema de Postgres se versiona con migraciones SQL en el repo (`supabase/migrations/`); en
  desarrollo puede correrse Supabase local con su CLI.
- Auth anónimo (`signInAnonymously`, incluido en el free tier); el enlace mágico (`signInWithOtp`)
  queda diferido a Fase 3 (R17).
- Mantenimiento de datos en pruebas: **Supabase Studio** (borrados lógicos, asignación de
  artículos, correcciones); la web `admin/` del dueño se construye cuando el panel quede corto
  (R18, AD-013).
