# ANÁLISIS COMPARATIVO — Skill ORIENT vs Flujos del Harness

**Fecha**: 2026-07-21
**Pregunta**: ¿Qué posee y qué NO posee la skill `orient` después de haber añadido 6 componentes nuevos al harness (HF Gate, Frontier Quality, FAILURE-PATTERNS, LOOPS hf_gate, bootstrap-proyecto, 9 blockers remediados)?
**Conclusión**: La skill orient quedó **desactualizada y peligrosa** — un agente que la siga al pie de la letra omitirá los nuevos mecanismos de seguridad.

---

## §1 Inventario de flujos del harness actual (post-remediación)

| # | Flujo | Trigger | Mecanismo obligatorio |
|---|-------|---------|----------------------|
| 1 | **Orientación del agente** | Inicio de sesión, nueva tarea, agente perdido | Skill `orient` |
| 2 | **Triaje de tarea** | Árbol 4 preguntas (Orient §Fase 1) | Orient §Fase 1 |
| 3 | **Flujo Ligero (MICROFIX)** | Tarea trivial, sin acoplamiento | Orient §Fase 2-A + AGENT-PROTOCOL §1 items 1-3 |
| 4 | **Flujo Riguroso (SLICE/REMEDIATION)** | Muta estado, UI nueva, >2 archivos, >30 min | Orient §Fase 2-B + AGENT-PROTOCOL §4.7 + bgpd |
| 5 | **Cumplimiento (compliance scoring)** | Cada turnend | Hook `turnend.sh` + state_manager |
| 6 | **Resync del handbook** | Post-commit | Hook `turnend.sh` + `handbook_resync.py --auto` |
| 7 | **Hidden Failure Gate (HF Gate)** | task_class ≥ SLICE, fixed_check falló 2x, remediación | FAILURE-PATTERNS §2 + `verify_hidden_failure_gate*.sh` |
| 8 | **Frontier Quality: effort routing** | Inicio de cada turno | `config.toml [policy.effort_routing]` + `turnend.sh` |
| 9 | **Frontier Quality: evidence bundle** | Cierre de loop (task_class ≠ AUDIT) | `evidence_bundle.sh` + `turnend.sh` |
| 10 | **Frontier Quality: self-critique** | Cierre de turno | `turnend.sh` + `quality-preamble.md` |
| 11 | **Frontier Quality: reviewer spawn** | task_class ∈ {SLICE, REMEDIATION, PHASE-CLOSE} | `turnend.sh` + `swarm-prompt.md` |
| 12 | **Frontier Quality: reasoning trace** | Cada tool call | `posttool.sh` |
| 13 | **Remediación con budget + iteration logs** | bug recurrente o blocker detectado | `LOOPS.md` budget + `.jcode/logs/remediation-*.log` |
| 14 | **Bootstrap adaptativo** | Proyecto vacío, src/ sin código | `bootstrap-proyecto/lib/` |
| 15 | **Re-anclaje post-compresión** | Marcadores de summary detectados | Orient §Fase 4 |

**Total: 15 flujos** identificados en el harness actual.

---

## §2 Tabla comparativa — Orient vs Harness actual

