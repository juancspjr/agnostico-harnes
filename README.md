# Proyecto Nuevo — Punto de Partida

> **Este es un repo NUEVO**. Contiene la constitución (`AGENTS.md`),
> el spec del dominio (`PROJECT.md`), el PDR (`PDR.md`), y el arnés
> agnóstico (`.jcode/`). Antes de empezar a codear, **lee los
> documentos en este orden** y reemplaza los placeholders con valores
> reales del proyecto.

---

## 🚦 Estado actual del repo

```
proyecto-01/
├── AGENTS.md                         ← Plantilla genérica (con placeholders)
├── PROJECT.md                        ← Plantilla genérica (con placeholders)
├── PDR.md                            ← Plantilla genérica (con placeholders)
├── README.md                         ← Este archivo (guía de arranque)
├── HANDOFF-INICIO-SESION.md          ← Para el próximo agente
│
├── .jcode/                           ← Arnés agnóstico v100-clean
│   ├── README.md                     ← Mapa del arnés
│   ├── PRINCIPLES.md                 ← Ley operativa
│   ├── AGENT-PROTOCOL.md             ← Checklist por turno
│   ├── LOOPS.md                      ← Catálogo de loops
│   ├── INTERPRETACION.md             ← Capa de decisión pre-código
│   ├── INCIDENT-PROTOCOLS.md         ← Protocolos raros
│   ├── STATE-REGISTERS.md            ← Plantilla para mapa de estados
│   ├── BEHAVIOR-INDEX.md             ← Plantilla para mapa de comportamientos
│   ├── shadcn-ui-guide.md            ← Plantilla para shadcn/ui
│   ├── config.toml                   ← Política ejecutable (ajustar)
│   ├── mcp.json                      ← MCPs (ajustar path filesystem)
│   │
│   ├── hooks/                        ← 4 hooks bash
│   ├── lib/                          ← Estado + commands + dispatcher
│   ├── skills/                       ← 8 skills del arnés
│   ├── templates/                    ← OP, STATE, PDR
│   ├── iterations/                   ← Plan vivo + archive + subcarpetas
│   ├── state/                        ← compliance.json (auto-generado)
│   ├── logs/                         ← Auto-generado por hooks
│   ├── tests/                        ← Smoke + diagnostics + audit + measure
│   └── visualizer/                   ← Debug visual en tiempo real
│
├── src/                              ← (vacío — donde va tu código)
└── bin/                              ← (vacío — scripts del proyecto)
```

---

## 🎯 Para el ingeniero de software / agente: 5 pasos para empezar

### Paso 1 — Leer la documentación canónica

En este orden estricto:

1. **`AGENTS.md`** (~340 líneas) — Constitución del proyecto. Reemplaza
   todos los `<placeholders>` con datos reales.
2. **`PDR.md`** (~330 líneas) — Requisitos del producto. Define QUÉ
   construir y POR QUÉ.
3. **`PROJECT.md`** (~240 líneas) — Spec del dominio. Reglas de
   negocio, modelo de datos, ADRs.
4. **`.jcode/README.md`** (~150 líneas) — Mapa del arnés.
5. **`.jcode/AGENT-PROTOCOL.md`** (~220 líneas) — Checklist por turno.

> **Token load frío**: ~1.300 líneas = ~5K tokens. Optimizado para
> jcode que arranca con contexto limitado.

### Paso 2 — Configurar el arnés

```bash
# 1. Editar config.toml — ajustar [project] y [workspace]
vim .jcode/config.toml

# 2. Editar mcp.json — filesystem.args debe apuntar a ESTE repo
#    (reemplazar ${PROJECT_ROOT} por el path absoluto real)
vim .jcode/mcp.json

# 3. Editar contamination_patterns.txt — agregar el nombre del proyecto
#    para que el detector lo encuentre si por error se filtra
vim .jcode/lib/contamination_patterns.txt

# 4. Inicializar el arnés (crea state/compliance.json + integridad check)
bash .jcode/lib/harness.sh init

# 5. Verificar que no hay contaminación
bash .jcode/lib/harness.sh check
# Esperado: 0 contaminación detectada
```

### Paso 3 — Llenar las plantillas en orden

```
[ ] PDR.md §1-§13          (requisitos del producto)
[ ] AGENTS.md §1-§12       (constitución, identidad, stack)
[ ] PROJECT.md §1-§9       (spec del dominio)
[ ] .jcode/STATE-REGISTERS.md   (mapa de estados, por cada campo crítico)
[ ] .jcode/BEHAVIOR-INDEX.md    (mapa de comportamientos, B-001 en adelante)
[ ] .jcode/iterations/PLAN-VIVO.md  (estado actual + sprint activo + handoff)
```

### Paso 4 — Primer commit

```bash
git init
git add .
git commit -m "chore(init): constitución del proyecto + arnés bootstrap"
```

