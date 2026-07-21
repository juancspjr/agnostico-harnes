---
type: HARNESS-MAP
version: 101.4-orient-checkpoints
date: 2026-07-21
title: Arnés JCode — Paper-Compliant + Bootstrap Adaptativo + Orient v101.4
---

# Arnés JCode — Mapa del Arnés (v101.4-orient-checkpoints)

> **Filosofía**: este arnés es **agnóstico al dominio**. Cero paths de proyecto,
> cero contraseñas, cero reglas de negocio. Toda la mecánica operativa portable
> vive aquí; toda la lógica del dominio vive en `AGENTS.md`, `PROJECT.md` y
> `PDR.md` **en la raíz del proyecto**.
>
> El arnés es el motor; el proyecto es la gasolina.

---

## Regla de oro — separación

| Pregunta | Respuesta |
|---|---|
| ¿Esto define CÓMO trabaja el agente (loops, strikes, scoring)? | → vive en `.jcode/` |
| ¿Esto define QUÉ es el proyecto (reglas de negocio, stack, DB)? | → vive en raíz del repo |
| ¿Tiene un path absoluto `/home/...` o un nombre de proyecto? | → NO debe estar en `.jcode/` |
| ¿Contiene contraseñas, usuarios, emails, tablas DB? | → NO debe estar en `.jcode/` |

---

## Archivos canónicos del arnés

```
.jcode/
├── README.md                          # Este mapa
├── PRINCIPLES.md                      # Ley operativa + 6 principios LLM
├── AGENT-PROTOCOL.md                  # Checklist por turno (11 items)
├── LOOPS.md                           # Catálogo de loops
├── INTERPRETACION.md                  # Capa de decisión pre-código
├── INCIDENT-PROTOCOLS.md              # Protocolos raros (fragmentación, preflight)
├── FAILURE-PATTERNS.md                 # Catálogo normativo de fallos ocultos + HF Gate
├── quality-preamble.md                  # *** NUEVO: Protocolo de calidad para cada agente ***
├── swarm-prompt.md                      # *** NUEVO: Routing + calidad inyectada a cada spawn ***
├── orient/                              # *** NUEVO v101.4: 11 checkpoints de seguridad ***
│   ├── SKILL.md                         # Triage + 10 preguntas + 7 fases + 11 checkpoints
│   ├── ANALISIS-COMPARATIVO.md          # 15 flujos del harness vs cobertura de orient
│   └── ARBOL-CONEXIONES.md              # 37 mecanismos del harness mapeados
├── BEHAVIOR-INDEX.md                  # Índice de comportamientos del sistema
├── STATE-REGISTERS.md                 # Registros de estado del sistema
├── config.toml                        # Política ejecutable (env-based)
├── mcp.json                           # MCPs agnósticos
│
├── hooks/                             # 4 hooks bash (mínimos)
│   ├── sessionstart.sh                # State init + integrity check
│   ├── turn_start.sh                  # Nuevo turno + reminder
│   ├── turnend.sh                     # Log score + handoff reminder + resync
│   └── posttool.sh                    # Log + tracking reads (NADA más)
│
├── lib/                               # Librerías del harness
│   ├── handbook_builder.py            # Phase I: Static Fact Extraction (AST)
│   ├── handbook_phase2.py             # Phase II: Behavioral Organization (stages)
│   ├── handbook_phase3.py             # Phase III: Hierarchical Synthesis
│   ├── handbook_resync.py             # Resync automático post-commit
│   ├── handbook_verify.py             # BGPD Source Verification
│   ├── _config_parse.py               # Parser TOML mínimo
│   ├── config_reader.sh               # Lee config.toml desde bash
│   ├── contamination_patterns.txt     # Patrones de proyecto a evitar
│   ├── harness.sh                     # Comando /h$
│   ├── state_manager.sh               # Compliance scoring (suma 100)
│   ├── jcode-hook-dispatcher.sh       # Dispatcher (única vía)
│   └── clean-contamination.sh         # Limpieza de contaminación
│
├── handbook/                          # Handbook generado por el pipeline
│   ├── program_graph.json             # G: grafo de llamadas del proyecto
│   ├── behavioral_mapping.json        # S: funciones → stages
│   ├── cache_B.json                   # B: L3 entries cacheadas
│   ├── K_g.json                       # K_g: hash del grafo para resync
│   ├── frozen_entries.json            # Entries congeladas (cambios rotos)
│   └── references/                    # Documentación navegable L1-L2-Z
│       ├── overview.md                # L1: visión general
│       ├── index.md                   # Índice navegable
│       ├── registers.md               # Vista Z: state registers
│       └── stages/                    # L2: páginas por stage
│
├── skills/                            # Skills del harnessing
│   ├── bootstrap-proyecto/            # *** NUEVO: bootstrap adaptativo ***
│   │   ├── SKILL.md
│   │   └── lib/
│   │       ├── project_scanner.py     # Detecta dominio, lenguaje, estado
│   │       ├── stage_generator.py     # Genera stages desde el proyecto
│   │       ├── language_adapter.py    # Framework multi-lenguaje
│   │       ├── config_initializer.py  # Auto-inicialización
│   │       └── bootstrap_all.py       # Orquestador completo
│   ├── arquitecto-proyecto/
│   ├── worker-ejecutor/
│   ├── reviewer-calidad/
│   └── guardrails/
│
├── templates/                         # Plantillas
│   ├── OP.md                          # Operating procedure (con Γ declarations)
│   └── STATE.md                       # State card
│
├── tests/                             # Tests del harness
│   ├── run_all.sh                     # Runner global
│   ├── smoke/                         # Tests de humo (7)
│   ├── diagnostics/                   # Tests de diagnóstico (1)
│   ├── audit/                         # Tests de auditoría (18: 9 propios + 9 independientes)
│   ├── measure/                       # Tests de rendimiento (1)
│   └── bootstrap/                     # Tests de bootstrap-proyecto (3 estrictos)
│
├── iterations/                        # Por proyecto (NO se sincroniza)
│   ├── INDEX.md
│   └── PLAN-VIVO.md                   # ≤100 líneas, sprint activo
│
├── logs/                              # Logs de iteración de remediación
│
└── visualizer/                        # Debug visual en tiempo real
    ├── server/                        # Node.js SSE + WS
    └── public/                        # Frontend D3
```

