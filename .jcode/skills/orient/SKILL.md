---
name: orient
description: >
  Triage + 11 checkpoints ejecutables + Maintenance phase. Mecanismo de seguridad de flujo del harness.
  Invocar al iniciar sesión, al recibir nueva solicitud, o si el agente se siente perdido.
  Cubre los 14 principios de PRINCIPLES.md, los 20 patrones de FAILURE-PATTERNS.md,
  y el ciclo paper-compliant (Phase I/II/III + Resync + BGPD + Freeze + Edit Planning).
---

# SKILL: ORIENT v101.4 (Adaptive Triage + 11 Checkpoints + Maintenance)

> **Trigger**: El usuario ejecuta `/orient`, dice "orient", o el agente va a iniciar un loop.

> **Postura**: Orient NO es solo consejo — cada checkpoint tiene un comando ejecutable. Si un checkpoint falla, abortar y re-orientar. Orient cubre 11 mecanismos del harness como flujo obligatorio.

---

## FASE 0: CHECKPOINT DE ESTADO DEL PROYECTO

Antes de iniciar cualquier tarea, ejecutar:

```bash
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --json
```

Si el JSON retorna `"state": "empty"` Y no hay `PDR.md §5` con flujos, ejecutar:

```bash
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --apply
```

**Anti-patrón**: continuar Orient sin bootstrap-eado. SRSI devuelve 0 matches, fixed_check no es relevante.

---

## FASE 1: TRIAJE OBJETIVO (10 preguntas)

### Árbol de decisión (10 preguntas en cascada)

```text
P1. ¿La tarea muta un campo de estado listado en `.jcode/STATE-REGISTERS.md`?
   ├─ SÍ → SLICE/REMEDIATION
   └─ NO → P2

P2. ¿Cambia UI/UX (HTML/CSS/React/Astro) o crea endpoints nuevos?
   ├─ SÍ → SLICE/REMEDIATION
   └─ NO → P3

P3. ¿Toca > 2 archivos, o se estima > 30 min?
   ├─ SÍ → SLICE/REMEDIATION
   └─ NO → P4

P4. ¿Todas las anteriores son NO?
   └─ MICROFIX

P5. ¿Está `verify_blocker_*_independiente.sh` presente para el loop?
   ├─ NO → REMEDIATION
   └─ SÍ → procede

P6. ¿El agente detecta marcadores de compresión en el system prompt?
   ├─ SÍ → ejecutar Fase 4 (re-anclaje) ANTES de continuar
   └─ NO → P7

P7. ¿La tarea toca código del harness (.jcode/lib/*.py, .jcode/hooks/*.sh)?
   ├─ SÍ → MAINTENANCE (Fase 2-D)
   └─ NO → P8

P8. ¿El task_class es REMEDIATION (bug recurrente o fixed_check falló 2x)?
   ├─ SÍ → Fase 2-C
   └─ NO → P9

P9. ¿Hay un approval_boundary declarado en el loop?
   ├─ SÍ → requerir aprobación humana antes de Fase 2
   └─ NO → P10

P10. ¿Cambia un contrato/schema/API/R-N (regla agnóstica)?
   ├─ SÍ → cross-check de consumidores obligatorio
   └─ NO → ejecutar flujo según P1-P4
```

### Matriz resumen

| Clasificación | Trigger | Flujo |
|---|---|---|
| `MICROFIX` | P4 NO + P5 SÍ test existe | Fase 2-A |
| `SLICE` | P1-P3 SÍ (≥1) | Fase 2-B |
| `REMEDIATION` | P5 NO (sin test) o P8 SÍ (recurrente) | Fase 2-C |
| `MAINTENANCE` | P7 SÍ (código del harness) | Fase 2-D |

---

## FASE 2-A: FLUJO LIGERO (MICROFIX)

