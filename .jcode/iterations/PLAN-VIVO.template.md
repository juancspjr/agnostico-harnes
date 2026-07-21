---
type: PLAN-VIVO
importance: H
version: 001-template
date: 2026-07-21
title: PLAN-VIVO.md — Plano mayor del proyecto (plantilla agnóstica)
---

# PLAN-VIVO.md — Plano mayor del proyecto

> **Único archivo vivo**. Es la consola operacional del proyecto. Cada
> agente lo lee al iniciar sesión. Debe ser siempre claro, actualizado,
> y accionable.
>
> **Esta es una PLANTILLA agnóstica**. Llenar cada sección con datos
> reales del proyecto antes del primer commit.
>
> **Reglas de mantenimiento**:
> 1. **Tamaño**: máximo 800 líneas. Si crece más, archivar secciones
>    viejas a `iterations/archive/PLAN-VIVO-<fecha>.md`.
> 2. **Append-only en cronología (§5) y bugs (§6)**: nunca borrar,
>    solo añadir. Podar entradas viejas cuando la sección supere 20.
> 3. **Estado actual solo**: §1, §2, §3, §4 reflejan el ESTADO ACTUAL.
>    Si cambian, se reescriben (no se append-an).
> 4. **Mantener secciones vacías** con "(ninguno)" — el agente
>    necesita ver la estructura, no adivinarla.

---

## §1 Reglas del proyecto (resumen ejecutivo)

> Copia/resume las reglas críticas de `PROJECT.md §4` y `AGENTS.md §3`.
> Máximo 60 líneas, top 15 reglas más críticas.

- **R-1**: `<regla 1>`
- **R-2**: `<regla 2>`
- **R-3**: `<regla 3>`
- **R-4**: `<regla 4>`
- **R-5**: `<regla 5>`
- **R-NN**: `<regla NN>`

> Para detalle técnico de cada regla, ver `PROJECT.md §4`.

---

## §2 Implementación actual (matriz de componentes)

> Matriz de componentes implementados y su estado. Máximo 100 líneas.
> Top 20-25 componentes críticos.

| Componente | Archivo(s) | Estado | Cobertura tests | Última iteración |
|---|---|---|---|---|
| `<componente 1>` | `<path>` | ✅ done | `<X>%` | `<L-XXX-NNN>` |
| `<componente 2>` | `<path>` | 🟡 partial | `<X>%` | `<L-XXX-NNN>` |
| `<componente 3>` | `<path>` | ❌ missing | `0%` | — |

**Leyenda**: ✅ done = completo y testeado | 🟡 partial = funciona pero
le faltan tests/features | ❌ missing = no implementado | 🚫 broken = roto

---

## §3 Gaps (lo que falta completar)

> Diff entre §1 (reglas) y §2 (implementación). Top 15 prioridades.
> Máximo 60 líneas.

### GAP-001 — `<título del gap>`

- **Regla vinculada**: R-NN
- **Descripción**: `<qué falta>`
- **Impacto**: `<crítico / medio / bajo>`
- **Estimación**: `<X horas>`
- **Prioridad**: `<alta / media / baja>`
- **Loop sugerido**: `L-XXX-NNN`

---

## §4 Solicitudes nuevas del cliente

> Cambios en reglas de negocio durante el trabajo. Máximo 40 líneas.
> Cada solicitud tiene ID estable (SOL-NNN) para referencia cruzada.

### SOL-001 — `<título>`

- **Fecha**: `<YYYY-MM-DD>`
- **Cliente**: `<quién>`
- **Descripción**: `<qué quiere>`
- **Impacto en reglas**: `<ninguno / nuevas R-NN a R-MM>`
- **Estado**: `<pendiente / en progreso / completada>`
- **Loop que lo cierra**: `<L-XXX-NNN>`

---

## §5 Cronología de cambios (append-only)

> Histórico de cambios importantes. Append-only: nunca borrar entradas,
> solo añadir al final. **Purar cuando supere 20 entries**.

- **YYYY-MM-DDTHH:MMZ** — `<descripción del cambio>` (commit `<hash>`)
- **YYYY-MM-DDTHH:MMZ** — `<descripción del cambio>` (loop `L-XXX-NNN`)

