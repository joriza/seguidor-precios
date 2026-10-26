# Desarrollo

> **Estado:** aún no hay código. Este documento describe el entorno y las convenciones que se
> usarán desde la **Fase 0** (ver [hoja de ruta](hoja-de-ruta.md)).

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
└── tools/
    └── seed/                 # generador del pack semilla (Fase 1)
```

## Semilla del catálogo (`tools/seed`)

- Script de línea de comandos (Dart o Node.js) que descarga el dump público de Open Food Facts /
  Open Products Facts, filtra `countries_tags = argentina` y genera
  `app/assets/seed/catalogo-<version>.json` con: EAN-13, nombre, marca, cantidad normalizada
  (contenido neto + unidad) y categoría.
- Se corre a mano cuando se quiere refrescar el catálogo; el pack se versiona en el repo o se
  publica en GitHub Releases si pesa demasiado.
- El pack incluye su metadato de atribución (`fuente`, `licencia`, `version`) que la app muestra en "Acerca de".

## Supabase (Fase 2)

- Crear proyecto gratuito en supabase.com; guardar URL y clave anónima.
- El esquema de Postgres se versiona con migraciones SQL dentro del repo (`supabase/migrations/`).
- En desarrollo puede correrse Supabase local con su CLI.
- La URL y la clave del backend viven en un único punto de configuración (entorno/flavor): apuntar a
  otra infraestructura es cambio de configuración, no de código (R16, AD-011).
- Auth: anónimo (`signInAnonymously`), incluido en el free tier; el login por enlace mágico
  (`signInWithOtp`) queda diferido a Fase 3 (R17).
- Mantenimiento de datos en pruebas: **Supabase Studio** (panel incluido). La web de administración
  del dueño (`admin/`) se construye cuando el panel quede corto (R18, AD-013).
