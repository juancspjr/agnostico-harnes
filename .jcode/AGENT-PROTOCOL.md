---
type: RULE
importance: C
version: 100-clean.template
date: 2026-07-21
title: AGENT-PROTOCOL — Checklist por turno (agnóstico)
---

# AGENT-PROTOCOL — Ley operacional del agente por turno

> **Canónico operacional**: este archivo es **la** checklist que el agente
> DEBE seguir cada turno. `AGENTS.md` (raíz) es constitución del proyecto;
> `PRINCIPLES.md` es ley filosófica; este archivo es **la acción concreta**.

---

## §0 Lectura mínima obligatoria por turno (SRSI)

| Documento | Cuándo leer | Líneas |
|---|---|---|
| `AGENTS.md` (raíz) §1 | Siempre al iniciar sesión | ~80 |
| `PDR.md` (raíz) | Cambia alcance o features | según |
| `PROJECT.md` (raíz) §1-§5 | Cambia dominio o reglas de negocio | según |
| `.jcode/iterations/PLAN-VIVO.md` §1-§2 | Siempre al iniciar sesión | ≤100 |
| `.jcode/INTERPRETACION.md` §1-§2 | **Antes de tocar código** | ~60 |
| `.jcode/AGENT-PROTOCOL.md` (este) | Siempre al iniciar turno | este |
| `.jcode/PRINCIPLES.md` PARTE II | Solo si tarea es de loops | ~150 |
| `.jcode/INCIDENT-PROTOCOLS.md` | Solo si hubo bloqueo de guardrail | bajo demanda |

**Prohibido**: leer `archive/` entero, `PLAN-VIVO` histórico, o `INDEX.md`
salvo búsqueda específica con `grep`.

---

## §1 Checklist por turno — 11 items

### Paso 0 — Interpretación (INTERPRETACION.md §1)

- [ ] **0. INTERPRETAR**: leí `INTERPRETACION.md §1` y determiné:
  - `task_type: <rule-change|feature|bugfix|review|audit|plan|ux>`
  - `skills_needed: <de la tabla §2>`
  - `mcps_needed: <de la tabla §2>`

### Antes de CUALQUIER fix

- [ ] **1. SRSI**: ejecuté `grep -n '<patrón>' <dir>` sobre el cambio
  - Si grep no retorna matches antes del fix y retorna >0 después → `srsi_done_this_turn=true`
- [ ] **2. DDLP**: leí `PLAN-VIVO.md §2` (backlog) y `§3` (próximo paso) ¿el cambio cierra algo? Si sí → `ddlp_done=true`
- [ ] **3. STRIKE COUNT**: si llevo 2 strikes en el mismo dominio sin cambiar método → activar R-3STRIKE-MVP (PRINCIPLES §1)

### Durante el fix (commit atómico)

- [ ] **4. SCOPE MÍNIMO**: el commit toca SOLO lo necesario (un bug por commit). Si toca >5 archivos → justificar en `PLAN-VIVO §6`
- [ ] **5. BACKEND ↔ FRONTEND**: si cambio backend, ¿cambié frontend equivalente? grep ambos lados
- [ ] **5.5. CROSS-CHECK consumidores (R-CROSS-CHECK)**: si renombré / moví / eliminé un campo en backend (DTO, modelo, servicio, DB), ANTES de declarar fixed_check:
  - `grep -rn '<nombre_nuevo>' frontend/src/` → debe retornar ≥ 1 match por consumidor.
  - `grep -rn '<nombre_viejo>' frontend/src/` → debe retornar **0** matches (no quedaron remanentes).
  - Si hay consumidores desincronizados → **STOP**, no declarar listo. Abrir fix separado en `PLAN-VIVO §6`.
- [ ] **5.6. AUTOJUDGE**: si el cambio toca reglas de dominio, declarar `autojudge_scopes` en `compliance.json`

### Después del fix

- [ ] **6. ACTUALIZAR PLAN-VIVO §6**: cada bug o cambio mayor deja rastro
- [ ] **7. VERIFICACIÓN EJECUTADA**: corrí `fixed_check` del loop actual y pasó
- [ ] **8. ACTUALIZAR MAPAS**: si el commit tocó un modelo de datos (DB, DTO, servicio), actualizar `STATE-REGISTERS.md`. Si introdujo nueva feature o fix con efecto observable, agregar entrada a `BEHAVIOR-INDEX.md`.

### Al cerrar sesión

- [ ] **9. HANDOFF**: ajustar `PLAN-VIVO §8` con el próximo loop planeado
- [ ] **10. CERRAR SESIÓN**: ajustar `PLAN-VIVO §5` cronología + versiones
- [ ] **11. FRAGMENTACIÓN ATÓMICA**: si la respuesta fue bloqueada por guardrail → ver `INCIDENT-PROTOCOLS.md` (NO cambiar proveedor, NO simplificar)

---

## §2 Lo que NO se puede omitir

| Omisión | Detección | Consecuencia |
|---|---|---|
| SRSI antes de fix | `posttool.sh` E4 | strike auto-ajustado |
| Ajustar §6 sin commit | `turnend.sh` | Compliance -10 |
| Handoff al cerrar | `turnend.sh` | Bloquea siguiente loop |
| 3 strikes mismo bug | manual | activar R-3STRIKE-MVP |
| Migración sin idempotencia | crash en re-run | |
| No registrar bloqueo guardrail | manual en §14 | R-AA-2 strike |
| Cambiar proveedor por guardrail | manual | R-AA-3 strike + reversión |
| **Simular swarm con scripts bash** | `guardrails` audit | R-NO-FAKE-SWARM strike |

---

## §3 Comandos canónicos

