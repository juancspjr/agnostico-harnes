---
type: PDR
importance: H
version: 001
date: 2026-07-21
title: PDR.md — Product Requirements Document (requisitos del producto)
---

# PDR — Product Requirements Document

> **Documento de Requisitos del Producto (PDR / PRD)**.
> Define QUÉ se va a construir, PARA QUIÉN, y POR QUÉ.
> **NO** define CÓMO (eso es código) ni reglas de negocio específicas
> (eso es `PROJECT.md §4`).
>
> Esta es la **puerta de entrada** para cualquier agente o ingeniero
> nuevo en el proyecto. Léelo antes de tocar nada.

---

## §1 Resumen ejecutivo (elevator pitch)

> **Una sola oración**: ¿qué es este producto y para quién?

`<Una sola oración que cualquier persona no técnica pueda entender.>`

> **Una sola oración**: ¿qué problema concreto resuelve hoy?

`<El dolor que este producto elimina.>`

---

## §2 Contexto y oportunidad

### §2.1 Situación actual (sin este producto)

`<Describe cómo se hacen las cosas HOY sin este producto. Cuanto más
concreto mejor: nombre de herramientas, tiempo invertido, fricción,
errores típicos.>`

### §2.2 Por qué ahora

`<Por qué este proyecto es importante AHORA. Qué cambió en el entorno
que lo hace viable/necesario.>`

### §2.3 Tendencias del mercado / contexto

`<Si aplica, 1-2 párrafos sobre la dirección del mercado, regulación
reciente, cambios tecnológicos que motivan este producto.>`

---

## §3 Objetivos del producto

### §3.1 Objetivo principal

`<El objetivo #1 sin el cual el proyecto no vale la pena.>`

### §3.2 Objetivos secundarios

- **O-2**: `<objetivo secundario medible>`
- **O-3**: `<objetivo secundario medible>`
- **O-4**: `<objetivo secundario medible>`

### §3.3 Anti-objetivos (lo que NO vamos a hacer)

> Crítico para evitar scope creep.

- ❌ **AO-1**: `<lo que NO construiremos en v1>`
- ❌ **AO-2**: `<lo que NO construiremos en v1>`
- ❌ **AO-3**: `<lo que NO construiremos en v1>`

---

## §4 Usuarios y casos de uso

### §4.1 Personas

#### Persona primaria: `<nombre>`

| Campo | Descripción |
|---|---|
| **Rol** | `<quién es>` |
| **Contexto** | `<en qué situación usa el producto>` |
| **Objetivo** | `<qué quiere lograr>` |
| **Frustraciones** | `<qué le molesta hoy>` |
| **Criterio de éxito** | `<cómo sabe que el producto le sirvió>` |

#### Persona secundaria: `<nombre>`

`<repetir tabla>`

### §4.2 Top 5 casos de uso

| # | Caso de uso | Persona | Frecuencia | Criticidad |
|---|---|---|---|---|
| 1 | `<caso 1>` | `<persona>` | `<diaria / semanal / mensual>` | `<alta / media / baja>` |
| 2 | `<caso 2>` | `<persona>` | `<frecuencia>` | `<criticidad>` |
| 3 | `<caso 3>` | `<persona>` | `<frecuencia>` | `<criticidad>` |
| 4 | `<caso 4>` | `<persona>` | `<frecuencia>` | `<criticidad>` |
| 5 | `<caso 5>` | `<persona>` | `<frecuencia>` | `<criticidad>` |

---

## §5 Alcance (scope)

### §5.1 In-scope (lo que SÍ construiremos en v1)

#### Must-have (P0 — bloqueante)

- **M-1**: `<feature bloqueante, sin esto el producto no sirve>`
- **M-2**: `<feature bloqueante>`
- **M-3**: `<feature bloqueante>`

#### Should-have (P1 — importante)

- **S-1**: `<feature importante, se puede lanzar sin esto pero duele>`
- **S-2**: `<feature importante>`

#### Nice-to-have (P2 — deseable)

- **N-1**: `<feature deseable, se pospone si no hay tiempo>`
- **N-2**: `<feature deseable>`

### §5.2 Out-of-scope (lo que NO construiremos)

> Lista explícita para evitar scope creep.

- ❌ `<feature fuera de scope v1>`
- ❌ `<feature fuera de scope v1>`
- ❌ `<feature fuera de scope v1>`

### §5.3 Preguntas abiertas

> Las preguntas que aún no tienen respuesta. Se cierra cada una antes
> del sprint correspondiente.

- **Q-1**: `<pregunta abierta>` → owner: `<quién decide>`
- **Q-2**: `<pregunta abierta>` → owner: `<quién decide>`

---

## §6 Métricas de éxito

### §6.1 North Star Metric

> La única métrica que mejor captura el valor del producto.

**NSM**: `<métrica principal>` — `<definición precisa y cómo se mide>`

### §6.2 Métricas de adopción

| Métrica | Target Q1 | Target Q2 | Cómo medir |
|---|---|---|---|
| `<métrica>` | `<valor>` | `<valor>` | `<instrumento>` |
| `<métrica>` | `<valor>` | `<valor>` | `<instrumento>` |

### §6.3 Métricas de calidad

| Métrica | Target | Cómo medir |
|---|---|---|
| Latencia p50 | `<Xms>` | `<APM>` |
| Latencia p99 | `<Xms>` | `<APM>` |
| Uptime | `<X%>` | `<monitoring>` |
| Errores / día | `<N>` | `<error tracking>` |
| Cobertura tests | `≥80%` | `<coverage tool>` |

### §6.4 Métricas de negocio