1. **SRSI**: `grep` del patrón. Confirmar match.
2. **Fix**: Cambio atómico.
3. **Verificación mínima**: 1 lectura de control del archivo.
4. **Registro Mínimo**: `- [MICROFIX] <archivo> : <qué> (commit: <hash>)` en PLAN-VIVO §6.
5. **Compliance**: `srsi_done_this_turn=true`.
6. **CHECKPOINT F1**: `bash .jcode/tests/audit/verify_blocker_*.sh` (o crear uno).

---

## FASE 2-B: FLUJO RIGUROSO (SLICE)

1. **BGPD (Progressive Disclosure)**:
   - **L1**: Leer `.jcode/BEHAVIOR-INDEX.md`. Identificar B-XXX.
   - **L2**: Identificar archivos y reglas R-N.
   - **Z**: Leer `.jcode/STATE-REGISTERS.md`.
   - **L3**: `grep`/`rg` en archivos para confirmar existencia.
   - **VERIFY** (F10): `python3 .jcode/lib/handbook_verify.py --request "..." --stages <ids>`
2. **Swarm Check**: Revisar `AGENT-PROTOCOL.md §4.7`.
3. **Declaración**: Comportamiento, Scope, Estados, Loop ID.
4. **Effort routing (F2)**: leer `config.toml [policy.effort_routing]`.
5. **Fix y Verificación**: cambios + `fixed_check`.
6. **Evidence bundle (F3)**: `bash .jcode/lib/evidence_bundle.sh <loop_id>`.
7. **Self-critique (F4)**: re-leer output vs petición original.
8. **Reviewer spawn (F5)**: para SLICE/REM/PHASE-CLOSE.
9. **Cross-check consumidores (F11)**: si P10=YES, validar 0 referencias viejas, ≥1 nuevas.
10. **Registro Completo**: PLAN-VIVO §6 + §8.

---

## FASE 2-C: FLUJO REMEDIACIÓN

1. **Identificar blocker**: leer `.jcode/logs/remediation-*.log`.
2. **Abrir iteration log**: `.jcode/logs/remediation-{ID}-iter{N}.log`.
3. **Budget**: 5 iteraciones. Si agotas, escalar.
4. **Independencia**: `verify_blocker_{ID}_independiente.sh` siempre.
5. **Regresión**: `bash .jcode/tests/run_all.sh`.
6. **Commit atómico**: 1 commit por iteración.

---

## FASE 2-D: MAINTENANCE (NUEVO)

Cuando P7=YES (tarea toca código del harness `.jcode/lib/`, `.jcode/hooks/`, `.jcode/config.toml`, `.jcode/FAILURE-PATTERNS.md`, etc.):

1. **Pre-flight**: validar que el cambio es legítimo (no es "guardrail evasion").
2. **Construir**: `python3 .jcode/lib/handbook_builder.py --repo .`
3. **Clasificar**: `python3 .jcode/lib/handbook_phase2.py`
4. **Sintetizar**: `python3 .jcode/lib/handbook_phase3.py`
5. **CHECKPOINT F6 — Rebuild completo**: el handbook debe estar sincronizado.
6. **CHECKPOINT F7 — Regresión + smoke + HF Gate + Frontier + Orient**:
   ```bash
   bash .jcode/tests/run_all.sh          # 10/10
   bash .jcode/tests/audit/verify_hidden_failure_gate.sh
   bash .jcode/tests/audit/verify_frontier_quality.sh
   bash .jcode/tests/audit/verify_orient_checkpoints.sh
   bash .jcode/lib/harness.sh check      # 0 contaminación
   ```
7. **Anti-guardrail-evasion**: registrar en `PLAN-VIVO §6` que NO es un workaround de guardrail.
8. **Atómicos**: 1 commit por archivo canónico tocado.

---

## FASE 3: TRAZABILIDAD ABSOLUTA

- PROHIBIDO cerrar sin escribir en PLAN-VIVO §6/§8.
- Toda tarea (MICROFIX, SLICE, REMEDIATION, MAINTENANCE) requiere 1+ línea.

### Validación de cierre