| Flujo del Harness | Posee orient | Estado | Severidad |
|-------------------|:------------:|--------|:---------:|
| 1. Orientación | ✅ Sí | OK | — |
| 2. Triaje (Fase 1) | ✅ Sí | OK | — |
| 3. Flujo Ligero MICROFIX | ✅ Sí | OK | — |
| 4. Flujo Riguroso SLICE/REMEDIATION | ⚠️ Parcial | Faltan: HF Gate check, evidence bundle, reviewer spawn | **HIGH** |
| 5. Cumplimiento scoring | ❌ No | Orient no valida compliance >80 antes de cerrar | MEDIUM |
| 6. Resync post-commit | ❌ No | Orient no ejecuta `handbook_resync.py --auto` | MEDIUM |
| 7. **HF Gate** | ❌ No | Orient omite las 13 condiciones de cierre de FAILURE-PATTERNS §2 | **CRITICAL** |
| 8. Effort routing | ❌ No | Orient no consulta `[policy.effort_routing]` | LOW |
| 9. **Evidence bundle** | ❌ No | Orient no arma bundle ni valida persistencia | **HIGH** |
| 10. **Self-critique** | ❌ No | Orient omite re-lectura contra petición original | **HIGH** |
| 11. **Reviewer spawn** | ❌ No | Orient no valida `task_class ≥ SLICE` exige reviewer | **HIGH** |
| 12. Reasoning trace | ❌ No | Orient no captura tool calls en trace-*.log | LOW |
| 13. **Remediación con iteration logs** | ❌ No | Orient no exige `.jcode/logs/remediation-*.log` por iteración | **CRITICAL** |
| 14. **Bootstrap adaptativo** | ❌ No | Orient no detecta si el proyecto está vacío | MEDIUM |
| 15. Re-anclaje | ✅ Sí | OK | — |

### Resumen

| Categoría | Posee | No posee |
|-----------|:-----:|:--------:|
| Críticos (HF Gate, iteration logs) | 0 | 2 |
| High (evidence bundle, self-critique, reviewer) | 0 | 3 |
| Medium (compliance, resync, bootstrap) | 0 | 3 |
| Low (effort, reasoning trace) | 0 | 2 |
| **Total cubierto por orient** | **3/10** | **7/10** |

---

## §3 Gaps críticos — Qué puede salir mal si orient corre sin actualizarse

### Escenario 1: Agente reorienta pero ignora HF Gate
- Orient clasifica como SLICE → ejecuta Flujo Riguroso
- Aplica fix, escribe test propio, declara "funciona"
- **NO** ejecuta `verify_hidden_failure_gate.sh`
- **NO** existe `verify_*_independiente.sh`
- **NO** existe `.jcode/logs/remediation-*.log`
- → **CRITICAL**: blocker declarado resuelto sin anti-fraude (HF-V2 SELF-ORACLE)

### Escenario 2: Orient usa Fase 2-B pero no arma evidence bundle
- Orient ejecuta BGPD, fixed_check, escribe PLAN-VIVO §6
- **NO** ejecuta `evidence_bundle.sh`
- → **HIGH**: HF-G1 LOGLESS-REMEDIATION. La evidencia no está persistida, fix nunca ocurrió.

### Escenario 3: Orient cierra sesión sin self-critique
- Orient ejecuta Fase 3 (trazabilidad)
- **NO** relee el output contra la petición original (HF-V1 PHANTOM-PASS)
- → **HIGH**: el agente puede auto-engañarse sin que el arnés lo detecte

### Escenario 4: Orient promueve SLICE sin reviewer
- Tarea SLICE ejecutada, fixed_check pasa
- **NO** se exige spawn de reviewer (`auto_spawn_reviewer=true` en config)
- → **HIGH**: el multi-agent review nunca ocurre, baja calidad sistémica

### Escenario 5: Orient en proyecto vacío ejecuta Fase 1 sin bootstrap
- src/ está vacío, no hay código
- Orient ejecuta SRSI, busca matches → 0
- Prompt indica "fixed_check falló 2 veces" → cae en remedia
- Pero **NO** invoca `bootstrap-proyecto/lib/bootstrap_all.py`
- → **MEDIUM**: el agente reorienta mal porque el proyecto no está bootstrap-eado

---

## §4 Mecanismo de seguridad propuesto

**Idea**: Cada flujo del harness debe tener un **checkpoint ejecutable** que oriente pueda invocar. Si el checkpoint falla, Orient aborta y re-orienta.

### Nueva estructura: Orient con Checkpoints