> Antes del primer commit, verificar:
> - `bash .jcode/lib/harness.sh check` → 0 contaminación
> - `bash .jcode/lib/harness.sh status` → todo verde
> - No quedan `<placeholders>` en `AGENTS.md`, `PROJECT.md` ni `PDR.md`

### Paso 5 — Iniciar el primer sprint

```bash
# Editar PLAN-VIVO.md §7 (Sprint actual) y §8 (Sesión actual)
vim .jcode/iterations/PLAN-VIVO.md

# Declarar el primer loop
python3 .jcode/lib/state_manager.sh set-loop L-SLICE-001 <budget>

# Empezar a codear
```

---

## 📂 Estructura de directorios canónica

### Raíz del proyecto

| Archivo | Propósito | Quién lo mantiene |
|---|---|---|
| `AGENTS.md` | Constitución del proyecto | Arquitecto |
| `PROJECT.md` | Spec del dominio | Arquitecto |
| `PDR.md` | Requisitos del producto | Product Owner |
| `README.md` | Onboarding rápido | Arquitecto |
| `HANDOFF-INICIO-SESION.md` | Handoff al próximo agente | Agente activo |

### `.jcode/`

| Carpeta | Propósito |
|---|---|
| `hooks/` | Bash hooks ejecutados por jcode (sessionstart, turn_start, posttool, turnend) |
| `lib/` | Librerías del arnés (state_manager, harness, dispatcher) |
| `skills/` | Skills cargadas según task_type (orient, worker, arquitecto, reviewer, guardrails) |
| `templates/` | Plantillas para iteraciones (OP, STATE, PDR) |
| `iterations/` | Plan vivo + subcarpetas (ARCH, REM, REV, PLAN, OP, STATE) + archive |
| `state/` | `compliance.json` (auto-generado por state_manager.sh) |
| `logs/` | Logs de hooks (auto-generado) |
| `tests/` | Centro de tests + evidencia |
| `visualizer/` | Debug visual en tiempo real (D3 graph) |

---

## 🔄 Cómo el arnés trabaja

### Ciclo de vida de un loop

```
1. INTERPRETAR  →  .jcode/INTERPRETACION.md §1
       ↓ (task_type + skills + MCPs)
2. PLANEAR      →  declarar loop en .jcode/iterations/PLAN-VIVO.md §8
       ↓
3. EJECUTAR     →  spawnear worker (o inline si < 30 min)
       ↓
4. VERIFICAR    →  fixed_check (comando reproducible)
       ↓
5. CERRAR       →  actualizar PLAN-VIVO §6 (bugs/cambios) + §8 (handoff)
```

### Compliance score (0-100)

| Componente | Peso | Cómo se gana |
|---|---|---|
| `reads_this_turn` | 15 | Hacer ≥3 lecturas por turno |
| `cumulative_reads` | 15 | Tener lecturas acumuladas |
| `drill_done_this_turn` | 15 | Drillar en el problema |
| `srsi_done_this_turn` | 15 | Hacer grep antes de fix |
| `ddlp_done` | 10 | Planear desde gaps del PLAN-VIVO |
| `r3s` | 10 | 0 strikes = 10, 1-2 = 5, 3+ = 0 |
| `handoff_written` | 10 | Escribir handoff al cerrar sesión |
| `clean` | 10 | Sin violaciones R-AA-1 |

> **Score mínimo para cerrar sesión**: 80/100.

---

## 🚫 Reglas críticas que NO se pueden violar

1. **Cero contaminación**: el arnés (`.jcode/`) NO debe contener paths
   absolutos del entorno, ni nombres de proyecto, ni credenciales.
   Detector: `bash .jcode/lib/harness.sh check`.

2. **SRSI antes de fix**: ejecutar `grep` antes de cualquier cambio.
   Detector: hook `posttool.sh`.

3. **Handoff al cerrar sesión**: actualizar `PLAN-VIVO.md §8` antes de
   que termine el turno. Detector: hook `turnend.sh`.

4. **No simular swarm**: usar el swarm nativo de jcode (`Ctrl+N` o
   `swarm_spawn_mode = "auto"`). Detector: `guardrails` audit.

5. **No cambiar proveedor LLM por bloqueo de guardrail**: fragmentar
   en su lugar. Ver `INCIDENT-PROTOCOLS.md §A R-FRAGMENT-ATOMIC`.

6. **Verificación antes de claim "listo"**: ejecutar `fixed_check` del
   loop y mostrar resultado. Sin verificación, no es válido.

---

## 📚 Recursos adicionales

- **Mapa del arnés**: `.jcode/README.md`
- **Ley operativa**: `.jcode/PRINCIPLES.md` + `.jcode/AGENT-PROTOCOL.md`
- **Catálogo de loops**: `.jcode/LOOPS.md`
- **Decisión pre-código**: `.jcode/INTERPRETACION.md`
- **Protocolos raros**: `.jcode/INCIDENT-PROTOCOLS.md` (bajo demanda)
- **Handoff al próximo agente**: `HANDOFF-INICIO-SESION.md`