---

## §6 Bugs detectados + soluciones

> Registro de bugs y cómo se resolvieron. R-3STRIKE-MVP strike counter.
> Máximo 80 líneas, bugs **abiertos** primero, cerrados después.

### Bugs abiertos

#### BUG-001 — `<título del bug>`

- **Detectado**: `<YYYY-MM-DD>`
- **Síntoma**: `<qué pasa>`
- **Causa raíz**: `<por qué pasa>`
- **Solución propuesta**: `<cómo arreglar>`
- **Strikes**: `<N>/3`
- **Loop que lo cierra**: `<L-XXX-NNN>`
- **Estado**: `<investigando / en progreso / bloqueado>`

### Bugs cerrados (últimos 15)

#### BUG-000 — `<título>`

- **Detectado**: `<YYYY-MM-DD>`
- **Resuelto**: `<YYYY-MM-DD>`
- **Causa raíz**: `<...>`
- **Solución aplicada**: `<...>` (commit `<hash>`)
- **Lección**: `<...>`

---

## §7 Plan MVP (corto plazo, 1-2 sprints)

> Próximos 2 sprints planeados. Máximo 50 líneas.

### Sprint actual: Sprint `<NN>` — `<título>`

- **Goal**: `<objetivo medible>`
- **Loops planeados**: `<L-XXX-NNN>, <L-XXX-NNN>`
- **Entregables**:
  - `<entregable 1>`
  - `<entregable 2>`
- **Definición de done**:
  - `<criterio>`
  - `<criterio>`

### Próximo sprint: Sprint `<NN+1>` — `<título>`

- **Goal**: `<objetivo>`
- **Loops planeados**: `<...>`
- **Dependencias**: `<Sprint NN completado>`

---

## §8 Plan de la sesión actual

> Loop actual + handoff. Máximo 40 líneas. **Se actualiza cada sesión.**

- **Sesión ID**: `<session_id>`
- **Fecha inicio**: `<YYYY-MM-DDTHH:MMZ>`
- **Loop actual**: `<L-XXX-NNN>` — `<título>`
- **Goal de la sesión**: `<objetivo>`
- **Tareas concretas**:
  1. `<tarea 1>`
  2. `<tarea 2>`
- **Handoff (al cerrar sesión)**:
  - **Estado actual**: `<qué quedó hecho>`
  - **Pendiente**: `<qué falta>`
  - **Próximo loop**: `<L-XXX-NNN>`
  - **Notas para próximo agente**: `<contexto crítico>`

---

## §9 Decisiones arquitectónicas (ADR log)

> Decisiones técnicas importantes con justificación. ADR = Architecture
> Decision Record. Append-only. Máximo 40 líneas, top 8 decisiones
> activas.

### ADR-001 — `<título de la decisión>`

- **Fecha**: `<YYYY-MM-DD>`
- **Status**: `<aceptada / deprecada / reemplazada>`
- **Contexto**: `<por qué hay que decidir>`
- **Decisión**: `<qué se eligió>`
- **Consecuencias**:
  - Positivas: `<...>`
  - Negativas: `<...>`
- **Alternativas consideradas**: `<...>`

---

## §10 Dependencias y servicios externos

> Servicios de los que depende el proyecto. Útil para debug de fallos.

| Servicio | Propósito | Status page | Última revisión |
|---|---|---|---|

---

## §11 Ambientes activos

> Estado actual de cada ambiente.

| Ambiente | URL | Versión deployada | Último deploy | Estado |
|---|---|---|---|---|
| dev | `<url local>` | `<local>` | — | 🟢 corriendo |
| staging | `<url>` | — | — | ⚪ no configurado |
| prod | `<url>` | — | — | ⚪ no configurado |

> Estados: 🟢 healthy | 🟡 degraded | 🔴 down | ⚪ unknown

---

## §12 Métricas actuales (snapshot)

> Snapshot de métricas clave del proyecto. **NO es monitoreo en vivo** —
> es referencia para el agente al planear trabajo. Actualizar semanal.