```bash
# Estado del arnés (instantáneo, sin side effects)
bash .jcode/lib/harness.sh status
bash .jcode/lib/harness.sh check        # Auditoría agnóstica
bash .jcode/lib/harness.sh focus        # Alerta de enfoque

# Ajustar compliance
python3 -c "import json;p='.jcode/state/compliance.json';c=json.load(open(p));c['srsi_done_this_turn']=True;json.dump(c,open(p,'w'),indent=2)"

# Cerrar sesión
bash .jcode/lib/state_manager.sh closeout    # Solo ajusta si pasan checks
```

---

## §4 Sub-agentes — USAR jcode NATIVO

**Prohibido**: scripts bash que llamen `jcode debug --socket ... create_session`.

**Forma correcta**:

### En TUI interactivo (jcode nativo)

1. `jcode` en terminal
2. `Ctrl+N` → spawn prompt (escribir rol + tarea)
3. `Ctrl+O` → listar agentes activos (verás sus progresos)
4. Coordinator cierra el swarm leyendo outputs

### En sesión headless

Declarar en `.jcode/config.toml`:
```toml
[agents]
swarm_spawn_mode = "auto"
```

jcode decide cuándo spawnear workers según el loop. El coordinador solo
coordina (no spawnea manualmente).

### Si el runtime NO soporta swarm

Declarar la limitación explícitamente en `PLAN-VIVO §8`:
```
- limitation: "runtime no soporta swarm, trabajando single-agent"
- impact: "no paralelizable, budget ×2 para compensar"
```

**No** crear "fake swarm" con scripts bash. Esto rompe tracking, confunde
al usuario, y produce agentes que "completan" sin hacer nada.

---

## §4.5 Reglas de spawn (optimización de sub-agentes)

| Situación | Acción |
|-----------|--------|
| Tarea en 1-2 archivos, < 30 min | Trabajar inline. **NO spawnear** |
| Tarea en 3+ archivos independientes | Máximo 3 sub-agentes simultáneos |
| Micro-fix (< 5 líneas) | Inline directo. Tampoco spawn |
| Contexto del sub-agente | Pasar SOLO: `task_type`, archivos, checkpoint esperado |

**NO pasar**: AGENTS.md entero, PLAN-VIVO entero, PROJECT.md entero al spawnear.

## §4.7 Triggers obligatorios por tipo de tarea

> **Disciplina**: cada loop declara qué skill/rol invoca primero.
> **NO** se ejecuta inline sin chequear esta tabla.

| Tipo de cambio | Skill/sub-agente obligatorio | Cómo invocar |
|---|---|---|
| Decisión de diseño / modelo / API | `arquitecto-proyecto` (sk arnés) | swarm spawn con prompt = "Revisar diseño X contra PROJECT.md" |
| Implementación (tocar *.go, *.ts, *.astro) | `worker-ejecutor` (sk arnés) | swarm spawn, scope = path exacto |
| Cierre de loop / claim "listo" | `reviewer-calidad` (sk arnés) | swarm spawn, fixed_check como prompt |
| UI nueva / pantalla / wizard | `frontend-design` (.agents/sk) | skill invocation inline |
| Cambio que afecte journey cliente | `customer-journey-map` (.agents/sk) | skill invocation inline |
| Diseño de flujo multi-paso / navegación | `journey` (.agents/sk) | skill invocation inline |
| Cruzar regla R-N / ajuste agnóstico | `guardrails` (sk arnés) | swarm spawn con diff + R-N afectado |

**Bypass inline** permitido SOLO si: la tarea es < 30 min, 1-2 archivos,
y NO toca diseño/journey/UI. Documentar en PLAN-VIVO §8.

---

## §5 Compatibilidad entre reglas

| Regla | Lugar | Cuándo | Cómo ajustar |
|---|---|---|---|
| R-3STRIKE-MVP | PRINCIPLES §1 | Repetir fallo 2 veces | `state_record_strike` |
| SRSI | Este §1 item 1 | Antes de cada fix | `posttool.sh` auto |
| DDLP | Este §1 item 2 | Inicio de sprint | manual |
| TPSP | PRINCIPLES §5 | Ajustar plano mayor | manual |
| R-DOS-PLANOS | PRINCIPLES §5 | Cliente pide algo nuevo | manual |
| R-AA-1 | PRINCIPLES glosario | Asumir fix sin verificar | `posttool.sh` auto |
| R-NO-FAKE-SWARM | PRINCIPLES §6 | Swarm | guardrails audit |

---

## §6 Compliance events (autos vs manuales)

**Automáticos** (hooks):

| Evento | Hook | Campo compliance |
|---|---|---|
| `git commit` sin grep en últimos 5 min | `posttool.sh` E4 | `aa1_violations[]` |
| SRSI hecho (grep con resultado) | `posttool.sh` E4b | `srsi_done_this_turn=true` |
| closeout_check pasa | `turnend.sh` | `closeout_passed=true` |
| Cada tool call | `posttool.sh` | `reads_this_turn++` |

**Manuales** (declarados por agente):

| Evento | Campo |
|---|---|
| DDLP hecho | `ddlp_done=true` |
| Strike ajustado | `r_aa_1_strikes += 1` |
| R-3STRIKE-MVP activado | `r_3strike_mvp_activations += 1` |
| Handoff escrito | `handoff_written=true` |
| Swarm spawn | `last_swarm_spawn_turn` + `last_swarm_role` + `swarm_spawn_count_session++` |

---

## Versión

- **v100-clean.template** (2026-07-21): Versión agnóstica del checklist
  por turno. Aplicable a cualquier stack o dominio. Lista para usar
  en cualquier proyecto nuevo.