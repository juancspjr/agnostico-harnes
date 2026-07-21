# PROMPT PARA AGENTES CONSTRUCTORES

## Asunto: Implementación completa verificada en loop — Harness jcode paper-compliant

---

## Contexto

Adjunto dos PDFs que constituyen la especificación técnica completa:

1. **`auditoria-harness-jcode-v100clean.pdf`** (33 páginas) — Auditoría técnica del harness actual. Identifica 12 hallazgos (1 Critical, 2 High, 5 Medium, 4 Low) con severidades, ubicaciones exactas (archivo:línea), y patches de código propuestos.

2. **`cumplimiento-paper-harness-handbook.pdf`** (59 páginas) — Análisis de cumplimiento del paper *Harness Handbook* (arXiv:2607.13285v1, Wang et al., Jul 2026). Identifica 8 gaps contra los 3 pilares del paper (Handbook representation L1-L3+Z, BGPD workflow, Construction pipeline + Resync) con matriz de 20 requisitos, y blueprint de 6 fases con 7 patches de código completos.

**Referencia del paper**: arXiv:2607.13285v1 — *Harness Handbook: Making Evolving Agent Harnesses Readable, Navigable, and Editable* (Ruhan Wang, Yucheng Shi, et al., Tencent HY LLM Frontier / Indiana University, 14 julio 2026).

---

## Objetivo

Implementar **la integración completa** de ambas mejoras: las correcciones de la auditoría (PDF 1) y el cumplimiento del paper (PDF 2), verificadas en loop iterativo, hasta que todos los gates pasen.

**No es un prototype. No es una demo. Es la implementación final, probada, lista para producción.**

---

## Alcanzando del trabajo

El repo base es el template jcode v100-clean (54 archivos, .jcode/ con hooks/lib/skills/templates/iterations/tests/visualizer). Deben aplicar las correcciones y luego construir los 3 pilares del paper sobre esa base corregida.

---

## Fases de implementación — orden estricto, sin saltar gates

### FASE 0 — Setup y verificación de baseline (30 min)

```bash
# 1. Clonar/posicionarse en el repo del harness
cd <repo-del-harness>

# 2. Verificar baseline
bash .jcode/lib/harness.sh status
bash .jcode/lib/harness.sh check
# Esperado: 0 contaminación, estructura completa

# 3. Snapshot del estado inicial
git add -A && git commit -m "chore: snapshot baseline antes de paper-compliant bootstrap"

# 4. Crear rama de trabajo
git checkout -b feat/paper-compliant-bootstrap
```

**Gate FASE 0**: `harness.sh check` retorna 0 contaminación. Si no, detener y reportar.

---

### FASE 1 — Correcciones críticas de la auditoría (PDF 1) — 1-2 días

Implementar los 3 hallazgos críticos antes de tocar el paper. Sin esto, el pipeline hereda bugs.

#### 1.1 Fix C-01 (Critical) — Crear los 9 tests faltantes

`run_all.sh` referencia 9 tests que NO existen en las carpetas `smoke/`, `diagnostics/`, `audit/`, `measure/`. Crearlos con esqueletos bash funcionales:

```
.jcode/tests/smoke/smoke_harness_flow.sh
.jcode/tests/smoke/smoke_hook_enforcement.sh
.jcode/tests/smoke/smoke_r_aa_1.sh
.jcode/tests/smoke/smoke_agent_protocol.sh
.jcode/tests/smoke/smoke_r_no_fake_swarm.sh
.jcode/tests/smoke/smoke_ddlp_tpsp.sh
.jcode/tests/diagnostics/diagnostics.sh
.jcode/tests/audit/audit_harness.sh
.jcode/tests/measure/measure_harness.sh
```

**Especificación por test** (ver PDF 1 §13.1 para código completo):

