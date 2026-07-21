---
type: SPEC
importance: H
version: 100-clean.template
date: 2026-07-21
title: PROJECT.md — Spec del dominio (plantilla agnóstica)
---

# PROJECT.md — Spec del Dominio

> **Source of truth del dominio**. Define QUÉ hace el sistema y POR QUÉ.
> **NO** define CÓMO se implementa (eso es código) ni CÓMO trabajan los
> agentes (eso es `.jcode/`).
>
> **Esta es una PLANTILLA agnóstica**. Reemplaza cada `<placeholder>`
> con el contenido real del proyecto.

---

## §1 Visión del producto

### §1.1 Problema que resuelve

`<Describe en 2-3 párrafos el problema central que este sistema resuelve.>`

`<El "por qué existimos".>`

### §1.2 Problema operativo real (concreto)

`<Describe el dolor específico del día a día que motiva este proyecto.>`

`<Si no se resuelve, qué pasa? Qué costo tiene hoy?>`

### §1.3 Audiencia objetivo

- **Usuario primario**: `<quién usa el producto>`
- **Usuario secundario**: `<quién más lo usa>`
- **NO es para**: `<a quiénes NO está dirigido>`

### §1.4 Métricas de éxito

| Métrica | Baseline | Target | Cómo medir |
|---|---|---|---|
| `<Métrica 1>` | `<valor inicial>` | `<valor objetivo>` | `<instrumento>` |
| `<Métrica 2>` | `<valor inicial>` | `<valor objetivo>` | `<instrumento>` |
| `<Métrica 3>` | `<valor inicial>` | `<valor objetivo>` | `<instrumento>` |

---

## §2 Stack técnico (detallado)

> Resumen en `AGENTS.md §2`. Esta sección entra en detalle de cada
> decisión técnica.

### Backend

- **Lenguaje**: `<versión>`
- **Framework**: `<versión>`
- **Build/test/lint**: `<comandos>`
- **Puerto dev**: `<puerto>`

### Frontend

- **Lenguaje**: `<versión>`
- **Framework**: `<versión>`
- **UI lib**: `<versión>`
- **Estado**: `<Zustand / Redux / Pinia / ...>`
- **Build/test/lint**: `<comandos>`
- **Puerto dev**: `<puerto>`

### Base de datos

- **Motor**: `<versión>`
- **Conexión**: env `<nombre-var>`
- **Migraciones**: `<herramienta>`, carpeta `<path>`
- **Seed dev**: `<path>` (estructura + datos de ejemplo)

### Infra

- **Container**: `<docker-compose / k8s / ...>`
- **CI/CD**: `<GitHub Actions / ...>`
- **Deploy**: `<Railway / Vercel / self-hosted / ...>`
- **Secrets**: env vars + `<secret manager>`

---

## §3 Modelo de datos

### §3.1 Diagrama entidad-relación (texto)

```
<Entidad1> --<relación>--> <Entidad2>
<Entidad2> --<relación>--> <Entidad3>
```

### §3.2 Entidades y campos clave

#### Entidad: `<nombre>`

| Campo | Tipo | Constraints | Notas |
|---|---|---|---|
| `id` | UUID / INT | PK | Identificador único |
| `<campo>` | `<tipo>` | `<not null / unique / check>` | `<descripción>` |
| `<campo>` | `<tipo>` | `<not null / unique / check>` | `<descripción>` |
| `<campo>` | `<tipo>` | `<not null / unique / check>` | `<descripción>` |
| `created_at` | TIMESTAMP | not null, default now() | Auditoría |
| `updated_at` | TIMESTAMP | not null, default now() | Auditoría |

#### Entidad: `<nombre>`

`<repetir tabla>`

### §3.3 Tablas de auditoría / derivadas

- `<tabla auditoría>`: registra eventos con `actor_id`, `tipo_evento`,
  `payload`, `timestamp`.
- `<tabla derivados>`: snapshots calculados para optimizar lecturas.

---

## §4 Reglas de negocio (detallado)

> Resumen ejecutivo en `AGENTS.md §3`. Esta sección entra en detalle de
> cada regla: descripción completa, invariantes, excepciones.

### R-1: `<título de la regla>`

**Descripción**: `<descripción completa en 2-3 oraciones>`

**Invariantes**:
- `<invariante 1>`
- `<invariante 2>`

**Excepciones documentadas**:
- `<excepción 1>: solo si <condición>`

**Relacionadas**: R-NN, R-MM

---

### R-2: `<título>`

`<repetir estructura>`

---

> Mantener máximo 40 reglas activas. Si más, archivar en
> `docs/reglas-archivadas.md`.

---

## §5 Flujos del negocio (detallado)

> Resumen ejecutivo en `AGENTS.md §5`. Esta sección entra en detalle.

### F-01: `<nombre del flujo>`

| Campo | Valor |
|---|---|
| **Actores** | `<rol 1>, <rol 2>` |
| **Trigger** | `<qué inicia el flujo>` |
| **Pre-condiciones** | `<qué debe ser verdad para empezar>` |
| **Post-condiciones** | `<qué debe ser verdad al terminar>` |
| **Estados por los que pasa** | `<estado1> → <estado2> → <estado3>` |
| **Errores recuperables** | `<qué hacer si falla X>` |

**Pasos**:

1. `<paso 1>: <actor> hace <acción> → efecto`
2. `<paso 2>: <actor> hace <acción> → efecto`
3. `<paso 3>: <actor> hace <acción> → efecto`
...

---

### F-02: `<nombre del flujo>`

`<repetir estructura>`

---

## §6 Servicios externos

| Servicio | Propósito | Env vars | Status |
|---|---|---|---|
| `<servicio>` | `<para qué>` | `<VAR1>, <VAR2>` | 🟢 integrado / 🟡 parcial / ⚪ no integrado |
| `<servicio>` | `<para qué>` | `<VAR1>, <VAR2>` | 🟢 integrado / 🟡 parcial / ⚪ no integrado |

> Para credenciales de dev, ver `AGENTS.md §6`. Credenciales de prod en
> secret manager.

---

## §7 Glosario del dominio

| Término | Definición |
|---|---|
| `<término 1>` | `<definición clara>` |
| `<término 2>` | `<definición clara>` |
| `<término 3>` | `<definición clara>` |

---

## §8 Decisiones arquitectónicas (ADR log)

> Decisiones técnicas importantes con justificación. ADR = Architecture
> Decision Record. Append-only.

### ADR-001 — Stack: `<elección>`

- **Fecha**: `<YYYY-MM-DD>`
- **Status**: `aceptada` / `deprecada` / `reemplazada`
- **Contexto**: `<por qué hay que decidir>`
- **Decisión**: `<qué se eligió>`
- **Consecuencias**:
  - Positivas: `<...>`
  - Negativas: `<...>`
- **Alternativas consideradas**: `<...>`

---

## §9 Riesgos y mitigaciones

### RIESGO-001 — `<título del riesgo>`

- **Descripción**: `<...>`
- **Probabilidad**: `alta` / `media` / `baja`
- **Impacto**: `alto` / `medio` / `bajo`
- **Mitigación**: `<cómo se mitiga>`
- **Plan de contingencia**: `<qué hacer si pasa>`

---

## Versión y cambios

- **v100-clean.template** (2026-07-21): Plantilla agnóstica del spec
  del dominio. Lista para cualquier stack. Reemplaza placeholders con
  valores reales antes del primer commit.