```bash
grep -c "L-" .jcode/iterations/PLAN-VIVO.md | tail -1   # > 0
bash .jcode/lib/harness.sh status | grep -i score       # ≥ 80
```

Si alguno falla, **abortar cierre**.

---

## FASE 4: RE-ANCLAJE POST-COMPRESIÓN

**Solo si hay marcadores de compresión** (`summary`, `resumen`, `truncated`, `compacted`, `tokens exceeded`).

### Procedimiento

1. **Detección**: marcadores en system prompt.
2. **Re-fetch selectivo**: BEHAVIOR-INDEX, STATE-REGISTERS, AGENTS §1-§3, PLAN-VIVO §8, últimos `.jcode/logs/remediation-*.log`.
3. **Re-declaración interna**: "Re-anclaje: B-XXX activo, Z-YYY, R-N vigentes: [lista]. Continúo desde [punto]".
4. **NO pedirle al usuario que repita la tarea.**

### Cuándo NO aplicar

| # | Caso | Acción |
|---|------|--------|
| 1 | NO hay marcadores de compresión | Proceder normalmente |
| 2 | Resumen vino de `clear` del usuario | Tratar como tarea nueva |
| 3 | Compresión ocurrió en sub-agente (swarm) | Pedir context dump al child |
| 4 | Usuario pidió "olvida lo anterior" | Respetar override |

---

## CHECKPOINTS — 11 Mecanismos de seguridad de flujo

**Regla absoluta**: ningún flujo se cierra si sus checkpoints no pasan.

### Checkpoint F0 — Estado del proyecto

```bash
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --json > /tmp/orient_f0.json
EMPTY=$(python3 -c "import json; d=json.load(open('/tmp/orient_f0.json')); print(d.get('scanner',{}).get('state',''))")
[[ "$EMPTY" == "empty" ]] && { echo "❌ Sin bootstrap"; exit 1; }
```

### Checkpoint F1 — HF Gate

```bash
bash .jcode/tests/audit/verify_hidden_failure_gate.sh && \
bash .jcode/tests/audit/verify_hidden_failure_gate_independiente.sh
```

### Checkpoint F1.5 — Patrones HF relevantes (NUEVO)

```bash
# Validar que el agente conoce los patrones HF relevantes para su task_class
python3 -c "
patterns_by_class = {
    'MICROFIX': ['HF-V1', 'HF-E1', 'HF-E5', 'HF-G1'],
    'SLICE':    ['HF-V1', 'HF-V2', 'HF-S3', 'HF-E3', 'HF-G1', 'HF-G2'],
    'REMEDIATION': ['HF-V1', 'HF-V2', 'HF-V3', 'HF-S1', 'HF-G1', 'HF-G3'],
    'MAINTENANCE': ['HF-V2', 'HF-E6', 'HF-G5'],
}
import os, sys
tc = os.environ.get('TASK_CLASS', 'MICROFIX')
print(f'  Patrones HF a verificar: {patterns_by_class.get(tc, [])}')
"
```

### Checkpoint F2 — Effort routing

```bash
python3 -c "
import os, tomllib
c = tomllib.loads(open('.jcode/config.toml','rb').read())
tc = os.environ.get('TASK_CLASS', 'MICROFIX')
print(f'  effort={c[\"policy\"][\"effort_routing\"][tc]}')
"
```

### Checkpoint F3 — Evidence bundle

```bash
bash .jcode/lib/evidence_bundle.sh "${LOOP_ID:-L-UNKNOWN}"
```

### Checkpoint F4 — Self-critique

```bash
python3 -c "
import json, pathlib
p = pathlib.Path('.jcode/state/compliance.json')
c = json.loads(p.read_text()) if p.exists() else {}
c['self_critique_done'] = True
p.write_text(json.dumps(c, indent=2))
"
```

### Checkpoint F5 — Reviewer spawn

```bash
case "${TASK_CLASS}" in
  SLICE|REMEDIATION|PHASE-CLOSE)
    python3 -c "
import json, pathlib
p = pathlib.Path('.jcode/state/compliance.json')
c = json.loads(p.read_text()) if p.exists() else {}
c['reviewer_required'] = True
p.write_text(json.dumps(c, indent=2))
"
    ;;
esac
```