| Métrica | Target Q1 | Target Q2 |
|---|---|---|
| `<métrica de negocio>` | `<valor>` | `<valor>` |
| `<métrica de negocio>` | `<valor>` | `<valor>` |

---

## §7 Requisitos no funcionales (NFRs)

### §7.1 Performance

- `<NFR-1>: el endpoint X debe responder en <Yms> con <Z usuarios concurrentes>`
- `<NFR-2>: la página Y debe cargar completamente en <W segundos> en 3G>`

### §7.2 Seguridad

- `<NFR-3>: todas las contraseñas hasheadas con bcrypt cost >=12>`
- `<NFR-4>: tokens JWT con expiración <=15min + refresh token con rotación>`
- `<NFR-5>: HTTPS obligatorio en producción>`
- `<NFR-6>: rate limiting en endpoints públicos (X req/min por IP)>`

### §7.3 Disponibilidad y resiliencia

- `<NFR-7>: uptime target >=X% mensual>`
- `<NFR-8>: backups automáticos cada <Y horas>>`

### §7.4 Escalabilidad

- `<NFR-9>: arquitectura preparada para escalar horizontalmente>`
- `<NFR-10>: DB con índices apropiados para queries críticas>`

### §7.5 Mantenibilidad

- `<NFR-11>: cobertura de tests >=80% en código nuevo>`
- `<NFR-12>: linting obligatorio en CI (golangci-lint / eslint + prettier / ...)>`
- `<NFR-13>: documentación actualizada en cada PR que cambie dominio>`

### §7.6 Accesibilidad (a11y)

- `<NFR-14>: cumplir WCAG 2.1 nivel AA en UI>`
- `<NFR-15>: navegación por teclado en todos los flujos críticos>`

### §7.7 Internacionalización (i18n)

- `<NFR-16>: preparado para multi-idioma desde v1>`
- `<NFR-17>: textos externos en archivos de traducción, NO hardcoded>`

### §7.8 Cumplimiento (compliance)

- `<NFR-18>: GDPR / CCPA: derecho al olvido, exportación de datos>`
- `<NFR-19>: logs de auditoría inmutables para acciones sensibles>`
- `<NFR-20>: retención de datos según regulación local>`

---

## §8 Restricciones y supuestos

### §8.1 Restricciones

- **R-1**: `<restricción técnica / presupuesto / tiempo / regulatory>`
- **R-2**: `<restricción>`
- **R-3**: `<restricción>`

### §8.2 Supuestos

> Si alguno de estos supuestos falla, el plan cambia.

- **S-1**: `<supuesto que asumimos como verdadero>`
- **S-2**: `<supuesto>`
- **S-3**: `<supuesto>`

### §8.3 Dependencias externas

> Servicios / personas / sistemas de los que dependemos.

- **D-1**: `<dependencia externa>`
- **D-2**: `<dependencia externa>`

---

## §9 Roadmap de alto nivel

> **NO es un sprint plan**. Es la secuencia de hitos del producto.

### Fase 1 — MVP (target: `<fecha>`)

- `<entregable 1>`
- `<entregable 2>`
- `<entregable 3>`
- **Definición de done**: `<criterio para considerar el MVP completo>`

### Fase 2 — `<nombre>` (target: `<fecha>`)

- `<entregable>`
- **Definición de done**: `<criterio>`

### Fase 3 — `<nombre>` (target: `<fecha>`)

- `<entregable>`
- **Definición de done**: `<criterio>`

> Detalle de sprints y loops en `iterations/PLAN-VIVO.md §7`.

---

## §10 Stakeholders

| Rol | Persona | Responsabilidad |
|---|---|---|
| **Product Owner** | `<nombre>` | Decisiones de scope y prioridad |
| **Tech Lead** | `<nombre>` | Decisiones de arquitectura |
| **Designer** | `<nombre>` | UX/UI |
| **QA Lead** | `<nombre>` | Calidad y testing |
| **Sponsor** | `<nombre>` | Viabilidad y funding |

---

## §11 Glosario del producto

| Término | Definición |
|---|---|
| `<término 1>` | `<definición>` |
| `<término 2>` | `<definición>` |
| `<término 3>` | `<definición>` |

---

## §12 Apéndice

### §12.1 Documentos relacionados

- `AGENTS.md` — Constitución del proyecto
- `PROJECT.md` — Spec del dominio (reglas de negocio, modelo de datos)
- `.jcode/PRINCIPLES.md` — Ley operativa del arnés
- `.jcode/iterations/PLAN-VIVO.md` — Estado actual del proyecto
- `<docs/<manual>.md>` — `<propósito>`

### §12.2 Historial de cambios

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 001 | 2026-07-21 | `<autor>` | Creación inicial |

---

## §13 Checklist de cierre del PDR

> Antes de pasar a implementación, el PDR debe cumplir:

- [ ] Resumen ejecutivo entendible en 30 segundos
- [ ] Objetivos medibles (no "ser el mejor")
- [ ] Personas definidas con frustraciones concretas
- [ ] Top 5 casos de uso con frecuencia y criticidad
- [ ] In-scope vs out-of-scope explícito
- [ ] Anti-objetivos declarados (lo que NO se hará)
- [ ] North Star Metric definida y medible
- [ ] NFRs con números (no "rápido", sino "<200ms p99")
- [ ] Restricciones y supuestos declarados
- [ ] Roadmap con fechas y definiciones de done
- [ ] Stakeholders identificados
- [ ] Preguntas abiertas con owner asignado

> Si alguna casilla queda vacía, el PDR NO está listo para
> implementación. Iterar antes de empezar a codear.