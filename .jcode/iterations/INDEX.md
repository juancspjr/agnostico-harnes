---
type: STATE
importance: C
version: 001-template
date: 2026-07-21
title: Índice maestro del arnés + iteraciones vivas (plantilla)
---

# Índice Maestro — `.jcode/iterations/INDEX.md`

> **Entry-point post-AGENTS+PROJECT**. Cualquier agente nuevo debe leer
> este archivo tras `AGENTS.md` y `PROJECT.md`. Aquí se listan todos
> los documentos canónicos del arnés y de las iteraciones del proyecto.
>
> **Esta es una PLANTILLA**. Llenar con las versiones reales de cada
> documento al iniciar el proyecto. Actualizar cuando cambien versiones.

---

## 1. Docs raíz del proyecto (siempre leer primero)

| Doc | Versión | Importancia | Propósito |
|-----|---------|-------------|-----------|
| `AGENTS.md` | `<v>` | **H** | Constitución del proyecto |
| `PROJECT.md` | `<v>` | **H** | Spec del dominio |
| `PDR.md` | `<v>` | **H** | Requisitos del producto |
| `README.md` | — | H | Onboarding rápido del proyecto |

---

## 2. Docs raíz del arnés portátil (en `.jcode/`)

| Doc | Versión | Importancia | Propósito |
|-----|---------|-------------|-----------|
| `.jcode/README.md` | `<v>` | H | Mapa del arnés `.jcode/` |
| `.jcode/PRINCIPLES.md` | `<v>` | **H** | Ley operativa del arnés |
| `.jcode/AGENT-PROTOCOL.md` | `<v>` | **H** | Checklist por turno (11 items) |
| `.jcode/LOOPS.md` | `<v>` | H | Catálogo oficial de loops |
| `.jcode/STATE-REGISTERS.md` | `<v>` | **H** | Mapa de campos de estado (Vista Z) |
| `.jcode/BEHAVIOR-INDEX.md` | `<v>` | M | Mapa de comportamiento → código (Vista L1) |
| `.jcode/INTERPRETACION.md` | `<v>` | M | Capa de decisión pre-código |
| `.jcode/INCIDENT-PROTOCOLS.md` | `<v>` | M | Protocolos raros (bajo demanda) |
| `.jcode/shadcn-ui-guide.md` | `<v>` | N | Patrones UI/frontend (si aplica) |

---

## 3. Hooks wirados (activados por jcode runtime)

| Hook | Disparador | Función |
|------|-----------|---------|
| `.jcode/hooks/sessionstart.sh` | Apertura de sesión | State init + integrity check + banner |
| `.jcode/hooks/turn_start.sh` | Inicio de cada turno | Reminder + checklist |
| `.jcode/hooks/posttool.sh` | Después de cada tool call | Log + tracking + SRSI auto-judge |
| `.jcode/hooks/turnend.sh` | Cierre de cada turno | Score + breakdown + persistencia compliance |

---

## 4. Skills del arnés

| Skill | Propósito |
|-------|-----------|
| `.jcode/skills/orient/` | Triage y auto-orientación del agente |
| `.jcode/skills/arquitecto-proyecto/` | Diseño de arquitectura, modelos, APIs |
| `.jcode/skills/worker-ejecutor/` | Constructor dentro de un loop acotado |
| `.jcode/skills/reviewer-calidad/` | Gatekeeper de calidad |
| `.jcode/skills/guardrails/` | Auditor de reglas del arnés |
| `.jcode/skills/cdp-browser-mcp/` | Browser automation via Chrome DevTools Protocol |
| `.jcode/skills/playwright-cli/` | Terminal browser automation |
| `.jcode/skills/context-caching/` | Cache de snapshots y fetches entre turnos |

---

## 5. Librerías del arnés (en `.jcode/lib/`)

| Script | Función |
|--------|---------|
| `harness.sh` | Comandos del arnés (`init`, `status`, `check`, `focus`, `score`) |
| `state_manager.sh` | Estado central: compliance score, reads, strikes |
| `jcode-hook-dispatcher.sh` | Dispatcher único de hooks |
| `git_age.sh` | Helper de auditoría post-commit |
| `clean-contamination.sh` | Limpieza de contaminación del arnés |
| `contamination_patterns.txt` | Patrones prohibidos en el arnés |

---

## 6. Subcarpetas canónicas de iteraciones

| Carpeta | Propósito |
|---------|-----------|
| `.jcode/iterations/STATE/` | Snapshots de estado |
| `.jcode/iterations/ARCH/` | Arquitectura y diseño detallado |
| `.jcode/iterations/REM/` | Remediaciones y hotfixes |
| `.jcode/iterations/REV/` | Revisiones y auditorías |
| `.jcode/iterations/PLAN/` | Planes y roadmaps |
| `.jcode/iterations/OP/` | Procedimientos operacionales |
| `.jcode/iterations/archive/` | Histórico comprimido (consultar con `grep`) |

---

## 7. Iteraciones VIVAS (no en archive)

> Documentos actualmente activos del proyecto.

| Doc | Versión | Tipo | Propósito |
|-----|---------|------|-----------|
| `.jcode/iterations/PLAN-VIVO.md` | `<v>` | PLAN | Único archivo vivo — sprint activo + backlog + handoff |

---

## 8. Templates

| Doc | Propósito |
|-----|-----------|
| `.jcode/templates/OP.md` | Plantilla para procedimientos operacionales |
| `.jcode/templates/STATE.md` | Plantilla para snapshots de estado |
| `.jcode/templates/PDR.md` | Plantilla para PDR (Product Requirements Document) |

---

## 9. Compliance (snapshot)

> Valores actuales en `.jcode/state/compliance.json`.

```
session_id:          <session_id>
turn:                <N>
coordinator_active:  <true/false>
harness_integrity:   intact
aa1_violations:      <N>
r_aa_1_strikes:      <N>
score:               <N>/100
```

---

## 10. Cómo regenerar este índice

```bash
# Si volviera a degradarse, regenerar manualmente desde esta plantilla.
# Mantener solo las entradas que reflejen el estado real.
```

---

## Versión

- **v001-template** (2026-07-21): Plantilla agnóstica del índice
  maestro. Llenar con las versiones reales de cada documento.