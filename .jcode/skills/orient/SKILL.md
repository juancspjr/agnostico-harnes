---
name: orient
description: >
  Triage + checkpoints ejecutables del agente. Invocar al iniciar sesión, al recibir una nueva solicitud, o si el agente se siente perdido.
  Ejecuta un Triage objetivo, aplica checkpoints anti-autoengaño (HF Gate, Frontier Quality), y garantiza trazabilidad.
  Mecanismo de seguridad de flujo: cada checkpoint falla aborta la operación.
---

# SKILL: ORIENT (Adaptive Triage + Checkpoints)

> **Trigger**: El usuario ejecuta `/orient`, dice "orient", o el agente va a iniciar un loop.

> **Postura**: Orient NO es solo consejo — cada checkpoint tiene un comando ejecutable. Si un checkpoint falla, abortar y re-orientar.

---

## FASE 0: CHECKPOINT DE ESTADO DEL PROYECTO (NUEVO)

Antes de iniciar cualquier tarea, ejecutar:

```bash
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --json
```

Si el JSON retorna `"state": "empty"` Y no hay `PDR.md §5` con flujos, el proyecto **NO está bootstrap-eado**:

```bash
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --apply
```

Si falla, **abortar Orient** y declarar blocker: "Proyecto sin bootstrap".

**Anti-patrón**: continuar Orient sin bootstrap-eado. Resultado: SRSI devuelve 0 matches, fixed_check no es relevante, el agente opera sin modelo del proyecto.

---

## FASE 1: TRIAJE OBJETIVO (Obligatorio al recibir la tarea)

El agente DEBE clasificar la tarea usando este **árbol de decisión** SIN
excepciones. No usar "criterio propio", seguir el orden de preguntas:

### Árbol de decisión (5 preguntas en cascada — AHORA 5)

```text
P1. ¿La tarea muta un campo de estado listado en
    `.jcode/STATE-REGISTERS.md` (o el mapa de estados del proyecto)?
    ├─ SÍ → SLICE/REMEDIATION (Flujo Riguroso, Fase 2-B)
    └─ NO → P2

P2. ¿La tarea cambia UI/UX (HTML/CSS/React/Astro) o crea
    endpoints nuevos?
    ├─ SÍ → SLICE/REMEDIATION (Flujo Riguroso, Fase 2-B)
    └─ NO → P3

P3. ¿La tarea toca > 2 archivos, o se estima > 30 min?
    ├─ SÍ → SLICE/REMEDIATION (Flujo Riguroso, Fase 2-B)
    └─ NO → P4

P4. ¿Todas las anteriores son NO?
    └─ MICROFIX (Flujo Ligero, Fase 2-A)

P5. ¿Está `verify_blocker_*_independiente.sh` presente para el loop?
    ├─ NO → REMEDIATION (requiere crear test independiente)
    └─ SÍ → procede con flujo según P1-P4
```

### Matriz resumen (5 preguntas)

| Clasificación | Trigger (cualquiera) | Flujo |
|---|---|---|
| `SLICE/REMEDIATION` | Muta estados, cambia UI, crea endpoints, >2 archivos | Fase 2-B (BGPD + Swarm + HF Gate) |
| `MICROFIX` | Ninguno de los anteriores, test independiente existe | Fase 2-A (SRSI + fix directo) |
| `REMEDIATION` | Bug recurrente, fixed_check falló 2x, o test independiente falta | Fase 2-C (Remediación) |

### Reglas de promoción MICROFIX → SLICE

Si durante la ejecución del MICROFIX se descubre que:
- Aparecen sitios acoplados no anticipados (más de 1 grep adicional).
- El cambio toca un estado de BD que no estaba en el scope inicial.

**Entonces**: PROMOVER a SLICE. No continuar como MICROFIX. Esto evita
el anti-patrón "empezar ligero y terminar incompleto".

---

## FASE 2-A: FLUJO LIGERO (MICROFIX)