---

## ✅ Checklist de inicio del proyecto

```
[ ] Leí AGENTS.md, PROJECT.md, PDR.md en ese orden
[ ] Reemplacé todos los <placeholders> con datos reales
[ ] Edité .jcode/config.toml con [project] y [workspace] reales
[ ] Edité .jcode/mcp.json con filesystem path absoluto
[ ] Edité .jcode/lib/contamination_patterns.txt
[ ] Corrí bash .jcode/lib/harness.sh init
[ ] Corrí bash .jcode/lib/harness.sh check (0 contaminación)
[ ] Llené .jcode/STATE-REGISTERS.md
[ ] Llené .jcode/BEHAVIOR-INDEX.md
[ ] Llené .jcode/iterations/PLAN-VIVO.md §2, §3, §7, §8
[ ] Primer commit con bootstrap
[ ] Primer loop declarado en PLAN-VIVO §8
[ ] Primer turn_start ejecutado
[ ] Primer SRSI + DDLP realizados
[ ] Primer handoff escrito al cerrar sesión

Si todo ✓ → el proyecto está listo para sprints reales.
```

---

## 📊 Paper-Compliant Bootstrap (2026-07-21)

> **Estado**: ✅ 5 fases implementadas con gates pasados.
> Cumple el paper *Harness Handbook* (arXiv:2607.13285v1) en sus 3 pilares.

### Los 3 pilares del paper implementados

| Pilar | Componente | Estado |
|---|---|---|
| **P1: Construction Pipeline** | `handbook_builder.py` + `handbook_phase2.py` + `handbook_phase3.py` | ✅ 12 funcs, 11 L3 entries, 6 state registers, 0 frozen |
| **P2: Resync automático** | `handbook_resync.py` + hook en `turnend.sh` | ✅ Auto-ejecutado tras commit reciente |
| **P3: BGPD verification** | `handbook_verify.py` + skill `handbook/SKILL.md` + paso VERIFY en `orient/` | ✅ 11 sites verificados (sin request filter) |

### Resultados de los gates

| Gate | Resultado |
|---|---|
| FASE 0 — baseline | ✅ `harness.sh check` retorna 0 contaminación |
| FASE 1 — C-01 + H-01 + H-02 | ✅ 9 tests pasan |
| FASE 2 — Construction Pipeline | ✅ overview.md + index.md + registers.md + 6 stage pages + K_g.json + cache_B.json + frozen_entries.json |
| FASE 3 — Resync | ✅ `handbook_resync.py --auto` ejecutable, hook en turnend.sh |
| FASE 4 — BGPD | ✅ `handbook_verify.py` retorna 11 verified (sin request) |
| FASE 5 — Edit Planning Γ + smoke_paper_compliance | ✅ 10 tests pasan, OP.md con will_modify/add/remove |

### Cómo usar el handbook

```bash
# Generar handbook inicial (después de llenar PROJECT.md/AGENTS.md/PDR.md)
python3 .jcode/lib/handbook_builder.py --repo .
python3 .jcode/lib/handbook_phase2.py
python3 .jcode/lib/handbook_phase3.py

# Verificar sites relevantes a un cambio
python3 .jcode/lib/handbook_verify.py --request "auth login flow"

# Resync después de commits (auto via turnend.sh)
python3 .jcode/lib/handbook_resync.py --auto
```

### Ramas y commits

```
feat/paper-compliant-bootstrap:
  b11b735 feat(harness): paper-compliant bootstrap completo
  d9800b7 feat(harness): paper pilar 3 — BGPD con source verification
  33783e8 feat(harness): paper pilar 2 — resync automático post-commit
  536c2b9 feat(harness): paper pilar 1 — construction pipeline Phase I/II/III
  d87450d fix(harness): C-01 tests + H-01 regex + H-02 config extensions
  bcd9984 chore: snapshot baseline antes de paper-compliant bootstrap
```

---

## Dependencias

### Opcionales (LLM para Phase II)

Para clasificación de funciones con LLM real en Phase II (`handbook_phase2.py`), instalar:

```bash
pip install z-ai-web-dev-sdk
```

Sin este SDK, Phase II usa heurística de análisis de código fuente (`_classify_with_heuristic`). La heurística distribuye funciones en 6 stages (init, interpret, plan, execute, verify, handoff) con un warning visible al inicio de cada ejecución.

---

## Versión

- **v002-paper-compliant** (2026-07-21): Bootstrap inicial del repo nuevo +
  arnés paper-compliant (3 pilares del paper Harness Handbook implementados).
  10 tests pasan (9 audit + 1 paper-compliance). 0 contaminación.
- **v001-bootstrap** (2026-07-21): Bootstrap inicial del repo nuevo.
  Basado en el arnés v100-clean migrado desde Will-Cel.