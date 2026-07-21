# CAPA DE INTERPRETACIÓN — Coordinador Dinámico

> **Léeme antes de tocar código.** Determina QUÉ leer, QUÉ skills cargar,
> y QUÉ MCPs activar según el tipo de tarea.

---

## §1 Decisión Preliminar (3 preguntas, obligatorio)

Antes de cualquier acción, responder:

1. **¿Cambia regla de negocio, entidad, estado, permiso?**
   - Si → Update **PROJECT.md** primero
   - No → Solo código o PLAN-VIVO

2. **¿Cambia orden de tareas, scope, prioridad?**
   - Si → Update **PLAN-VIVO** primero
   - No → Solo código

3. **¿Es bug, feature, review, o auditoría?**
   - → Determina `task_type` (ver §2)

> **Output**: 3-5 líneas al recibir cada solicitud. Nada más.

---

## §2 Task Type → Contexto + Skills + MCPs

| `task_type` | Lee (máx 150L c/u) | Skills | MCPs |
|---|---|---|---|
| `rule-change` | PROJECT.md §3-4 | arquitecto, guardrails | filesystem |
| `feature` | PROJECT.md §5 + PLAN-VIVO §1-2 | worker, reviewer | filesystem, playwright |
| `bugfix` | PLAN-VIVO §2 + `grep <código>` | worker | filesystem |
| `review` | LOOPS.md + `grep <patrón>` | reviewer-calidad | filesystem |
| `audit` | LOOPS.md + `grep <patrón>` | guardrails | filesystem |
| `plan` | AGENTS.md §1 + PLAN-VIVO §1 | arquitecto | filesystem |
| `ux` | AGENTS.md + PLAN-VIVO §1 | ux-designer | filesystem, playwright |

### Reglas

- Cargar **SOLO** lo necesario. No leer archivos completos si `grep` alcanza.
- Skills: máximo 2 por tarea (1 ejecutor + 1 reviewer) — salvo planificación que usa 3.
- MCPs: máximo 3. Si no necesitas Playwright, no lo cargues.
- Si `task_type` es nuevo → crear entrada aquí.

---

## §3 Task Type → Búsqueda Precisa

| `task_type` | Estrategia de búsqueda |
|---|---|
| `rule-change` | `grep -n "R-N" PROJECT.md \| head -5` + `grep -n "entidad\|estado\|permiso" PROJECT.md` |
| `feature` | `grep -n "endpoint\|handler\|migration" PROJECT.md §5` + `grep -rn "func.*Handler" backend/handlers/` |
| `bugfix` | `grep -rn "<síntoma>" backend/ frontend/` + `grep -rn "<variable>"` para rastrear cadena |
| `review` | `grep -rn "TODO\|FIXME" backend/ frontend/` + `grep -rn "RequireAdmin\|requiredRoles"` |
| `audit` | `grep -rn "hardcod\|TODO\|FIXME" .` + `grep -rn "RequireAdmin\|admin:"` |
| `plan` | `ls -R backend/handlers/ frontend/src/` + `grep -n "task_class\|loop_id"` en LOOPS.md |
| `ux` | `browser_snapshot` + `grep -rn "className\|style\|disabled"` en componentes target |

---

## §4 Antes de spawnear sub-agentes

1. **¿La tarea requiere paralelismo real?** (2+ archivos independientes, sin shared state)
   - No → Trabajar single-agent
   - Si → Máximo 3 sub-agentes simultáneos

2. **¿Es micro-tarea (< 5 archivos, < 30 min)?**
   - No spawnear sub-agentes. Hacerlo inline.
   - Regla: si puedes explicar la tarea en < 3 líneas, no vale la pena.

3. **¿El sub-agente tiene contexto suficiente?**
   - Pasar SOLO: `task_type`, archivos a tocar, checkpoint esperado
   - NO pasar: AGENTS.md entero, PLAN-VIVO entero, PROJECT.md entero

---

## §5 Cost Estimates (aproximado)

| Operación | Tokens estimados | Costo |
|-----------|-----------------|-------|
| Leer PLAN-VIVO (89L actual) | ~400 | ✅ |
| Leer PROJECT.md entero | ~2.5K | ⚠️ medio |
| Spawn 1 sub-agente con contexto mínimo | ~1K | ✅ |
| Spawn 3 sub-agentes simultáneos | ~3K | ⚠️ medio |
| grep sobre archive/ (histórico) | ~500 | ✅ |
| Leer archive entero (3846L) | ~13K | ❌ alto — solo grep |
| build backend + frontend | ~500 | ✅ |
| playwright screenshot | ~1K | ✅ |
| Review con triple evidencia | ~4K | ⚠️ medio |

**Máximo presupuesto por sesión**: ~25K tokens de contexto frío.
Si una operación requiere más → fragmentar en 2 sesiones.

---

## §6 Documentación afectada por cambios

| Si el cambio toca... | Actualizar |
|----------------------|-----------|
| Nueva entidad, estado, regla (R-N) | **PROJECT.md** §3-4 |
| Nuevo endpoint, flujo | **PROJECT.md** §5 |
| Nuevo permiso, rol | **AGENTS.md** §6 |
| Bug o feature (sin cambio de dominio) | **PLAN-VIVO** §1-2 |
| Arquitectura del arnés | **INTERPRETACION.md** + **README.md** |