| Test | Qué debe validar |
|------|------------------|
| `smoke_harness_flow.sh` | Estructura canónica (PRINCIPLES.md, AGENT-PROTOCOL.md, LOOPS.md, README.md, config.toml, mcp.json existen) + 4 hooks ejecutables + compliance.json válido + score ≤ 100 |
| `smoke_hook_enforcement.sh` | posttool.sh detecta tool=grep/rg → marca srsi_done_this_turn=true; detecta git commit sin SRSI previo → strike R-AA-1 |
| `smoke_r_aa_1.sh` | Simular commit sin grep previo, verificar que `aa1_violations` se incrementa en compliance.json |
| `smoke_agent_protocol.sh` | Los 11 items del checklist de AGENT-PROTOCOL.md §1 tienen mecanismo (hook, script, o declaración manual) |
| `smoke_r_no_fake_swarm.sh` | Commit a código fuente (.go/.ts/.py) sin swarm spawn reciente (≤30 turns) → strike R-FAKE-COORDINATOR |
| `smoke_ddlp_tpsp.sh` | Estructura §3 (gaps), §4 (solicitudes), §5 (cronología) existe en PLAN-VIVO.md template |
| `diagnostics.sh` | Ejecuta `harness.sh check` + `breakdown` y valida output structure |
| `audit_harness.sh` | Ejecuta `harness.sh check` y valida 0 contaminación en archivos del arnés (excluye tests/state/iterations) |
| `measure_harness.sh` | Mide tiempos de `harness.sh init`, `check`, `score` (deben ser < 1s cada uno) |

**Reglas para cada test**:
- `set -uo pipefail`
- Exit 0 en pass, exit 1 en fail
- Output: `PASS <descripcion>` o `FAIL <descripcion>` (stderr)
- Sin side effects (excepto tests que validen side effects)
- Standalone (no dependen de otros tests)

#### 1.2 Fix H-01 (High) — Bug regex en posttool.sh

`posttool.sh` línea 104 tiene una regex con comilla doble sin escapar que rompe el matcher R-FAKE-COORDINATOR:

**Bug original** (línea 30 y línea 104):
```bash
grep -qE '\.(go|ts|astro|tsx|jsx|sql|svelte|css|scss|vue)( |"|$)'
```

**Fix**:
```bash
# Usar clase de caracteres en lugar de comilla doble sin escapar
CODE_EXT_PATTERN='\.(go|ts|astro|tsx|jsx|sql|svelte|css|scss|vue)([^A-Za-z0-9]|$)'
if echo "$tool_args" | grep -qE "$CODE_EXT_PATTERN"; then
```

Aplicar el fix en **dos lugares**: línea 30 (`is_docs_only_commit`) y línea 104 (R-FAKE-COORDINATOR detector).

#### 1.3 Fix H-02 (High) — Stack-agnóstico vía config

Las extensiones hardcodeadas deben moverse a `config.toml` para que cualquier stack funcione:

**Paso 1**: Agregar sección a `.jcode/config.toml`:
```toml
[workspace.code_extensions]
# Extensiones de código fuente para detectores R-FAKE-COORDINATOR
# y auditoría post-commit. Ajustar al stack del proyecto.
extensions = [".go", ".ts", ".astro", ".tsx", ".jsx",
              ".sql", ".svelte", ".css", ".scss", ".vue"]
# Python: [".py", ".ipynb", ".sql"]
# Rust: [".rs", ".toml"]
# Go puro: [".go", ".sql"]
```

**Paso 2**: Crear helper `.jcode/lib/config_reader.sh` que lea arrays desde TOML sin parser completo (usar awk):

```bash
#!/usr/bin/env bash
# Lee arrays desde config.toml sin parser TOML completo.
set -uo pipefail
CONFIG_FILE="${JCODE_CONFIG:-.jcode/config.toml}"

config_get_array() {
  local key="$1"
  local section="${key%%.*}"
  local field="${key#*.}"
  awk -v sec="[$section]" -v fld="$field" '
    $0 == sec { in_sec=1; next }
    /^\[/ { in_sec=0 }
    in_sec && $1 == fld "=" {
      sub(/^[^=]*=\s*\[/, ""); sub(/\].*$/, "")
      gsub(/["'"'"',\s]+/, " "); print; exit
    }
  ' "$CONFIG_FILE" | tr ' ' '\n' | grep -v '^$'
}
```