1. **SRSI**: Hacer `grep` del patrón a cambiar. Confirmar match.
2. **Fix**: Aplicar cambio atómico.
3. **Verificación mínima**: leer el archivo modificado completo para
   confirmar coherencia (1 lectura de control).
4. **Registro Mínimo**: Appendear 1 línea en `PLAN-VIVO §6` con
   formato: `- [MICROFIX] <archivo> : <qué cambió> (commit: <hash>)`.
5. **Compliance**: Setear `srsi_done_this_turn=true` en `compliance.json`.
6. **CHECKPOINT F1 (anti-ORACLE)**: ejecutar
   `bash .jcode/tests/audit/verify_blocker_*.sh` para validar que el fix
   realmente funcionó. Si no hay verify_blocker_*, el agente ESCRIBE uno
   antes de continuar.

---

## FASE 2-B: FLUJO RIGUROSO (SLICE)

1. **BGPD (Progressive Disclosure)**:
   - **L1**: Leer `.jcode/BEHAVIOR-INDEX.md`. Identificar comportamiento B-XXX.
   - **L2**: Identificar archivos y reglas (R-N) involucradas.
   - **Z**: Leer `.jcode/STATE-REGISTERS.md` para los estados. Alistar sitios acoplados.
   - **L3**: Hacer `grep`/`rg` en los archivos para confirmar existencia.
   - **VERIFY**: Ejecutar OBLIGATORIAMENTE:
     ```bash
     python3 .jcode/lib/handbook_verify.py \
       --request "<descripción del cambio>" \
       --stages <stage_ids>
     ```
     Retener solo los sites que el script retorna como `verified`.
     Si todos los candidates están `frozen` o `missing`, el handbook
     está desactualizado — invocar `handbook_resync.py --auto` antes
     de continuar.
2. **Swarm Check**: Revisar `AGENT-PROTOCOL.md §4.10`. ¿Requiere
   spawnear sub-agente? (Si toca backend+frontend, spawnear workers).
3. **Declaración**: Declarar al usuario el Comportamiento, Scope,
   Estados y Loop (L-SLICE-NNN).
4. **Effort routing (CHECKPOINT F2)**: consultar `config.toml`:
   ```bash
   python3 -c "
   import tomllib
   c = tomllib.loads(open('.jcode/config.toml','rb').read())
   print(c['policy']['effort_routing'].get('SLICE', 'medium'))
   "
   ```
   El effort de salida es el que el agente DEBE usar.
5. **Fix y Verificación**: Aplicar cambios. Correr `fixed_check`. Triple
   Evidencia §30.
6. **Evidence bundle (CHECKPOINT F3)**: ejecutar OBLIGATORIAMENTE:
   ```bash
   bash .jcode/lib/evidence_bundle.sh <loop_id>
   ```
   Verificar que el verdict NO sea `INCOMPLETE`. Si lo es, **abortar**.
7. **Self-critique (CHECKPOINT F4)**: antes de declarar "listo",
   el agente debe releer su output contra la petición original y
   marcar `self_critique_done=true` en `compliance.json` vía `state_set`.
   Si no se hace, el hook `turnend.sh` lo marcará `self_critique_pending=true`
   y emitirá warning.
8. **Reviewer spawn (CHECKPOINT F5)**: para SLICE/REMEDIATION/PHASE-CLOSE,
   el hook `turnend.sh` ya emite warning si `reviewer_required=false`.
   Si TUI: `Ctrl+N` → spawn reviewer con fixed_check como prompt.
   Si headless: `state_set reviewer_required true`.
9. **Registro Completo**: Actualizar `PLAN-VIVO §6` (detallado) y `§8`
   (handoff).

---

## FASE 2-C: FLUJO REMEDIACIÓN (NUEVO)

Cuando el bloqueo viene del HF Gate (F-1 a F-5 fallan) o de un bug recurrente:

1. **Identificar blocker**: leer `.jcode/logs/remediation-*.log` (si existe).
2. **Abrir iteration log** OBLIGATORIO:
   ```
   .jcode/logs/remediation-{ID}-iter{N}.log
   ```
   Formato mínimo (ver `FAILURE-PATTERNS.md §9 R-ITERATION-LOG`):
   ```
   [timestamp] ITERATION N/5 — blocker {ID}
   [timestamp] Cambios aplicados:
     - archivo1.py: líneas X-Y (descripción)
   [timestamp] Test:
     $ bash verify_blocker_{ID}.sh
     Exit: 0
   [timestamp] VEREDICTO: PASSED
   ```
3. **Budget**: 5 iteraciones por blocker. Si agotas, escalar al usuario.
4. **Independencia de test**: SIEMPRE `verify_blocker_{ID}_independiente.sh`
   que recalcula desde ground truth.
5. **Regresión**: `bash .jcode/tests/run_all.sh` antes de declarar PASSED.
6. **Commit atómico**: 1 commit por iteración, con el log incluido.

---

## FASE 3: REGLA DE TRAZABILIDAD ABSOLUTA

- **PROHIBIDO** cerrar un turno sin haber escrito en `PLAN-VIVO §6` o
  `§8`, sin importar qué tan pequeña haya sido la tarea.
- Una tarea `MICROFIX` no exime de la trazabilidad. Si no se documenta,
  no se hizo (R-AA-1).

### Validación de cierre

Antes de declarar tarea cerrada:

```bash
# ¿Se escribió en PLAN-VIVO?
grep -c "L-" .jcode/iterations/PLAN-VIVO.md | tail -1
# Debe ser > 0

# ¿Compliance score ≥ 80?
bash .jcode/lib/harness.sh status | grep -i score
```

Si alguno falla, **abortar cierre**.

---

## FASE 4: RECUPERACIÓN POST-COMPRESIÓN DE CONTEXTO

**Solo activar cuando el agente detecte señales explícitas de resumen**
(`"Previously..."`, `"Resumen de la conversación anterior"`, `"Earlier
turns were summarized"`, o cuando el system prompt indique truncación).

### Procedimiento de re-anclaje

1. **Detección**: leer el system prompt o el último mensaje del usuario
   buscando marcadores de compresión (`summary`, `resumen`, `truncated`,
   `compacted`, `tokens exceeded`).
2. **Re-fetch selectivo** (no recargar todo):
   - `.jcode/BEHAVIOR-INDEX.md` y `.jcode/STATE-REGISTERS.md` (mapas).
   - `AGENTS.md §1-§3` (reglas R-N vigentes).
   - `.jcode/iterations/PLAN-VIVO.md §8` (últimas 5 entradas para
     recuperar contexto del loop activo).
   - **NUEVO**: `.jcode/logs/remediation-*.log` (última iteración si
     el loop era remediación).
3. **Re-declaración interna**: antes de proseguir, el agente debe
   escribir internamente:
   > "Re-anclaje post-compresión: B-XXX activo, estado Z-YYY, R-N
   > vigentes: [lista]. Continúo desde: [punto exacto]."
4. **Continuidad sin interrupciones**: NO pedirle al usuario que repita
   la tarea. NO re-declarar el sprint completo. Solo continuar.

### Anti-patrones Fase 4

- ❌ Detectar compresión cuando NO existe (asumir que hubo resumen sin
  marcador).
- ❌ Re-cargar TODO el proyecto (desperdicio de tokens — usar fetches
  selectivos).
- ❌ Pedirle al usuario que repita el contexto que YA estaba en el turno
  anterior (rompe la ilusión de continuidad).
- ❌ Omitir el re-anclaje y continuar "como si nada" (causa alucinaciones
  sobre decisiones que ya se tomaron).

### Cuándo NO aplicar