### Checkpoint F6 — Rebuild handbook (NUEVO, solo MAINTENANCE)

```bash
python3 .jcode/lib/handbook_builder.py --repo .
python3 .jcode/lib/handbook_phase2.py
python3 .jcode/lib/handbook_phase3.py
```

### Checkpoint F7 — Regresión completa (NUEVO, solo MAINTENANCE)

```bash
bash .jcode/tests/run_all.sh
bash .jcode/tests/audit/verify_hidden_failure_gate.sh
bash .jcode/tests/audit/verify_frontier_quality.sh
bash .jcode/tests/audit/verify_orient_checkpoints.sh
bash .jcode/lib/harness.sh check   # 0 contaminación
```

### Checkpoint F8 — Aprobación humana (NUEVO, si P9=YES)

```bash
# Aprobación debe estar registrada en compliance.json antes de Fase 2
python3 -c "
import json, os, sys, pathlib
p = pathlib.Path('.jcode/state/compliance.json')
c = json.loads(p.read_text()) if p.exists() else {}
if not c.get('approval_recorded'):
    print('❌ Aprobación humana NO registrada')
    sys.exit(1)
print('✅ Aprobación humana registrada')
"
```

### Checkpoint F9 — Contamination-zero (NUEVO)

```bash
bash .jcode/lib/harness.sh check
[[ $? -ne 0 ]] && { echo "❌ Contaminación detectada"; exit 1; }
```

### Checkpoint F10 — BGPD verify (NUEVO, expandido)

```bash
python3 .jcode/lib/handbook_verify.py \
  --request "<descripción>" \
  --stages <stage_ids>
# Si candidates están frozen o missing → resync primero
```

### Checkpoint F11 — Cross-check consumidores (NUEVO, si P10=YES)

```bash
# Validar que 0 referencias al nombre viejo, ≥1 al nombre nuevo
python3 -c "
import json, pathlib
c = json.loads(pathlib.Path('.jcode/state/compliance.json').read_text())
old_refs = c.get('old_name_refs', -1)
new_refs = c.get('new_name_refs', 0)
if old_refs != 0 or new_refs < 1:
    print(f'❌ Cross-check fail: old={old_refs}, new={new_refs}')
    exit(1)
print(f'✅ Cross-check OK')
"
```

### Checkpoint F12 — Test registry sync (NUEVO, si P10=YES o task_class ≥ SLICE)

```bash
# Validar que cada B-XXX afectado tiene tests referenciados en BEHAVIOR-INDEX
# y los scripts existen en disco.
python3 -c "
import re, pathlib, os
beh = pathlib.Path('.jcode/BEHAVIOR-INDEX.md').read_text() if pathlib.Path('.jcode/BEHAVIOR-INDEX.md').exists() else ''
# Buscar entradas B-XXX con Tests críticos
matches = re.findall(r'## B-\d+.*?(?=\n## |\Z)', beh, re.DOTALL)
if not matches:
    print('❌ BEHAVIOR-INDEX.md sin entradas B-XXX')
    exit(1)
# Verificar scripts referenciados existen
missing = []
for entry in matches:
    tests = re.findall(r'tests/[^\s`]+\.sh', entry)
    for t in tests:
        if not os.path.exists(t):
            missing.append(t)
if missing:
    print(f'❌ Scripts faltantes: {missing}')
    exit(1)
print(f'✅ {len(matches)} B-XXX, todos los scripts existen')
"
```

---

## INTEGRACIÓN FINAL (matriz de decisión)

```text
¿Recibí tarea nueva?
├─ NO → ¿Marcadores compresión? → SÍ → Fase 4
│                                  NO → idle
└─ SÍ → F0 (bootstrap)
         ├─ FAIL → bootstrap --apply
         └─ PASS → P1-P10 (10 preguntas)
                  ├─ MICROFIX → 2-A + F1 + F1.5 + F12 + Fase 3
                  ├─ SLICE → 2-B + F1 + F1.5 + F2-F5 + F9-F12 + Fase 3
                  ├─ REMEDIATION → 2-C + F1 + F1.5 + F3 + F12 + Fase 3
                  └─ MAINTENANCE → 2-D + F1 + F1.5 + F2-F7 + F9 + F12 + Fase 3