**Paso 3**: Modificar `posttool.sh` y `turnend.sh` para leer extensiones dinámicamente:
```bash
source "$JCODE_DIR/lib/config_reader.sh"
EXTENSIONS=$(config_get_array workspace.code_extensions.extensions)
PATTERN=$(echo "$EXTENSIONS" | sed 's/^\./\\./' | paste -sd'|' -)
if echo "$tool_args" | grep -qE "($PATTERN)([^A-Za-z0-9]|$)"; then
```

#### Gate FASE 1

```bash
# 1. Tests pasan
bash .jcode/tests/run_all.sh --quick
# Esperado: 9 pass, 0 fail, 0 skip

# 2. Sin contaminación
bash .jcode/lib/harness.sh check
# Esperado: 0 contaminación

# 3. Commit
git add -A
git commit -m "fix(harness): C-01 tests + H-01 regex + H-02 config extensions

- C-01: crear 9 tests faltantes (smoke/diagnostics/audit/measure)
- H-01: fix regex posttool.sh comilla doble sin escapar
- H-02: extraer code_extensions a config.toml, crear config_reader.sh

Refs: auditoria-harness-jcode-v100clean.pdf §13.1-13.3"
```

**Si el gate falla**: iterar hasta pasar. No avanzar a FASE 2.

---

### FASE 2 — Paper Pilar 1: Construction Pipeline (PDF 2) — 5-7 días

Implementar las 3 fases del construction pipeline del paper §3.2.

#### 2.1 Phase I — Static Fact Extraction (determinístico, cero LLM)

Crear `.jcode/lib/handbook_builder.py` con:

- **Adapter Python** usando `ast` de stdlib (cero dependencias externas)
- **Función `extract_static_facts(repo_root, language)`** que retorna el program graph G
- **Output**: `.jcode/handbook/program_graph.json` con schema:
  ```json
  {
    "schema_version": 1,
    "language": "python",
    "leaf_mode": "function" | "file",  // auto-detect: function si ≤200 funciones
    "files_scanned": N,
    "functions": [{
      "qualname": "Class.method",
      "file": "src/auth.py",
      "line_range": [142, 178],
      "signature": "(self, ...) -> None",
      "body_hash": "sha256:..."
    }],
    "boundaries": [],
    "call_edges": [{
      "caller": "qualname",
      "callee": "qualname",
      "line": 145,
      "resolved": true
    }],
    "state_accesses": [{
      "function": "qualname",
      "attribute": "self.x",
      "access": "read" | "write",
      "line": 146
    }],
    "unresolved_calls_log": []
  }
  ```

**Código completo**: ver PDF 2 §14.1 (Patch 1 — handbook_builder.py).

**Casos edge a manejar**:
- Archivos con syntax error → loguear en `unresolved_calls_log`, no crash
- Archivos sin funciones → contar como files_scanned pero no aportar functions
- Calls que no resuelven a función interna → loguear, no asignar a targets adivinados
- Detección de read vs write: inspeccionar parent `Assign` node (no solo `Attribute`)

**Validación**:
```bash
python3 .jcode/lib/handbook_builder.py phase1 --repo .
# Output esperado:
# [ok] Phase I: 47 functions, 89 resolved calls, leaf_mode=function
```

#### 2.2 Phase II — Behavioral Organization (LLM-assisted)

Crear `.jcode/lib/handbook_phase2.py` con el loop Propose-Review-Mapping:

- **Seed skeleton S₀** basado en PRINCIPLES.md PARTE II (task_class) + execution stages típicos de jcode:
  ```
  init → interpret → plan → execute → verify → handoff
  ```
- **Prompt de clasificación**: usar el template del Appendix D.1.1 del paper (incluido en PDF 2 §15.1)
- **LLM**: usar z-ai-web-dev-sdk (`from zai import ZaiClient`), modelo `glm-4.6`, temperature 0.2
- **Modo stub** (sin SDK disponible): asignar todas las funciones a "execute" y loguear warning
- **Output**: `.jcode/handbook/behavioral_mapping.json` con schema:
  ```json
  {
    "schema_version": 1,
    "leaf_mode": "function",
    "stage_skeleton": { "stages": [...] },
    "function_assignments": [{
      "qualname": "...",
      "purpose": "<60-150 word 5-aspect description>",
      "granularity": "function" | "region",
      "function_assignments": ["execute", ...],
      "regions": null,
      "file": "...",
      "line_range": [...]
    }],
    "coverage_record": {
      "unmapped_functions": ["qualname", ...]
    }
  }
  ```