| # | Caso | Razón de NO aplicar | Acción alternativa |
|---|------|---------------------|--------------------|
| 1 | NO hay marcadores de compresión en el system prompt ni en el contexto reciente. | No hay compresión real que recuperar. | Proceder normalmente con Fase 1. |
| 2 | El resumen provino de un `clear` o reinicio de sesión **solicitado por el usuario** (no es compresión automática). | El usuario quiere un nuevo inicio deliberado; re-anclar arrastra información que él descartó. | Tratar como tarea nueva: ejecutar Fase 1 desde cero. |
| 3 | La compresión ocurrió en un sub-agente (`swarm_spawn_mode`) y el contexto perdido es del CHILD, no del COORDINATOR. | El coordinator no tiene visibilidad del child context; re-fetch selectivo del coordinator es inútil. | Pedir al child un "context dump" o un `report` formal con su estado. |
| 4 | El usuario pidió explícitamente "olvida lo anterior" o "asume que no sabes nada". | Es un override humano deliberado; respetarlo. | Confirmar disponibilidad de re-fetch selectivo si el usuario lo pide después, pero no hacerlo proactivamente. |

---

## CHECKPOINTS — Mecanismo de seguridad de flujo (NUEVO)

**Regla absoluta**: ningún flujo se cierra si sus checkpoints no pasan.

### Checkpoint F0 — Estado del proyecto

```bash
# Antes de cualquier tarea, verificar bootstrap
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --json > /tmp/orient_f0.json
EMPTY=$(python3 -c "import json; d=json.load(open('/tmp/orient_f0.json')); print(d.get('scanner',{}).get('state',''))")
if [[ "$EMPTY" == "empty" ]]; then
  echo "❌ Proyecto sin bootstrap. Ejecutar bootstrap_all.py --apply primero."
  exit 1
fi
```

### Checkpoint F1 — HF Gate (para SLICE/REMEDIATION/PHASE-CLOSE)

```bash
bash .jcode/tests/audit/verify_hidden_failure_gate.sh && \
bash .jcode/tests/audit/verify_hidden_failure_gate_independiente.sh
[[ $? -ne 0 ]] && exit 1  # abortar
```

### Checkpoint F2 — Effort routing

```bash
python3 -c "
import tomllib, os
c = tomllib.loads(open('.jcode/config.toml','rb').read())
tc = os.environ.get('TASK_CLASS', 'MICROFIX')
print(f'  effort={c[\"policy\"][\"effort_routing\"][tc]}')
"
```

### Checkpoint F3 — Evidence bundle

```bash
bash .jcode/lib/evidence_bundle.sh "${LOOP_ID:-L-UNKNOWN}"
# Verificar que el verdict no sea INCOMPLETE
```

### Checkpoint F4 — Self-critique

```bash
# Re-leer el último output contra la petición original
# Marcar en compliance.json
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
# Si task_class ∈ {SLICE, REMEDIATION, PHASE-CLOSE}, requerir reviewer
case "$TASK_CLASS" in
  SLICE|REMEDIATION|PHASE-CLOSE)
    python3 -c "
import json, pathlib
p = pathlib.Path('.jcode/state/compliance.json')
c = json.loads(p.read_text()) if p.exists() else {}
c['reviewer_required'] = True
p.write_text(json.dumps(c, indent=2))
print('Reviewer spawn required')
"
    ;;
esac
```

### Anti-patrón general

- ❌ Usar Flujo Riguroso para un MICROFIX (desperdicio de tokens y tiempo).
- ❌ Usar Flujo Ligero para un SLICE (omite acoplamiento y causa bugs).
- ❌ Omitir la Fase 3 (rompe trazabilidad).
- ❌ Clasificar como MICROFIX "para ser eficiente" cuando el árbol de
  decisión indica SLICE (sesgo de optimización prematura).
- ❌ Omitir el paso "Verificación mínima" de Fase 2-A (1 lectura de
  control basta para evitar fixes tontos).
- ❌ Promover MICROFIX a SLICE y seguir tratando el trabajo como ligero
  (la promoción invalida el plan original).
- ❌ Confundir "NO hay marcadores de compresión" con "tarea fuera del
  sprint activo" — son cosas distintas: la primera NO activa Fase 4, la
  segunda SÍ puede requerir re-anclaje.