---

## Los 3 pilares del paper Harness Handbook

Este arnés implementa los 3 pilares del paper arXiv:2607.13285v1:

### Pilar 1 — Construction Pipeline (Phase I/II/III)

| Fase | Qué hace | Output |
|------|----------|--------|
| **Phase I** | Escanea el código del proyecto con AST, extrae funciones, calls, state accesses | `program_graph.json` |
| **Phase II** | Clasifica funciones en stages según el dominio del proyecto | `behavioral_mapping.json` |
| **Phase III** | Sintetiza handbook navegable L1-L2-L3-Z con source_hash real | `cache_B.json`, `references/` |

### Pilar 2 — Resync automático

- Se ejecuta en `turnend.sh` post-commit
- **Siempre re-ejecuta Phase I** antes de comparar (H-4 fix)
- Detecta funciones añadidas, renombradas, eliminadas
- Congela entradas huérfanas en `frozen_entries.json`
- Escritura atómica con `fcntl.flock` (H-5 fix)

### Pilar 3 — BGPD Source Verification

```bash
python3 .jcode/lib/handbook_verify.py --request "modificar función auth"
# → retorna solo las L3 entries relevantes al request
# → verifica que el source code real sigue existiendo
# → calcula relevance por token overlap
```

---

## Skill `orient` v101.4 — Mecanismo de seguridad de flujo (NUEVO)

La skill `orient` ahora opera como **mecanismo de seguridad obligatorio** del flujo del agente.

### Arquitectura de Orient

```text
¿Tarea nueva?
├─ NO → ¿Compresión? → SÍ → Fase 4 (re-anclaje)
└─ SÍ → F0 (bootstrap)
         ├─ FAIL → bootstrap --apply primero
         └─ PASS → P1-P10 (10 preguntas en cascada)
                  ├─ MICROFIX  → 2-A + F1 + F1.5 + Fase 3
                  ├─ SLICE     → 2-B + F1 + F1.5 + F2-F5 + F9-F11 + Fase 3
                  ├─ REMEDIATION → 2-C + F1 + F1.5 + F3 + Fase 3
                  └─ MAINTENANCE → 2-D + F1 + F1.5 + F2-F7 + F9 + Fase 3
```

### 11 Checkpoints (F0-F11) ejecutables

| Chk | Función | Comando |
|-----|---------|---------|
| F0 | Proyecto bootstrap-eado | `bootstrap_all.py --json` |
| F1 | HF Gate | `verify_hidden_failure_gate*.sh` |
| F1.5 | Patrones HF por task_class | dict en runtime |
| F2 | Effort routing | `tomllib` lee `config.toml` |
| F3 | Evidence bundle | `evidence_bundle.sh <loop_id>` |
| F4 | Self-critique | marca `self_critique_done=true` |
| F5 | Reviewer spawn | marca `reviewer_required=true` |
| F6 | Rebuild handbook | `handbook_builder.py + phase2 + phase3` |
| F7 | Regresión completa | `run_all.sh + 4 verify_*.sh` |
| F8 | Aprobación humana | `compliance.json:approval_recorded` |
| F9 | Contamination-zero | `harness.sh check` |
| F10 | BGPD verify | `handbook_verify.py --request` |
| F11 | Cross-check consumidores | `grep old=0, new≥1` |