**Código completo**: ver PDF 2 §15.1 (Patch 2 — Phase II con LLM).

**Validación**:
```bash
python3 .jcode/lib/handbook_phase2.py
# Output esperado:
# [ok] Phase II: 47 functions assigned to 6 stages
# [ok] Unmapped: 3 (functions que no encajan en ningún stage)
```

#### 2.3 Phase III — Hierarchical Synthesis

Crear `.jcode/lib/handbook_phase3.py` que convierte `(S, U_g)` en:

- **L1**: `.jcode/handbook/references/overview.md` (system overview, arquitectura, execution model, stage relationships, global state flow)
- **L2**: `.jcode/handbook/references/stages/<id>.md` por cada stage (responsibilities, inputs/outputs, execution flow, state, internal units, code anchors)
- **L3**: cards por cada function (file path, anchor, line_range, source_hash, interface, behavior, relations, register_interactions)
- **Vista Z**: `.jcode/handbook/references/registers.md` con writers/readers por cada state register
- **Index**: `.jcode/handbook/references/index.md` con tabla de stages + leaves + registers
- **K_g**: `.jcode/handbook/K_g.json` (estado de resync: leaf_mode, program_graph_hash, stage_skeleton, config)
- **Cache B**: `.jcode/handbook/cache_B.json` (l3_entries, l2_pages, l1_overview reusables)
- **Frozen**: `.jcode/handbook/frozen_entries.json` (entries cuyo locator no valida, inicialmente [])

**Código completo**: ver PDF 2 §16.1 (Patch 3 — Phase III synthesis).

**Validación**:
```bash
python3 .jcode/lib/handbook_phase3.py
# Output esperado:
# [ok] Phase III: 47 L3 entries, 8 state registers, 0 frozen
```

#### Gate FASE 2

```bash
# Verificar estructura completa del handbook
test -f .jcode/handbook/references/overview.md || exit 1
test -f .jcode/handbook/references/index.md || exit 1
test -f .jcode/handbook/references/registers.md || exit 1
test -d .jcode/handbook/references/stages/ || exit 1
ls .jcode/handbook/references/stages/*.md | wc -l  # debe ser 6 (uno por stage)

# Verificar que hay L3 entries con locators
l3_count=$(python3 -c "import json; d=json.load(open('.jcode/handbook/cache_B.json')); print(len(d.get('l3_entries', {})))")
[[ $l3_count -gt 0 ]] || exit 1

# Verificar K_g y cache B
test -f .jcode/handbook/K_g.json || exit 1
test -f .jcode/handbook/cache_B.json || exit 1
test -f .jcode/handbook/frozen_entries.json || exit 1

# Commit
git add -A
git commit -m "feat(harness): paper pilar 1 — construction pipeline Phase I/II/III

- Phase I: handbook_builder.py con PythonAdapter (ast stdlib)
- Phase II: handbook_phase2.py con Propose-Review-Mapping loop (LLM)
- Phase III: handbook_phase3.py con hierarchical synthesis L1-L3+Z
- Auto-detect leaf mode (function si ≤200 funciones)
- Output: .jcode/handbook/{references/, K_g.json, cache_B.json, frozen_entries.json}

Paper ref: arXiv:2607.13285v1 §3.2"
```

---

### FASE 3 — Paper Pilar 2: Resync automático (PDF 2) — 2-3 días

#### 3.1 Crear handbook_resync.py

Implementar el procedimiento `Resync_g(H, R, R', ∆, Γ)` del paper Appendix B.4:

```python
# .jcode/lib/handbook_resync.py
# Tres pasos:
# (1) Version alignment: reparses R', construye G', compara con G via ∆
# (2) Scoped update: si S válido, actualiza solo entries afectadas; si no, full rebuild
# (3) Conservative handling: freeze entries no revalidables, registrar unmapped
```

**Código completo**: ver PDF 2 §17.1 (Patch 4 — Resync hook).