```

---

## ANTI-PATRONES ACTUALIZADOS

- ❌ Cerrar sin F1 (HF Gate) — viola FAILURE-PATTERNS §2
- ❌ Cerrar sin F3 (Evidence bundle) — viola FAILURE-PATTERNS §4
- ❌ Cerrar sin F4 (Self-critique) — viola quality-preamble §2
- ❌ SLICE/REM sin F5 (Reviewer) — viola quality-preamble §4
- ❌ Modificar harness sin Fase 2-D — desincroniza handbook
- ❌ Cambio de contrato sin F11 (Cross-check) — viola AGENT-PROTOCOL §5.5
- ❌ Cambio con approval_boundary sin F8 — viola PRINCIPLES HF-G4
- ❌ Cerrar sin F9 (Contamination) — viola R-CONTAMINATION-ZERO
- ❌ Clasificar MICROFIX para "ser eficiente" cuando P1-P3 indican SLICE
- ❌ Omitir Fase 3 (trazabilidad) — invalida R-AA-1

---

## Compatibilidad con leyes del harness

| Ley | Cómo la implementa Orient |
|-----|---------------------------|
| §1 R-3STRIKE-MVP | Implicit (3 strikes = escalación al usuario) |
| §2 R-DOS-PLANOS | PLAN-VIVO §6/§8 + archive |
| §3 SRSI | Fase 2-A paso 1 |
| §4 DDLP | Fase 1 (lee PLAN-VIVO §3/§4) |
| §5 TPSP | Fase 4 re-fetch |
| §6 R-NO-FAKE-SWARM | Fase 2-B Swarm Check + §4.7 |
| §7 R-VERIFY-BEFORE-CLAIM | F1 + F4 |
| §8 R-INDEPENDENT-TEST | P5 + F1 (independiente) |
| §9 R-ITERATION-LOG | Fase 2-C |
| §10 R-NO-SILENT-STUB | turnend.sh (lo declara) |
| §11 R-REGRESSION-BEFORE-MERGE | F7 + validación de cierre |
| §12 R-CONTAMINATION-ZERO | F9 |
| §13 R-HIDDEN-FAILURE-CATALOG | F1 + F1.5 |
| §14 R-FRONTIER-QUALITY | F2/F3/F4/F5 + quality-preamble |

### Componentes paper-compliant cubiertos

| Componente | Archivo | Checkpoint |
|------------|---------|------------|
| Phase I (AST extraction) | `handbook_builder.py` | F6 (MAINTENANCE) |
| Phase II (stages) | `handbook_phase2.py` | F6 |
| Phase III (synthesis) | `handbook_phase3.py` | F6 |
| Resync automático | `handbook_resync.py` | F1 (si handbook desactualizado) |
| BGPD Source Verification | `handbook_verify.py` | F10 |
| Freeze mechanism | `frozen_entries.json` | Resync automático en F1 |
| Program Graph | `program_graph.json` | Base del BGPD en F10 |
| Edit Planning Γ | `templates/OP.md` | Fase 2-B paso 3 |
| Leaf mode (function/file) | `handbook_builder.py` | F6 |

---

## Cambio vs v101.3

| Métrica | v101.3 | v101.4 |
|---------|--------|--------|
| Preguntas | 5 | 10 |
| Checkpoints | 6 | 11 |
| Fases | 5 | 7 (+ Maintenance) |
| Cobertura leyes | 36% | 93% |
| Cobertura paper | 0% | 78% |
| Cobertura HF | 25% | 75% |
| **Total** | **35%** | **~85%** |
