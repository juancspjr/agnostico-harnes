---
type: RULE
importance: H
version: 100-clean
date: 2026-07-16
title: Ley de Ejecución LLM — Arnés Agnóstico (6 principios + PARTE II)
---

# PRINCIPLES.md — Ley operativa del arnés

> **Canónico**: este archivo es la **ley filosófica** del arnés. Define CÓMO
> debe razonar el agente. No define QUÉ es el proyecto (eso va en `AGENTS.md`).
>
> **Agnóstico**: cero referencias a dominio. Si encuentras una, es un bug.

---

## PARTE I — 6 principios LLM

### §1 R-3STRIKE-MVP — Tres strikes, cambiar método

Si un mismo fallo se repite 3 veces con el mismo método, **el método está mal**.
Cambiar de enfoque. No insistir.

- Strike 1: ajustar `state_manager.sh::state_record_strike`
- Strike 2: ajustar + nota en `PLAN-VIVO §6`
- Strike 3: cambiar método + ajustar `r_3strike_mvp_activations`

### §2 R-DOS-PLANOS — Two-plane state

El plano mayor (`PLAN-VIVO.md`) **no se sobrescribe**: se append-ea. Pero
cuando crece más de 350 líneas, se archivan las secciones viejas a
`iterations/archive/PLAN-VIVO-<fecha>.md`. La versión viva siempre cabe en
una ventana de contexto.

El plano menor (plan de sesión) puede mutar libremente. Antes de cerrar
sesión, flotar los cambios al plano mayor.

### §3 SRSI — Sparse Read/Search It

Antes de cualquier fix, ejecutar `grep`/`rg` sobre el patrón del cambio.
Confirmar matches antes y después. Esto valida que el fix realmente tocó
el código correcto.

Bumpear `srsi_done_this_turn=true` en `compliance.json` cuando se haga.

### §4 DDLP — Diff-Driven Loop Planning

Al inicio de cada sprint, leer `PLAN-VIVO §3` (gaps) y `§4` (solicitudes
cliente). El loop debe cerrar al menos un gap o solicitud. Bumpear
`ddlp_done=true` en `compliance.json`.

### §5 TPSP — Two-Plane State Planning

Cuando el cliente pide algo nuevo en medio de un sprint:
1. Anotar en `PLAN-VIVO §4` (solicitudes nuevas)
2. Modificar plan de sesión actual
3. Al cerrar sesión, consolidar en `PLAN-VIVO §5` (cronología)

### §6 R-NO-FAKE-SWARM — No simular sub-agentes

**Prohibido** crear "fake swarm" con scripts bash que llamen `jcode debug
--socket ... create_session` manualmente. Esto rompe el tracking nativo de
jcode y confunde al usuario (no ve los agentes en `Ctrl+O`).

**Forma correcta**:
- En TUI: `Ctrl+N` para spawn, `Ctrl+O` para listar
- En headless: declarar loop con `swarm_spawn_mode = "auto"` en `config.toml`

Si el runtime no soporta swarm (limitación del LLM host), declarar la
limitación explícitamente en `PLAN-VIVO §8` y trabajar en single-agent.

---

## PARTE II — Ley operativa del arnés

### Task classification

| `task_class` | Cuándo | `budget` típico |
|---|---|---|
| `MICROFIX` | Bug puntual, 1 archivo | 2 iter |
| `SLICE` | Feature vertical (1 endpoint + UI) | 5 iter |
| `REMEDIATION` | Refactor post-3-strikes | 8 iter |
| `PHASE-CLOSE` | Cierre de fase | 3 iter |
| `AUDIT` | Solo lectura, sin cambios | 1 iter |

### Stop conditions (cualquiera dispara)

1. Éxito verificado por `fixed_check`
2. No-op limpio (no hay cambios que hacer)
3. Bloqueo reproducible (dependencia externa, falta info)
4. Aprobación requerida del usuario
5. Presupuesto agotado
6. 2 iteraciones consecutivas sin progreso medible

### Benchmark types

`test` / `smoke` / `curl` / `grep` / `sql` / `review-score` /
`guardrail-audit` / `build`

Cada loop declara `benchmark_type` y `fixed_check` (comando reproducible).
El loop NO se cierra hasta que `fixed_check` pasa.

### Loop format

```markdown
- loop_id: L-SLICE-042
- task_class: SLICE
- goal: "Endpoint POST /api/<recurso> crea entidad y dispara evento"
- scope: backend/handlers/<recurso>.go, backend/events/dispatch.go
- out_of_scope: frontend, db/migrations
- fixed_check: "curl -s localhost:8080/api/<recurso> -d '...' | jq .id"
- benchmark_type: curl
- budget: 5
- progress_metric: "endpoint responde 200 con body válido"
- stop_conditions: [éxito, no-op, bloqueo, aprobación, budget, 2-no-progreso]
- approval_boundary: "cualquier cambio en schema requiere aprobación"
- handoff_artifact: "PLAN-VIVO §8 actualizado + commit hash"
```

### Sincronización obligatoria del arnés

Si cambias una regla portable del arnés, debes sincronizar:

- `PRINCIPLES.md` (este archivo)
- `AGENT-PROTOCOL.md` (checklist)
- `LOOPS.md` (catálogo)
- `config.toml` (policy ejecutable)
- `README.md` (mapa)
- Skills afectadas

**Prohibido** usar `sync_harness.sh` (eliminado). Usar git submodule o
template repo para compartir el arnés entre proyectos.

### Glosario (definiciones formales)

| Término | Significado |
|---|---|
| **SRSI** | Sparse Read/Search It — buscar con grep/rg antes de fix |
| **DDLP** | Diff-Driven Loop Planning — planear desde gaps |
| **TPSP** | Two-Plane State Planning — plano mayor + plano menor |
| **HPVG** | High-Precision Verification Gate — `fixed_check` reproducible |
| **R-AA-1** | Anti-autoengaño: no declarar fix sin verificar |
| **R-AA-2** | Anti-bloqueo-silencioso: registrar bloqueos de guardrail en §14 |
| **R-AA-3** | Anti-cambio-proveedor: NO cambiar LLM por bloqueo de guardrail (fragmentar) |

R-AA-2 y R-AA-3 viven en `INCIDENT-PROTOCOLS.md` (cargo bajo demanda).

---

## Versión

- **v100-clean**: refactor. Eliminados ejemplos de proyecto específico. Eliminadas referencias a proveedores LLM concretos. Eliminado §7 R-FRAGMENT-ATOMIC y §8 R-PREFLIGHT-SENIOR (movidos a INCIDENT-PROTOCOLS.md). Eliminado bug de dos §7. Añadido glosario formal.