```text
¿Recibí tarea nueva?
├─ NO → ¿Detecté marcadores de compresión? → SÍ → ejecutar Fase 4.
│                                        └─ NO → idle.
└─ SÍ → CHECKPOINT 0: Estado del proyecto
         ├─ ¿src/ vacío + PDR.md plantilla? → invocar bootstrap-proyecto
         └─ OK → Fase 1 (árbol de decisión)
                  ├─ MICROFIX → Fase 2-A
                  └─ SLICE/REM → Fase 2-B
                                ├─ CHECKPOINT 1: HF Gate pre-cierre
                                ├─ CHECKPOINT 2: Effort routing
                                ├─ CHECKPOINT 3: Evidence bundle
                                ├─ CHECKPOINT 4: Self-critique
                                └─ CHECKPOINT 5: Reviewer (si task_class ≥ SLICE)
                  → Fase 3 (trazabilidad)
```

### 6 nuevos checkpoints en Orient

| # | Checkpoint | Comando | Falla → acción |
|---|------------|---------|----------------|
| 0 | Proyecto bootstrap-eado | `python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py` | Si src/ vacío + no bootstrap → ejecutar `--apply` primero |
| 1 | HF Gate | `bash .jcode/tests/audit/verify_hidden_failure_gate.sh && bash .jcode/tests/audit/verify_hidden_failure_gate_independiente.sh` | Si falla → remediación obligatoria |
| 2 | Effort routing | `python3 -c "import tomllib; c=tomllib.loads(open('.jcode/config.toml','rb').read()); print(c['policy']['effort_routing'][$TASK_CLASS])"` | Si no existe → bloque |
| 3 | Evidence bundle | `bash .jcode/lib/evidence_bundle.sh $LOOP_ID` | Si verdict=INCOMPLETE → bloque |
| 4 | Self-critique | Re-leer output vs petición original; marcar `self_critique_pending` en compliance | Si no marcado → bloque |
| 5 | Reviewer (si SLICE/REM/PHASE-CLOSE) | `state_set reviewer_required true` o spawn en TUI | Si task_class ≥ SLICE y reviewer_required=false → bloque |

---

## §5 Anti-patrones actuales (Orient sin actualizar)

- ❌ **Declara "resuelto" sin ejecutar HF Gate** — Violates HF-V1, HF-V2, HF-G1
- ❌ **No arma evidence bundle** — Violates HF-G1 LOGLESS-REMEDIATION
- ❌ **No re-lee output** — Violates HF-V1 PHANTOM-PASS
- ❌ **No spawnea reviewer en SLICE** — Violates quality-preamble.md §4
- ❌ **No detecta proyecto vacío** — Operates sin bootstrap-eado
- ❌ **No persiste iteration logs** — Violates R-ITERATION-LOG §9
- ❌ **Cierra con compliance <80** — Violates R-AA-1 anti-autoengaño
- ❌ **No ejecuta resync post-commit** — Handbook desactualizado

---

## §6 Plan de remediación de Orient

Para que Orient sea **otro mecanismo de seguridad de flujo**, debe:

1. **Agregar 5 nuevos pasos al árbol de decisión** (Checkpoints 1-5)
2. **Hacer ejecutable cada paso** (no solo consejo)
3. **Exigir HF Gate como pre-condición de cierre** (no opcional)
4. **Documentar el flujo bootstrap** (Checkpoint 0)
5. **Reemplazar la matriz obsoleta** por la nueva matriz con checkpoints
6. **Agregar anti-patrones nuevos** para los flujos nuevos

---

## §7 Veredicto

| Métrica | Antes de actualizar Orient |
|---------|---------------------------|
| Flujos cubiertos por Orient | 3/15 (20%) |
| Flujos críticos omitidos | 5 |
| HF Gate enforcement | NO |
| Evidence bundle enforcement | NO |
| Self-critique enforcement | NO |
| Reviewer spawn enforcement | NO |
| Bootstrap detection | NO |

**Riesgo**: HIGH — un agente siguiendo Orient puede aprobar tareas sin pasar por los 5 mecanismos de seguridad del harness.

**Acción**: Reescribir Orient con 6 checkpoints ejecutables.