| Métrica | Valor actual | Target | Trend |
|---|---|---|---|
| Cobertura tests | `<X%>` | `<target>` | 🟢 / 🟡 / 🔴 |
| Latencia p50 API | `<Xms>` | `<target>` | 🟢 / 🟡 / 🔴 |
| Latencia p99 API | `<Xms>` | `<target>` | 🟢 / 🟡 / 🔴 |
| Uptime (30 días) | `<X%>` | `<target>` | 🟢 / 🟡 / 🔴 |
| Errores / día | `<X>` | `<target>` | 🟢 / 🟡 / 🔴 |

---

## §13 Lecciones aprendidas

> Cosas que el equipo aprendió y que conviene tener a mano. Append-only.
> Máximo 40 líneas.

- **`<YYYY-MM-DD>`** — `<lección concreta>`
- **`<YYYY-MM-DD>`** — `<lección concreta>`

---

## §14 Registro de bloqueos (R-FRAGMENT-ATOMIC)

> Solo si hubo bloqueos de guardrail del LLM. Ver
> `.jcode/INCIDENT-PROTOCOLS.md §A`. Append-only. Si vacío, escribir
> "(ninguno)".

> Si no hay bloqueos: "(ninguno)"

---

## §15 Riesgos y bloqueos conocidos

> Riesgos del proyecto que conviene tener visibles. Máximo 40 líneas.

### RIESGO-001 — `<título>`

- **Descripción**: `<...>`
- **Probabilidad**: `<alta / media / baja>`
- **Impacto**: `<alto / medio / bajo>`
- **Mitigación**: `<cómo se mitiga>`
- **Plan de contingencia**: `<qué hacer si pasa>`

---

## §16 Backlog rápido (ideas sin prioridad)

> Ideas que surgieron pero no tienen prioridad todavía. Sin formato
> estricto. Se podan mensualmente.

- `<idea 1>`
- `<idea 2>`

> Las que se prioricen se mueven a §7 (plan MVP) o §3 (gaps).

---

## Mantenimiento de este archivo

### Reglas de poda (cuándo archivar)

1. **Si archivo > 800 líneas**: archivar §5, §6 cerrados, §13, §14
   resueltos a `iterations/archive/PLAN-VIVO-<fecha>.md`.
2. **§5 cronología > 20 entries**: podar las más viejas.
3. **§6 bugs cerrados > 15**: podar los más viejos.
4. **§4 solicitudes completadas > 30 días**: archivar.
5. **§9 ADRs deprecadas > 5**: archivar.

### Quién mantiene cada sección

| Sección | Mantenida por | Cuándo |
|---|---|---|
| §1, §2, §3 | agente coordinator | cada loop cerrado |
| §4 | agente coordinator | cuando cliente pide algo |
| §5 | hooks + agente | cada cambio |
| §6 | agente coordinator | cuando se detecta/resuelve bug |
| §7 | agente + cliente | cada sprint planning |
| §8 | agente activo | cada inicio/cierre de sesión |
| §9 | agente coordinator | cuando se toma decisión técnica |
| §10, §11 | ops / agente | revisión semanal |
| §12 | agente coordinator | revisión semanal |
| §13 | agente coordinator | cuando se aprende algo |
| §14 | agente | cuando hay bloqueo |
| §15 | agente coordinator | cuando se identifica riesgo |
| §16 | cualquiera | libremente |

### Reglas de formato

1. **IDs estables**: una vez asignado un ID (GAP-001, SOL-001, BUG-001,
   ADR-001, RIESGO-001), **NUNCA** reasignarlo aunque se archive.
2. **Timestamps**: ISO 8601 UTC (ej `2026-07-21T10:00Z`).
3. **Cross-references**: usar formato `R-NN`, `F-NN`, `GAP-NNN`,
   `SOL-NNN`, `BUG-NNN`, `ADR-NNN`, `L-XXX-NNN`, `RIESGO-NNN`.
4. **NO duplicar**: si una regla ya está en `PROJECT.md §4`, aquí solo
   un resumen de 1 línea + referencia.

---

## Versión

- **v001-template** (2026-07-21): Plantilla agnóstica del plano mayor.
  Llenar con datos reales del proyecto antes del primer commit.