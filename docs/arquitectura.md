# Arquitectura

## Principio rector: local-first

La **fuente de verdad es la base SQLite del dispositivo**. La app funciona 100% sin conexión:
escanear, dar de alta productos, artículos y comercios, registrar precios, comparar y consultar el
historial nunca dependen de la red. La nube (Supabase) es una **capa de colaboración**: acumula
aportes de todos los usuarios y los distribuye cuando hay conexión.

Si el backend deja de estar disponible (pausa del plan gratuito, caída, migración), la app sigue
funcionando intacta y los datos locales no se pierden.

## Componentes

```mermaid
flowchart TD
    subgraph App["App Android (Flutter)"]
        UI["Pantallas: escáner · producto · artículo/comparador · comercio · precio · historial"]
        SCAN["Escáner (mobile_scanner / ML Kit, on-device)"]
        REPO["Capa de datos (drift)"]
        DB[("SQLite local")]
        OUT["Outbox de sync (cola de cambios)"]
        SYNC["Servicio de sync"]
    end
    subgraph Nube["Supabase (plan gratuito)"]
        PG[("Postgres")]
        RLS["Reglas de acceso (RLS)"]
        AUTH["Auth anónimo (signInAnonymously)"]
    end

    UI --> REPO
    SCAN --> UI
    REPO --> DB
    REPO --> OUT
    OUT --> SYNC
    SYNC -- "push/pull HTTPS" --> PG
    RLS --- PG
    AUTH --- SYNC
```

### Decisiones por componente

| Componente | Elección | Motivo |
| --- | --- | --- |
| UI y lógica | Flutter | Un solo código Android, iOS posible a futuro ([AD-001](decisiones.md#ad-001--flutter-como-framework-de-la-app)) |
| BD local | SQLite + `drift` | SQL tipado, migraciones, formato eterno y exportable ([AD-004](decisiones.md#ad-004--sqlite-vía-drift-como-base-local)) |
| Escáner | ML Kit on-device | Funciona offline, sin costo, sin servidores ([AD-005](decisiones.md#ad-005--escáner-ml-kit-on-device)) |
| Semilla de catálogo | Open Food Facts / Open Products Facts (ODbL) | Catálogo argentino con EAN-13, gratuito y durable ([AD-008](decisiones.md#ad-008--catálogo-semilla-desde-open-food-facts--open-products-facts)) |
| Backend | Supabase (Postgres) | Colaboración con datos exportables y reglas de acceso ([AD-002](decisiones.md#ad-002--supabase-como-backend-colaborativo)) |
| Identidad | Auth anónimo + ID de dispositivo | Cero fricción, sin registro ([AD-003](decisiones.md#ad-003--identidad-anónima--id-de-dispositivo)) |

## Datos semilla y enriquecimiento (R10)

Para que la app no inicie vacía, el catálogo base se genera **offline** desde bases de datos
abiertas y viaja dentro del APK:

```mermaid
flowchart LR
    OFF["Open Food Facts /<br/>Open Products Facts<br/>(dump abierto, ODbL)"] --> GEN["Script generador<br/>tools/seed (offline)"]
    GEN -- "filtra Argentina,<br/>normaliza marca, unidad y contenido" --> PACK["Pack semilla<br/>(JSON versionado en assets)"]
    PACK -- "primer inicio<br/>(import en segundo plano)" --> DB[("SQLite local")]
    DB -- "Fase 2: carga inicial por lotes" --> PG[("Supabase")]
```

- **Generación:** `tools/seed` descarga el dump público, filtra `countries_tags = argentina`,
  normaliza nombre, marca y cantidad ("500 g" → contenido neto + unidad) y emite un pack JSON versionado.
- **Import en primer inicio:** el pack se importa al SQLite local marcando el origen (`semilla`);
  corre en segundo plano y no bloquea el uso de la app.
- **Enriquecimiento (Fase 2):** al escanear un EAN desconocido con conexión, la app consulta la
  API abierta para precargar nombre/marca/contenido antes del alta manual (siempre confirmada por el usuario).
- **Licencia:** los datos provienen de Open Food Facts bajo ODbL; la app muestra la atribución en
  "Acerca de" y el catálogo derivado mantiene compatibilidad de licencia (share-alike).

## Flujo de sincronización

```mermaid
sequenceDiagram
    autonumber
    participant D as App (dispositivo)
    participant S as Supabase (Postgres)
    Note over D: Usuario registra un precio (offline)
    D->>D: Guarda en SQLite y encola en outbox
    D->>S: PUSH: upsert de cambios (por id, cuando hay red)
    S->>S: Dedup por código de barras + RLS
    S-->>D: Confirma ids definitivos
    D->>S: PULL: filras con actualizado_en > último sync
    S-->>D: Datos de otros usuarios
    D->>D: Merge local (última escritura gana, por fila)
```

### Reglas de sincronización

1. **Identificadores:** UUID generados en el dispositivo → no hay colisiones entre usuarios y el merge es trivial.
2. **Outbox:** todo cambio local (artículos, productos, comercios, precios) se encola; el push sube por lotes cuando hay red (automático o manual).
3. **Pull incremental:** cada tabla se consulta por `actualizado_en > ultimo_sync`; se guarda un marcador por tabla.
4. **Conflictos:** *última escritura gana* por fila, con la marca de tiempo del servidor como árbitro. Los precios son append-only: nunca hay conflicto de precio.
5. **Borrado:** lógico (`borrado_en`), nunca físico, para que el borrado se propague a otros dispositivos.
6. **Dedup por EAN:** si subo un producto cuyo código de barras ya existe en el servidor, el backend devuelve el id existente y el dispositivo re-apunta sus precios a ese producto (transacción local).
7. **Agrupación por artículo:** los `articulo_id` se sincronizan como cualquier campo; si dos usuarios clasifican el mismo producto en artículos distintos, gana la escritura más reciente y el resto puede reasignarse desde la UI.

## Seguridad y acceso

- **RLS en todas las tablas:** cualquiera puede **leer** e **insertar** (ese es el fin colaborativo); **editar nombre/categoría** solo quien lo creó; **borrar** (lógico) solo quien lo creó. Precios: solo insert.
- **Auth anónimo de Supabase:** cada instalación obtiene un usuario estable sin datos personales (`signInAnonymously`); a futuro puede convertirse en cuenta real sin migrar datos.
- **Claves:** la clave anónima de Supabase va embebida en la app (está diseñada para eso; la protección real es la RLS).

## Durabilidad del backend gratuito

Supabase pausa proyectos gratuitos tras ~7 días sin actividad. Mitigaciones (Fase 2):

- Ping programado con GitHub Actions (cron gratuito) para mantenerlo activo, o
- reactivación manual desde el panel (1 minuto, sin costo).

En cualquier caso, R3 nunca se compromete: la app no depende de la nube.