### 10 Preguntas del árbol

P1-P4 (legacy): muta estado, UI, >2 archivos, tiempo.
P5: ¿test independiente presente?
P6: ¿marcadores de compresión?
P7: ¿toca código del harness?
P8: ¿bug recurrente?
P9: ¿hay approval_boundary?
P10: ¿cambia contrato/schema/R-N?

### Cobertura medida

| Categoría | Cobertura |
|-----------|-----------|
| Leyes (PRINCIPLES.md) | 93% (14/14 principios) |
| Paper-compliant | 78% (Phase I/II/III, resync, BGPD, freeze, OP Γ, leaf mode) |
| HF Gate | 75% (validación de patrones por task_class) |

---

## Frontier Quality Automation (NUEVO)

5 mecanismos ejecutables que convierten el `quality-preamble.md` de consejo a flujo obligatorio:

1. **Effort routing** — `config.toml [policy.effort_routing]` mapea task_class → effort
2. **Evidence bundle generator** — `evidence_bundle.sh` arma bundle automáticamente
3. **Self-critique** — `turnend.sh` marca `self_critique_pending` y avisa al agente
4. **Reviewer spawn** — `turnend.sh` declara `reviewer_required` si task_class ≥ SLICE
5. **Reasoning trace** — `posttool.sh` loguea tool calls en `.jcode/logs/trace-*.log`

---

## Skill `bootstrap-proyecto` (NUEVO)

Cubre los 3 gaps del paper-compliant cuando el proyecto está vacío o en otro stack:

```bash
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py
```

| Gap | Cubre |
|-----|-------|
| 1 — Stages adaptativas | Detecta dominio (CRM/API/ML/etc.) desde PDR.md |
| 2 — Multi-lenguaje | Framework `BaseAdapter` con Python como referencia |
| 3 — Auto-init | Genera `contamination_patterns.txt`, `mcp.json`, stages |

---

## Qué hace el harness por ti (mejoras incorporadas)

### Antes de la auditoría (v100-clean)

| Componente | Estado |
|-----------|--------|
| Escaneo de código | Solo 2 archivos (12 funciones) |
| Clasificación | 100% execute (1 stage) |
| source_hash | Vacío ("" en todas las entries) |
| Call edges | Incluía builtins (split, join, etc.) |
| State accesses | Confundía métodos con atributos |
| Resync | No detectaba cambios sin rebuild manual |
| Path inválido | Corrompía program_graph.json |
| Race condition | Sin locks en escritura JSON |
| Stages | Hardcodeadas (init/interpret/plan/execute/verify/handoff) |

### Después de la remediación + automatización (v101.4)

| Componente | Estado |
|-----------|--------|
| Escaneo de código | **48 funciones, 6 scripts del harness** |
| Clasificación | **6 stages, max 47% en execute, 24 unmapped** |
| source_hash | **42/42 con sha256 real y verificable** |
| Call edges | **0% builtins, ratio 3.06** |
| State accesses | **0 falsos positivos (genuino)** |
| Resync | **Detección automática con Phase I integrado** |
| Path inválido | **Error claro, PG no se corrompe** |
| Race condition | **fcntl.flock + os.replace atómico** |
| Stages | **Adaptativas al dominio del proyecto** |
| HF Gate | **Tests ejecutables + 26 strikes en compliance.json** |
| Frontier Quality | **5 mecanismos ejecutables en hooks** |
| Bootstrap adaptativo | **3 módulos + stages por dominio** |
| **Orient** | **11 checkpoints + 10 preguntas + 7 fases + 93% leyes + 78% paper** |

---

## Cómo empezar según el estado del proyecto

### Escenario A: Proyecto NUEVO (sin código, recién creado)