**Casos edge a manejar**:
- Diff vacío → retornar `{"status": "no_op"}`, no hacer nada
- Función eliminada → freeze su L3 entry con razón "function_removed"
- Función renombrada → detectar via body fingerprint match, actualizar locator
- File movido → actualizar file path en todos los L3 entries del archivo
- Source hash mismatch → freeze con razón "source_hash_mismatch"
- Skeleton inválido → invocar `handbook_builder.py build` para full rebuild

#### 3.2 Modificar turnend.sh para invocar resync post-commit

Agregar al final de `.jcode/hooks/turnend.sh` (después de línea 60):

```bash
# 7. Handbook resync si hubo commit reciente
if [[ $last_commit_age -le 5 ]]; then
  HANDBOOK_DIR="$JCODE_DIR/handbook"
  if [[ -d "$HANDBOOK_DIR" ]] && [[ -f "$HANDBOOK_DIR/K_g.json" ]]; then
    echo "[turnend] Sincronizando handbook (Resync_g)…"
    if python3 "$JCODE_DIR/lib/handbook_resync.py" --auto 2>&1 | \
       tee -a "$JCODE_DIR/logs/handbook_resync.log"; then
      echo "[turnend] ✅ Handbook resync OK"
    else
      echo "[turnend] ⚠️  Handbook resync falló — ver log" >&2
    fi
  fi
fi
```

#### Gate FASE 3

```bash
# Test 1: commit que toca un archivo existente
echo "# test" >> src/__init__.py 2>/dev/null || { mkdir -p src && echo "# test" > src/__init__.py; }
git add -A && git commit -m "test: trigger resync" -q

# Ejecutar resync manualmente
python3 .jcode/lib/handbook_resync.py --auto
# Output esperado: {"status": "ok", "files_changed": 1, "entries_updated": N, ...}

# Verificar que frozen_entries.json se actualizó
test -f .jcode/handbook/frozen_entries.json

# Test 2: commit que elimina un archivo
# (crear archivo dummy, commitear, eliminar, commitear, ejecutar resync)
echo "def dummy(): pass" > src/dummy.py
python3 .jcode/lib/handbook_builder.py phase1 --repo .  # rebuild para incluir dummy
python3 .jcode/lib/handbook_phase2.py
python3 .jcode/lib/handbook_phase3.py
git add -A && git commit -m "test: add dummy" -q

rm src/dummy.py
git add -A && git commit -m "test: remove dummy" -q
python3 .jcode/lib/handbook_resync.py --auto
# Verificar que la entry de dummy está frozen con razón "function_removed"

python3 -c "
import json
frozen = json.load(open('.jcode/handbook/frozen_entries.json'))
assert any('dummy' in str(f.get('qualname', '')) for f in frozen), 'dummy no está frozen'
print('✅ dummy correctamente frozen tras eliminación')
"

git add -A
git commit -m "feat(harness): paper pilar 2 — resync automático post-commit

- handbook_resync.py implementa Resync_g (Appendix B.4)
- turnend.sh invoca resync tras commit reciente (≤5 min)
- Version alignment + scoped update + conservative handling
- Frozen entries para locators no revalidables

Paper ref: arXiv:2607.13285v1 §3.3.3, Appendix B.4"
```

---

### FASE 4 — Paper Pilar 3: BGPD con source verification (PDF 2) — 2 días

#### 4.1 Crear handbook_verify.py

Implementar el paso 4 de BGPD (Source verification, paper Appendix B.1):

```python
# .jcode/lib/handbook_verify.py
# Resuelve locators del handbook contra el filesystem real
# Retiene solo los sites que siguen siendo relevantes al request q
```

**Código completo**: ver PDF 2 §18.1 (Patch 5 — BGPD con verification).

**Casos edge a manejar**:
- File not found → agregar a `skipped_missing` con razón "file_not_found"
- Source hash mismatch → agregar a `skipped_hash_mismatch`
- Anchor (function name) no encontrado en source → `skipped_missing` con razón "anchor_not_found"
- Entry frozen → agregar a `skipped_frozen`, no verificar
- Relevance check: heurística de token overlap (≥20% overlap con request_q)

#### 4.2 Crear skill handbook/SKILL.md canonical (Figure 6 del paper)

```bash
mkdir -p .jcode/skills/handbook
```

Crear `.jcode/skills/handbook/SKILL.md` siguiendo exactamente el formato del paper Figure 6:

```markdown
---
name: jcode-handbook
description: >-
  Structural map of the harness, derived from its code. Use it when
  planning a change to find EVERY code site the change must touch —
  it maps the code stage-by-stage and lists every state register
  together with all of its read/write locations.
---

# Harness Handbook: navigation guide

## Reference files
- `.jcode/handbook/references/overview.md` — system orientation. Read first.
- `.jcode/handbook/references/index.md` — stages + state registers map.
- `.jcode/handbook/references/registers.md` — for each register: ALL writers/readers.
- `.jcode/handbook/references/stages/<id>.md` — one stage + cards per leaf.

## How to use it (during planning, before you write your plan)
1. Read `references/overview.md` first.
2. Read `references/index.md` to identify stages + registers your change involves.
3. For EVERY state register your change touches, read `references/registers.md`.
4. Open `references/stages/<id>.md` for detail.
5. Verify each site against real code:
   ```bash
   python3 .jcode/lib/handbook_verify.py \
     --request "<change request>" \
     --stages <stage_ids>
   ```
6. Your plan must account for every verified site.

## Maintenance
Auto-regenerated after every commit by `handbook_resync.py` (from `turnend.sh`).
If stale entries detected: `python3 .jcode/lib/handbook_resync.py --auto`
```

**Código completo**: ver PDF 2 §19.1 (Patch 6 — SKILL.md manifest).

#### 4.3 Modificar skill orient/SKILL.md para exigir verification

En `.jcode/skills/orient/SKILL.md`, Fase 2-B paso 1, agregar paso VERIFY obligatorio:

```markdown
- **VERIFY (NUEVO)**: Ejecutar OBLIGATORIAMENTE:
  ```bash
  python3 .jcode/lib/handbook_verify.py \
    --request "<descripción del cambio>" \
    --stages <stage_ids>
  ```
  Retener solo los sites que el script retorna como `verified`.
  Si todos los candidates están `frozen` o `missing`, el handbook
  está desactualizado — invocar `handbook_resync.py --auto` antes
  de continuar.
```

#### Gate FASE 4

```bash
# Verificar que handbook_verify.py funciona
result=$(python3 .jcode/lib/handbook_verify.py --request "auth login")
echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['summary']['verified_count'] >= 0, 'verified_count inválido'
print(f\"✅ verify: {d['summary']['verified_count']} sites verificados, {d['summary']['frozen_count']} frozen\")
"

# Verificar skill handbook creada
test -f .jcode/skills/handbook/SKILL.md

# Verificar skill orient/ actualizada
grep -q "VERIFY (NUEVO)" .jcode/skills/orient/SKILL.md

git add -A
git commit -m "feat(harness): paper pilar 3 — BGPD con source verification

- handbook_verify.py implementa BGPD step 4 (Appendix B.1)
- skill handbook/SKILL.md canonical (Figure 6 del paper)
- skill orient/SKILL.md actualizada con paso VERIFY obligatorio

Paper ref: arXiv:2607.13285v1 §3.3.1, Appendix B.1"
```

---

### FASE 5 — Edit Planning con Γ + Tests paper-compliance (PDF 2) — 2 días

#### 5.1 Extender template OP.md con Γ declarations

Modificar `.jcode/templates/OP.md` para incluir action declarations en function granularity (paper Appendix B.2):

```markdown
## §3 Action declarations Γ (machine-readable)

> El handbook-resync pipeline consume esto. Una rename =
> remove(old) + add(new).

```json
{
  "will_modify": [
    "<qualname de función existente cuyos edits cambian>"
  ],
  "will_add": [
    "<qualname de nueva función introducida>"
  ],
  "will_remove": [
    "<qualname de función eliminada>"
  ]
}
```
```

**Código completo**: ver PDF 2 §20.1 (Patch 7 — Edit planning con Γ).

#### 5.2 Crear smoke_paper_compliance.sh

Crear `.jcode/tests/smoke/smoke_paper_compliance.sh` que valide los 3 pilares:

