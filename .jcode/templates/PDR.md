# PDR.md — Plantilla para Product Requirements Document

> Copiar a `PDR.md` en la raíz del proyecto (junto a `AGENTS.md` y
> `PROJECT.md`) y llenar cada sección. El PDR es la **puerta de entrada**
> del proyecto: cualquier agente o ingeniero nuevo debe leerlo antes
> de tocar nada.

---

```markdown
---
type: PDR
importance: H
version: 001
date: <YYYY-MM-DD>
title: PDR.md — Product Requirements Document
---

# PDR — Product Requirements Document

> **Documento de Requisitos del Producto**.
> Define QUÉ se va a construir, PARA QUIÉN, y POR QUÉ.
> **NO** define CÓMO (eso es código) ni reglas de negocio específicas
> (eso es `PROJECT.md §4`).

---

## §1 Resumen ejecutivo (elevator pitch)

> **Una sola oración**: ¿qué es este producto y para quién?

<Una sola oración que cualquier persona no técnica pueda entender.>

> **Una sola oración**: ¿qué problema concreto resuelve hoy?

<El dolor que este producto elimina.>

---

## §2 Contexto y oportunidad

### §2.1 Situación actual (sin este producto)

<Describe cómo se hacen las cosas HOY sin este producto.>

### §2.2 Por qué ahora

<Por qué este proyecto es importante AHORA.>

### §2.3 Tendencias del mercado / contexto

<Si aplica.>

---

## §3 Objetivos del producto

### §3.1 Objetivo principal

<El objetivo #1 sin el cual el proyecto no vale la pena.>

### §3.2 Objetivos secundarios

- **O-2**: <objetivo secundario medible>
- **O-3**: <objetivo secundario medible>

### §3.3 Anti-objetivos (lo que NO vamos a hacer)

> Crítico para evitar scope creep.

- ❌ **AO-1**: <lo que NO construiremos en v1>
- ❌ **AO-2**: <lo que NO construiremos en v1>

---

## §4 Usuarios y casos de uso

### §4.1 Personas

#### Persona primaria: <nombre>

| Campo | Descripción |
|---|---|
| **Rol** | <quién es> |
| **Contexto** | <en qué situación usa el producto> |
| **Objetivo** | <qué quiere lograr> |
| **Frustraciones** | <qué le molesta hoy> |
| **Criterio de éxito** | <cómo sabe que el producto le sirvió> |

### §4.2 Top 5 casos de uso

| # | Caso de uso | Persona | Frecuencia | Criticidad |
|---|---|---|---|---|
| 1 | <caso 1> | <persona> | <frecuencia> | <criticidad> |
| 2 | <caso 2> | <persona> | <frecuencia> | <criticidad> |
| 3 | <caso 3> | <persona> | <frecuencia> | <criticidad> |
| 4 | <caso 4> | <persona> | <frecuencia> | <criticidad> |
| 5 | <caso 5> | <persona> | <frecuencia> | <criticidad> |

---

## §5 Alcance (scope)

### §5.1 In-scope

#### Must-have (P0 — bloqueante)

- **M-1**: <feature bloqueante>
- **M-2**: <feature bloqueante>

#### Should-have (P1 — importante)

- **S-1**: <feature importante>
- **S-2**: <feature importante>

#### Nice-to-have (P2 — deseable)

- **N-1**: <feature deseable>

### §5.2 Out-of-scope

- ❌ <feature fuera de scope v1>

### §5.3 Preguntas abiertas

- **Q-1**: <pregunta abierta> → owner: <quién decide>

---

## §6 Métricas de éxito

### §6.1 North Star Metric

**NSM**: <métrica principal>

### §6.2 Métricas de adopción

| Métrica | Target Q1 | Target Q2 | Cómo medir |
|---|---|---|---|

### §6.3 Métricas de calidad

| Métrica | Target | Cómo medir |
|---|---|---|
| Latencia p50 | <Xms> | <APM> |
| Latencia p99 | <Xms> | <APM> |
| Uptime | <X%> | <monitoring> |
| Errores / día | <N> | <error tracking> |
| Cobertura tests | ≥80% | <coverage tool> |

---

## §7 Requisitos no funcionales (NFRs)

### §7.1 Performance

- <NFR-1>: <descripción + número>

### §7.2 Seguridad

- <NFR-2>: <descripción>

### §7.3 Disponibilidad y resiliencia

- <NFR-3>: <descripción>

### §7.4 Escalabilidad

- <NFR-4>: <descripción>

### §7.5 Mantenibilidad

- <NFR-5>: cobertura de tests ≥80%

### §7.6 Accesibilidad (a11y)

- <NFR-6>: WCAG 2.1 nivel AA

### §7.7 Internacionalización (i18n)

- <NFR-7>: preparado para multi-idioma desde v1

### §7.8 Cumplimiento (compliance)

- <NFR-8>: GDPR / CCPA / LGPD / etc.

---

## §8 Restricciones y supuestos

### §8.1 Restricciones

- **R-1**: <restricción>

### §8.2 Supuestos

- **S-1**: <supuesto>

### §8.3 Dependencias externas

- **D-1**: <dependencia>

---

## §9 Roadmap de alto nivel

### Fase 1 — MVP (target: <fecha>)

- <entregable>
- **Definición de done**: <criterio>

### Fase 2 — <nombre> (target: <fecha>)

- <entregable>

---

## §10 Stakeholders

| Rol | Persona | Responsabilidad |
|---|---|---|
| **Product Owner** | <nombre> | Decisiones de scope y prioridad |
| **Tech Lead** | <nombre> | Decisiones de arquitectura |
| **Designer** | <nombre> | UX/UI |
| **Sponsor** | <nombre> | Viabilidad y funding |

---

## §11 Glosario del producto

| Término | Definición |
|---|---|

---

## §12 Apéndice

### §12.1 Documentos relacionados

- `AGENTS.md` — Constitución del proyecto
- `PROJECT.md` — Spec del dominio (reglas de negocio, modelo de datos)
- `.jcode/PRINCIPLES.md` — Ley operativa del arnés
- `.jcode/iterations/PLAN-VIVO.md` — Estado actual del proyecto

### §12.2 Historial de cambios

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 001 | <YYYY-MM-DD> | <autor> | Creación inicial |

---

## §13 Checklist de cierre del PDR

- [ ] Resumen ejecutivo entendible en 30 segundos
- [ ] Objetivos medibles (no "ser el mejor")
- [ ] Personas definidas con frustraciones concretas
- [ ] Top 5 casos de uso con frecuencia y criticidad
- [ ] In-scope vs out-of-scope explícito
- [ ] Anti-objetivos declarados
- [ ] North Star Metric definida y medible
- [ ] NFRs con números
- [ ] Restricciones y supuestos declarados
- [ ] Roadmap con fechas y definiciones de done
- [ ] Stakeholders identificados
- [ ] Preguntas abiertas con owner asignado
```