```bash
# 1. El harness ya está instalado. Solo falta indicar que arranque.
# 2. Ejecuta bootstrap-proyecto EN MODO DIAGNÓSTICO:
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py
#    → Detecta que src/ está vacío
#    → Usa stages default _adaptable=True
#    → Muestra diagnóstico sin modificar nada

# 3. Llena los placeholders del proyecto (una vez):
#    - AGENTS.md §1-§12 (constitución)
#    - PROJECT.md §1-§9 (spec del dominio)
#    - PDR.md §1-§13 (requisitos del producto)

# 4. Cuando el proyecto tenga código en src/, ejecuta:
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --apply
#    → Detecta dominio desde PDR.md + código
#    → Genera stages específicas (no las genéricas)
#    → Configura contamination_patterns.txt
#    → Ajusta mcp.json con paths relativos

# 5. Rebuild del handbook completo (una vez):
python3 .jcode/lib/handbook_builder.py --repo .
python3 .jcode/lib/handbook_phase2.py
python3 .jcode/lib/handbook_phase3.py

# 6. Verificar que todo funciona:
bash .jcode/tests/run_all.sh
```

### Escenario B: Proyecto con CÓDIGO (ya tiene src/ con archivos)

```bash
# 1. Diagnóstico completo del proyecto:
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py
#    → Detecta lenguaje (Python, Go, TS, etc.)
#    → Detecta dominio (CRM, API, ML, etc.)
#    → Detecta flujos críticos desde PDR.md §5

# 2. Aplicar configuración adaptada:
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --apply
#    → Stages específicas del dominio
#    → contamination_patterns.txt con nombre del proyecto

# 3. Build del handbook (escanear el código real):
python3 .jcode/lib/handbook_builder.py --repo .
python3 .jcode/lib/handbook_phase2.py
python3 .jcode/lib/handbook_phase3.py

# 4. Verificar:
bash .jcode/tests/run_all.sh
```

### Escenario C: Proyecto en OTRO LENGUAJE (Go, TS, Rust, Java)

```bash
# 1. Detectar lenguaje:
python3 .jcode/skills/bootstrap-proyecto/lib/language_adapter.py --detect
#    → Si detecta Go, recomienda generar adapter

# 2. Generar esqueleto del adapter para ese lenguaje:
python3 .jcode/skills/bootstrap-proyecto/lib/language_adapter.py \
  --generate-skeleton go

# 3. Implementar el adapter (usa PythonAdapter como referencia):
#    - Editar el archivo generado
#    - Implementar extract() y parse_file()
#    - Registrar con LanguageAdapterRegistry.register("go", GoAdapter)

# 4. Mientras tanto, el harness funciona en modo "agnóstico mínimo"
#    (solo estructura de proyecto, sin program graph)
```

---

## Lo que el harness necesita al inicio (checklist mínimo)

Antes de usar el harness por primera vez en un proyecto:

- [ ] `.jcode/config.toml` con `[project] name` y `[workspace] source_dirs`
- [ ] `.jcode/mcp.json` con paths relativos (ejecutar `config_initializer.py --apply` o editar manual)
- [ ] `AGENTS.md` y `PROJECT.md` en raíz del repo (al menos con placeholders)
- [ ] `PDR.md` en raíz del repo (especialmente §5 para flujos críticos)
- [ ] `src/` con al menos 1 archivo de código (o el proyecto está vacío → modo adaptable)
- [ ] Ejecutar `python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --apply`
- [ ] Ejecutar `bash .jcode/tests/run_all.sh` (verificar 10/10 pass)
- [ ] Ejecutar `bash .jcode/lib/harness.sh check` (verificar 0 contaminación)

Si alguna de estas falla, el harness opera en modo degradado (stages genéricas, sin program graph).

---

## Prompt de inicio de sesión (para copiar/pegar al agente)

Cuando un agente nuevo entra al proyecto, este es el prompt de inicio:

```
Eres un agente en el proyecto {nombre-del-proyecto}.

ANTES DE TOCAR CÓDIGO, LEE EN ESTE ORDEN:
1. cat .jcode/README.md                               ← Mapa del arnés (este archivo)
2. cat AGENTS.md                                       ← Constitución del proyecto
3. cat PROJECT.md                                      ← Spec del dominio
4. cat PDR.md                                          ← Requisitos del producto
5. cat .jcode/INTERPRETACION.md §1-§2                  ← Task type, skills, MCPs
6. cat .jcode/AGENT-PROTOCOL.md                        ← Checklist por turno (11 items)
7. cat .jcode/iterations/PLAN-VIVO.md                  ← Estado actual del sprint

SI EL PROYECTO TIENE CÓDIGO:
  python3 .jcode/lib/handbook_builder.py --repo .
  python3 .jcode/lib/handbook_phase2.py
  python3 .jcode/lib/handbook_phase3.py

SI EL PROYECTO ESTÁ VACÍO (recién creado):
  python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py
  # Modo adaptable: stages genéricas, esperando código

PARA VERIFICAR:
  bash .jcode/tests/run_all.sh
  bash .jcode/lib/harness.sh check

REGLAS:
  - No modifiques .jcode/PRINCIPLES.md ni .jcode/AGENT-PROTOCOL.md
  - No guardes paths absolutos ni nombres de proyecto en .jcode/
  - Si necesitas ayuda de dominio, usa /arquitecto-proyecto
  - Si necesitas implementar, usa /worker-ejecutor
  - Si necesitas revisar calidad, usa /reviewer-calidad
  - Si necesitas verificar reglas de negocio, usa /guardrails
```