```bash
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# Pilar 1: Construction Pipeline
test -f "$JCODE_DIR/lib/handbook_builder.py" || fail "Falta handbook_builder.py"
test -f "$JCODE_DIR/lib/handbook_phase2.py" || fail "Falta handbook_phase2.py"
test -f "$JCODE_DIR/lib/handbook_phase3.py" || fail "Falta handbook_phase3.py"
test -f "$JCODE_DIR/handbook/program_graph.json" || fail "Falta program_graph.json"
test -f "$JCODE_DIR/handbook/behavioral_mapping.json" || fail "Falta behavioral_mapping.json"
test -f "$JCODE_DIR/handbook/references/overview.md" || fail "Falta overview.md (L1)"
test -f "$JCODE_DIR/handbook/references/index.md" || fail "Falta index.md"
test -f "$JCODE_DIR/handbook/references/registers.md" || fail "Falta registers.md (vista Z)"
ls "$JCODE_DIR/handbook/references/stages/"*.md >/dev/null 2>&1 || fail "Faltan L2 stage pages"
pass "Pilar 1: Construction Pipeline completo"

# Pilar 2: Resync
test -f "$JCODE_DIR/lib/handbook_resync.py" || fail "Falta handbook_resync.py"
test -f "$JCODE_DIR/handbook/K_g.json" || fail "Falta K_g.json (resync state)"
test -f "$JCODE_DIR/handbook/frozen_entries.json" || fail "Falta frozen_entries.json"
# Verificar que turnend.sh invoca resync
grep -q "handbook_resync.py" "$JCODE_DIR/hooks/turnend.sh" || fail "turnend.sh no invoca resync"
pass "Pilar 2: Resync automático configurado"

# Pilar 3: BGPD verification
test -f "$JCODE_DIR/lib/handbook_verify.py" || fail "Falta handbook_verify.py"
test -f "$JCODE_DIR/skills/handbook/SKILL.md" || fail "Falta skill handbook/SKILL.md"
grep -q "VERIFY" "$JCODE_DIR/skills/orient/SKILL.md" || fail "skill orient/ sin paso VERIFY"
pass "Pilar 3: BGPD con source verification"

# Edit Planning con Γ
grep -q "will_modify" "$JCODE_DIR/templates/OP.md" || fail "OP.md sin Γ declarations"
grep -q "will_add" "$JCODE_DIR/templates/OP.md" || fail "OP.md sin Γ declarations"
grep -q "will_remove" "$JCODE_DIR/templates/OP.md" || fail "OP.md sin Γ declarations"
pass "Edit Planning con Γ declarations"

echo "smoke_paper_compliance: OK"
exit 0
```

Agregar `smoke_paper_compliance.sh` al array CATEGORIES en `run_all.sh`.

#### Gate FASE 5 (FINAL)

```bash
# 1. Todos los tests pasan (10 smoke + 1 diagnostics + 1 audit + 1 measure = 13)
bash .jcode/tests/run_all.sh
# Esperado: 13 pass, 0 fail, 0 skip

# 2. Auditoría completa del harness
bash .jcode/lib/harness.sh check
# Esperado: 0 contaminación, estructura completa

# 3. Manual BGPD verification end-to-end
python3 .jcode/lib/handbook_verify.py --request "cualquier feature del PDR"

# 4. Resync manual de prueba
python3 .jcode/lib/handbook_resync.py --auto

# 5. Verificar que no quedan placeholders críticos
grep -rn '<[a-z_]*>' .jcode/AGENTS.md .jcode/PRINCIPLES.md 2>/dev/null | grep -v "^Binary" | head -5
# (algunos placeholders en plantillas son OK, pero no en archivos canónicos)

# Commit final
git add -A
git commit -m "feat(harness): paper-compliant bootstrap completo

- Edit Planning con Γ declarations (will_modify/add/remove)
- smoke_paper_compliance.sh valida los 3 pilares
- 13 tests pasan (9 audit + 1 paper-compliance + 3 existentes)

Paper ref: arXiv:2607.13285v1 (Wang et al., 2026)
Audit ref: auditoria-harness-jcode-v100clean.pdf"
```

---

## Verificación en loop iterativo

**Regla**: después de cada fase, ejecutar el gate. Si el gate falla, **iterar la fase hasta pasar**. No avanzar a la siguiente fase con gates pendientes.