- ❌ **Cerrar tarea sin pasar F1 (HF Gate)** — viola FAILURE-PATTERNS §2.
- ❌ **Cerrar tarea sin pasar F3 (Evidence bundle)** — viola FAILURE-PATTERNS §4.
- ❌ **Cerrar tarea sin F4 (Self-critique)** — viola quality-preamble §2.
- ❌ **SLICE/REM sin F5 (Reviewer)** — viola quality-preamble §4.

---

## INTEGRACIÓN DE FASES (matriz de decisión final)

```text
¿Recibí tarea nueva?
├─ NO → ¿Detecté marcadores de compresión? → SÍ → ejecutar Fase 4.
│                                        └─ NO → idle (esperar).
└─ SÍ → CHECKPOINT F0 (proyecto bootstrap-eado)
         ├─ FAIL → ejecutar bootstrap_all.py --apply primero
         └─ PASS → Fase 1 (árbol de decisión)
                  ├─ MICROFIX → Fase 2-A + F1 (HF Gate MICROFIX) + Fase 3.
                  ├─ SLICE   → Fase 2-B + F1 + F2 + F3 + F4 + F5 + Fase 3.
                  └─ REMEDIATION → Fase 2-C + F1 + F3 + Fase 3.
```

Toda tarea (sin importar tamaño) que complete su flujo debe haber:

1. ✅ Pasado el checkpoint F0 (proyecto bootstrap-eado)
2. ✅ Pasado los checkpoints F1-F5 según task_class
3. ✅ Dejado **al menos 1 línea** en `PLAN-VIVO §6`
4. ✅ Score de compliance ≥ 80 (via `harness.sh status`)

Si falla cualquiera de las 4 condiciones, **abortar y re-orientar**.

---

## INTEGRACIÓN CON SKILLS OBLIGATORIAS

| Skill | Cuándo invocar |
|-------|----------------|
| `arquitecto-proyecto` | Decisión de modelo de datos o API |
| `worker-ejecutor` | Implementación en src/ |
| `reviewer-calidad` | CHECKPOINT F5 (reviewer spawn) |
| `guardrails` | Cuando CHECKPOINT F1 detecta violation |
| `bootstrap-proyecto` | CHECKPOINT F0 (proyecto sin bootstrap) |

---

## Diferencia con versión anterior

Esta versión (v101.3-orient-checkpoints) corrige la desactualización detectada en
`ANALISIS-COMPARATIVO.md`. Cambios principales vs v100-clean:

1. **5 preguntas en lugar de 4** (P5: ¿test independiente presente?)
2. **Fase 0 nueva**: CHECKPOINT de estado del proyecto
3. **Fase 2-C nueva**: Flujo REMEDIATION con iteration logs
4. **5 CHECKPOINTS nuevos** (F0-F5) como mecanismo de seguridad de flujo
5. **Validación de cierre** (compliance ≥ 80, líneas en PLAN-VIVO)
6. **Anti-patrones nuevos** para HF Gate, evidence bundle, self-critique, reviewer

Sin estos cambios, la skill orient guiaba al agente a cerrar tareas sin pasar
por los 5 mecanismos de seguridad que el resto del harness ya implementa.

---

## Compatibilidad con PRINCIPLES.md

Esta skill implementa operativamente los principios:

- §3 SRSI — `grep` antes de fix en Fase 2-A
- §4 DDLP — Plan desde PLAN-VIVO en Fase 1
- §7 R-VERIFY-BEFORE-CLAIM — CHECKPOINT F1 (HF Gate) y F4 (self-critique)
- §8 R-INDEPENDENT-TEST — CHECKPOINT F1 (independiente obligatorio)
- §9 R-ITERATION-LOG — Fase 2-C exige logs
- §11 R-REGRESSION-BEFORE-MERGE — Validación de cierre con `run_all.sh`
- §13 R-HIDDEN-FAILURE-CATALOG — 6 checkpoints como ejecutables
- §14 R-FRONTIER-QUALITY — Self-critique + reviewer + evidence bundle