---

## Tests del harness (cómo validar)

```bash
# Todos los tests (10 tests: 7 smoke + 1 diagnostics + 1 audit + 1 measure)
bash .jcode/tests/run_all.sh

# Solo tests rápidos (smoke + diagnostics)
bash .jcode/tests/run_all.sh --quick

# Tests anti-fraude (propios)
for t in .jcode/tests/audit/verify_blocker_*.sh; do bash "$t"; done

# Tests anti-fraude (independientes — recalcular desde ground truth)
for t in .jcode/tests/audit/verify_blocker_*_independiente.sh; do bash "$t"; done

# Tests de bootstrap-proyecto (3 gaps)
bash .jcode/tests/bootstrap/test_all.sh

# Re-auditoría independiente completa
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py
```

---

## Cómo adaptar este arnés a otro proyecto

1. Copiar `.jcode/` al nuevo repo
2. Ejecutar `python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py --apply`
   (auto-detecta dominio, lenguaje, configura contamination, mcp.json, stages)
3. Editar `.jcode/config.toml` si es necesario:
   - `[project] name = "tu-proyecto"`
   - `[workspace] source_dirs = ["src", "tests"]`
4. Si el proyecto no es Python, generar adapter con:
   `python3 .jcode/skills/bootstrap-proyecto/lib/language_adapter.py --generate-skeleton go`
5. Rebuild del handbook: `python3 .jcode/lib/handbook_builder.py --repo .`
6. Verificar: `bash .jcode/tests/run_all.sh`

---

## Logs y evidencia

El harness mantiene un registro de todas las iteraciones de remediación:

```
.jcode/logs/
├── remediation-C01-iter1.log     # Circularidad (12→48 funciones)
├── remediation-C02-iter1.log     # Distribución de stages (1→6)
├── remediation-C03-iter1.log     # Modo stub visible
├── remediation-C04-iter1.log     # Validación de path
├── remediation-H01-iter1.log     # source_hash real
├── remediation-H02-iter1.log     # Builtins filtrados
├── remediation-H03-iter1.log     # State accesses reales
├── remediation-H04-iter1.log     # Resync automático
├── remediation-H05-iter1.log     # Locks atómicos
└── VALIDACION-INDEPENDIENTE.md   # 5 verificaciones forenses
```

Cada log documenta: cambios aplicados, output de tests, veredicto.

---

## Versión

- **v101.4-orient-checkpoints** (2026-07-21): Skill `orient` reescrita como mecanismo
  de seguridad de flujo. 11 checkpoints (F0-F11), 10 preguntas en árbol (P1-P10),
  7 fases (0, 1, 2-A, 2-B, 2-C, 2-D MAINTENANCE, 3, 4), 5 anti-patrones nuevos.
  Cobertura: 93% leyes PRINCIPLES, 78% paper-compliant, 75% HF Gate.
  Quality-preamble.md integrado con routing/evidence/self-critique/reviewer/reasoning.
  Frontier Quality Automation: 5 mecanismos ejecutables. 19 tests anti-fraude.
- **v101.2-paper-compliant** (2026-07-21): Los 3 pilares del paper implementados.
  Remedación de 9 blockers (4 CRITICAL + 5 HIGH). Skill bootstrap-proyecto
  para stages adaptativas, multi-lenguaje, y auto-inicialización. 18 tests
  anti-fraude (9 propios + 9 independientes). 10/10 run_all.sh pass.
  audit_security.py: 0 CRITICAL, 0 HIGH.
- **v101.1-vision-mcp-fix** (2026-07-18): Documentada la precedencia real de MCP
  en Jcode v0.51.1 (global + proyecto por nombre), los overrides de servidores
  globales con `disabled: true`, la obligación de usar paths absolutos y el
  wrapper canónico `playwright-cli`.
- **v100-clean** (2026-07-16): refactor completo. Eliminados 14 archivos,
  reducidas 5,377 → 1,200 líneas. Bug de scoring 90→100 corregido.
  Eliminada toda contaminación de proyecto. Añadido visualizador en tiempo real.
