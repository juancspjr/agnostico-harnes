---
type: RULE
version: 100-clean
date: 2026-07-16
title: Catálogo oficial de loops
---

# LOOPS.md — Catálogo oficial de loops

> **Canónico**: cada unidad de trabajo es un **loop**. Acotado, medible,
> terminable. Sin loops, no hay closure.

---

## Formato canónico

```markdown
- loop_id: L-{TYPE}-{NNN}             # ej L-SLICE-042
- task_class: MICROFIX|SLICE|REMEDIATION|PHASE-CLOSE|AUDIT
- goal: "<descripción concrete, 1 frase>"
- scope: [<archivos/dirs afectados>]
- out_of_scope: [<archivos/dirs no tocados>]
- fixed_check: "tests/integration/test_<feature>.sh"
  # El fixed_check DEBE ser ruta a script versionado en `tests/integration/`,
  # `tests/validation/` o `tests/audit/`. NO one-liner improvisado.
  # Si el script no existe, el loop NO puede cerrar (orient F12 aborta).
- benchmark_type: test|smoke|curl|grep|sql|review-score|guardrail-audit|build
- hf_gate: required                    # Hidden Failure Gate (FAILURE-PATTERNS.md)
- budget: <máx iteraciones>
- progress_metric: "<cómo medir progreso entre iteraciones>"
- stop_conditions: [éxito, no-op, bloqueo, aprobación, budget, 2-no-progreso]
- approval_boundary: "<qué requiere aprobación humana>"
- handoff_artifact: "<qué deja el loop al cerrar>"
```

---

## Tipos oficiales (paridad con PRINCIPLES PARTE II)

| `task_class` | Cuándo | `budget` | `fixed_check` típico |
|---|---|---|---|
| `MICROFIX` | Bug puntual, 1 archivo | 2 iter | `go test ./pkg/...` o `npm test` |
| `SLICE` | Feature vertical completa | 5 iter | `curl ... \| jq .id` |
| `REMEDIATION` | Refactor post-3-strikes | 8 iter | `npm run test:e2e` |
| `PHASE-CLOSE` | Cierre de fase | 3 iter | `bash .jcode/tests/run_all.sh --quick` |
| `AUDIT` | Solo lectura | 1 iter | `grep -c TODO` (o similar) |

> **Stack-agnóstico**: los ejemplos anteriores usan `go test`/`npm test`
> solo como ilustración. El loop real declara su propio `fixed_check`
> según el stack del proyecto.

---

## Stop conditions (cuando cerrar el loop)

Cualquiera de estas condiciones cierra el loop:

1. **Éxito verificado**: `fixed_check` pasa
2. **No-op limpio**: el agente determina que no hay cambios que hacer
3. **Bloqueo reproducible**: dependencia externa caída, falta info del cliente
4. **Aprobación requerida**: el cambio cruza `approval_boundary`
5. **Presupuesto agotado**: se alcanzó `budget` iteraciones
6. **2-no-progreso**: 2 iteraciones consecutivas sin avance medible

### Hidden Failure Gate (obligatorio)

Ningún loop se cierra si el Hidden Failure Gate definido en `FAILURE-PATTERNS.md`
no está en estado `passed`. Ver ejecutar:

```bash
bash .jcode/tests/audit/verify_hidden_failure_gate.sh
bash .jcode/tests/audit/verify_hidden_failure_gate_independiente.sh
```

---

## Ejemplo canónico (agnóstico)

```markdown
- loop_id: L-SLICE-042
- task_class: SLICE
- goal: "Endpoint POST /items crea item y dispara evento"
- scope: [src/api/items.ts, src/events/dispatcher.ts]
- out_of_scope: [src/ui/, db/migrations/]
- fixed_check: "curl -s localhost:3000/api/items -d '{\"name\":\"x\"}' | jq .id"
- benchmark_type: curl
- budget: 5
- progress_metric: "endpoint responde 200 con body {id: <number>}"
- stop_conditions: [éxito, no-op, bloqueo, aprobación, budget, 2-no-progreso]
- approval_boundary: "cualquier cambio en db/schema requiere aprobación"
- handoff_artifact: "PLAN-VIVO §8 actualizado + commit hash"
```

---

## Anti-patrones

- ❌ Loop sin `fixed_check` → nunca se cierra
- ❌ Loop con `goal` vago ("mejorar performance") → no medible
- ❌ Loop con `budget: ∞` → nunca para
- ❌ Loop sin `out_of_scope` → creep garantizado
- ❌ Loop que solo el agente puede validar → R-AA-1 strike (autoengaño)
- ❌ Loop declarado pero no registrado en `INDEX.md §Loops activos` → invisible

---

## Registro en INDEX.md

Antes de empezar un loop, registrar:

```markdown
### 🟢 Loops activos
- L-SLICE-042 — Endpoint POST /items — started 2026-07-16T10:00Z
```

Al cerrar:

```markdown
### ✅ Loops cerrados (últimos 5)
- L-SLICE-042 — Endpoint POST /items — closed 2026-07-16T11:30Z — success
```

---

## Versión

- **v100-clean**: eliminadas refs a `go test`/`go build`/`backend/handlers`/`frontend/src/pages`
  (stack leak del proyecto anterior). Añadido ejemplo canónico agnóstico.
