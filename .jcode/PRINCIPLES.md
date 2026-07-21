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

### §7 R-VERIFY-BEFORE-CLAIM — No declarar sin evidencia

**Nunca** decir "funciona", "está listo", "todo bien" sin haber ejecutado
un comando reproducible que lo demuestre.

- Antes de declarar un blocker resuelto: ejecutar `bash verify_blocker_X.sh`
- Capturar output completo en el log de iteración
- Si el test falla: iterar. No declarar "casi listo".

### §8 R-INDEPENDENT-TEST — Test propio + Test independiente

Todo fix requiere **2 niveles de test**:

1. **Test propio** (quien hace el fix lo escribe): verifica que el fix funciona
2. **Test independiente** (recalcula desde ground truth): verifica que no hay
   autoengaño. NO puede leer archivos generados por el fix. Debe parsear el
   código fuente directamente (AST, grep, etc.)

El test independiente debe existir **ANTES** de declarar el blocker resuelto.
Si no existe, el bloque no está resuelto — es un hallazgo pendiente.

### §9 R-ITERATION-LOG — Log obligatorio por iteración

Cada intento de resolver un bloque debe documentarse en un archivo de log:

```
.jcode/logs/remediation-{ID}-iter{N}.log
```

El log DEBE contener:
- Timestamp y número de iteración
- Cambios aplicados (archivo + líneas + descripción)
- Output del test propio (exit code + mensaje)
- Output del test independiente (exit code + mensaje)
- Output de regresión (exit code + pass/fail count)
- Veredicto: PASSED o FAILED (con motivo)

Si el log no existe o está vacío, el fix no ocurrió.

### §10 R-NO-SILENT-STUB — Stubs visibles o no existen

Cualquier modo stub/fallback/heurístico debe ser explícitamente visible:

- Warning en stderr al inicio de la ejecución
- Flag `LLM_AVAILABLE = False` documentado en el código
- El README documenta qué dependencias opcionales activan el modo real
- El stub no puede ser silencioso

### §11 R-REGRESSION-BEFORE-MERGE — Regresión completa antes de merge

Antes de mergear cualquier cambio al arnés:

- [ ] `bash .jcode/tests/run_all.sh` → 0 fail
- [ ] `bash .jcode/lib/harness.sh check` → 0 contaminación
- [ ] Todos los `verify_blocker_*.sh` → exit 0
- [ ] Todos los `verify_blocker_*_independiente.sh` → exit 0
- [ ] `python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py` → sin errores

### §12 R-CONTAMINATION-ZERO — Cero contaminación en el arnés

`.jcode/` NO debe contener:

- Paths absolutos (`/home/`, `/Users/`, `C:\`)
- Nombres de proyecto hardcodeados
- Contraseñas, tokens, API keys
- Reglas de negocio del proyecto
- Archivos `.pyc` o `__pycache__/`

Verificar con: `bash .jcode/lib/harness.sh check`

Si `harness.sh check` reporta contaminación > 0, detener y limpiar antes de
cualquier otro trabajo.

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
| **R-VERIFY-BEFORE-CLAIM** | §7: No declarar sin evidencia ejecutable |
| **R-INDEPENDENT-TEST** | §8: Test propio + test independiente por fix |
| **R-ITERATION-LOG** | §9: Log obligatorio por iteración |
| **R-NO-SILENT-STUB** | §10: Stubs deben ser visibles |
| **R-REGRESSION-BEFORE-MERGE** | §11: Regresión completa antes de merge |
| **R-CONTAMINATION-ZERO** | §12: Cero contaminación en `.jcode/` |

R-AA-2 y R-AA-3 viven en `INCIDENT-PROTOCOLS.md` (cargo bajo demanda).

---

## Versión

- **v101.2-paper-compliant** (2026-07-21): Añadidos 6 principios anti-fallo
  (§7 R-VERIFY-BEFORE-CLAIM, §8 R-INDEPENDENT-TEST, §9 R-ITERATION-LOG,
  §10 R-NO-SILENT-STUB, §11 R-REGRESSION-BEFORE-MERGE, §12 R-CONTAMINATION-ZERO).
  Glosario actualizado con 6 nuevos términos.
- **v100-clean**: refactor. Eliminados ejemplos de proyecto específico.