```
Loop de cada fase:
  1. Implementar cambios de la fase
  2. Ejecutar gate de la fase
  3. Si gate pasa → commit → avanzar a siguiente fase
  4. Si gate falla →
     a. Analizar output del gate
     b. Identificar qué falló
     c. Fix específico
     d. Volver a paso 2
  5. Si después de 3 iteraciones el gate sigue fallando →
     detener, reportar bloqueo al usuario con:
     - Fase afectada
     - Gate que falla
     - Output del gate
     - Intentos realizados
     - Hipótesis de causa raíz
```

---

## Entregables finales

Al completar las 5 fases, deben entregar:

1. **Repo con las 5 fases commiteadas** en rama `feat/paper-compliant-bootstrap`, lista para merge a main
2. **README actualizado** (`.jcode/README.md`) documentando:
   - Los 3 pilares del paper implementados
   - Cómo invocar `handbook_builder.py`, `handbook_resync.py`, `handbook_verify.py`
   - Cómo usar la skill `handbook/SKILL.md`
3. **HANDOFF-INICIO-SESION.md** actualizado con:
   - Estado: "Paper-compliant bootstrap completo"
   - Próximo loop sugerido: primer loop de feature real usando el handbook
4. **Reporte de ejecución** (puede ser en el chat) con:
   - Número de L3 entries generadas
   - Número de state registers detectados
   - Número de tests pasando (deben ser 13)
   - Tiempo total de implementación
   - Bugs encontrados durante el proceso (si los hubo)

---

## Restricciones y anti-patrones (PROHIBIDO)

1. **❌ NO saltar fases**: cada fase tiene un gate explícito. Si el gate falla, iterar.
2. **❌ NO modificar `PRINCIPLES.md` o `AGENT-PROTOCOL.md`** durante el bootstrap. Son la ley del harness.
3. **❌ NO commitear con gates pendientes**: cada commit debe dejar el repo en estado verde.
4. **❌ NO usar placeholders `<...>` en código**: si algo no se sabe, preguntar.
5. **❌ NO inventar APIs**: si el paper especifica un formato, usar ese formato exacto.
6. **❌ NO omitir tests**: los 13 tests deben pasar. Si un test falla, fix el código, no el test.
7. **❌ NO usar `--fake-coordinator-override` o `--coord-self-authorize`** para saltar detectores.
8. **❌ NO dejar `frozen_entries.json` creciendo sin límite**: si supera 20% del total de L3 entries, ejecutar full rebuild.
9. **❌ NO usar `python3 -c` para scripts largos**: todos los scripts Python deben vivir en archivos en `.jcode/lib/`.
10. **❌ NO avanzar a FASE 2 sin que FASE 1 pase su gate**: las dependencias son estrictas.

---

## Referencias

- **PDF 1**: `auditoria-harness-jcode-v100clean.pdf` — auditoría técnica del harness actual (33 páginas, 12 hallazgos con patches)
- **PDF 2**: `cumplimiento-paper-harness-handbook.pdf` — análisis de cumplimiento del paper + blueprint + 7 patches completos (59 páginas)
- **Paper original**: arXiv:2607.13285v1 — *Harness Handbook: Making Evolving Agent Harnesses Readable, Navigable, and Editable* (Wang et al., 2026)

Todos los patches de código están completos en los PDFs. No necesitan inventar nada: implementen lo especificado, verifiquen los gates, iteren hasta pasar.

---

## Cómo empezar

1. **Lean los 2 PDFs completos primero**. Sin skimming. Las secciones 13-22 del PDF 2 tienen todo el código que necesitan.
2. **Verifiquen pre-condiciones** (FASE 0).
3. **Empiecen por FASE 1** (correcciones de auditoría). Es la base sobre la que se construye todo lo demás.
4. **Commiteen después de cada gate pasado**. Historial limpio, fácil de auditar.
5. **Si se bloquean**, reporten con: fase, gate, output, intentos, hipótesis. No avancen con bugs pendientes.

**Tiempo estimado total**: 12-16 días (1-2 dev full-time). Las dependencias son estrictas pero las fases 3 y 4 pueden paralelizarse parcialmente después de la 2.

---

**Fin del prompt. Adjuntos: los 2 PDFs.**
