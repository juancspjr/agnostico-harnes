# PROMPT DE REMEDIACIÓN CRÍTICA CON LOOP DE INSISTENCIA

## Asunto: Resolver 8 blockers CRITICAL+HIGH del audit forense — loop iterativo hasta verificación independiente

---

## Contexto

La auditoría forense (ver `REPORTE-AUDITORIA-FORENSE.md` adjunto) concluyó **RECHAZADO** con 4 hallazgos CRITICAL y 5 HIGH. Los agentes constructores tomaron atajos sistemáticos que falsearon los claims del paper-compliant bootstrap. Las inconsistencias más graves:

- **C-1**: El handbook escaneó solo 2 de 6 archivos del propio harness (40% cobertura). La circularidad prometida no existe.
- **C-2**: 100% de funciones clasificadas como "execute". La distribución de stages es falsa.
- **C-3**: Modo stub permanente. El "Propose-Review-Mapping loop" del paper nunca se implementó con LLM real.
- **C-4**: `handbook_builder.py --repo /nonexistent/path` corrompe silenciosamente program_graph.json.
- **H-1 a H-5**: source_hash vacío, call edges inflados con builtins, state accesses falsos, resync sin rebuild, race condition sin locks.

**No se aprueba nada hasta que cada uno de los 8 blockers tenga fix verificado con evidencia independiente y test anti-fraude que lo confirme.**

---

## Objetivo

Resolver los 8 blockers en orden estricto, con **loop de insistencia iterativo** por cada uno. Cada fix debe pasar:

1. **Test anti-fraude específico** escrito por el agente remediador
2. **Test anti-fraude independiente** escrito por el auditor (este prompt lo especifica)
3. **Test de regresión** (todos los tests previos siguen pasando)
4. **Commit atómico** con mensaje que referencia el hallazgo (C-1, H-4, etc.)

**Si cualquier test falla, el fix NO se aprueba. El agente debe iterar hasta pasar los 3 niveles de test. No se acepta "funciona" sin evidencia.**

---

## Reglas del loop de insistencia (CRÍTICAS — leer 3 veces)

### Regla 1: Loop iterativo con budget

Cada blocker tiene un **budget de 5 iteraciones**. Si después de 5 intentos no pasa los 3 niveles de test, el agente debe:

1. **Detener el trabajo** sobre ese blocker
2. **Reportar bloqueo** al usuario con:
   - ID del blocker (C-1, H-4, etc.)
   - Las 5 iteraciones intentadas (qué cambió en cada una)
   - Output exacto del test que falla en la última iteración
   - Hipótesis de causa raíz
   - Sugerencia de escalada (¿necesita input humano? ¿refactor mayor?)
3. **No avanzar** al siguiente blocker hasta resolver el actual o escalar

### Regla 2: Evidencia obligatoria por iteración

Por cada iteración (incluso las que fallan), el agente debe documentar en `.jcode/logs/remediation-CXX-iterN.log`:

```
[timestamp] ITERATION N/5 — blocker C-X
[timestamp] Cambios aplicados:
  - archivo1.py: líneas X-Y (descripción del cambio)
  - archivo2.py: líneas X-Y (descripción del cambio)
[timestamp] Test anti-fraude propio:
  $ bash test_X.sh
  Exit code: 0/1
  Output: <primeras 20 líneas>
[timestamp] Test anti-fraude independiente:
  $ bash test_X_independiente.sh
  Exit code: 0/1
  Output: <primeras 20 líneas>
[timestamp] Test de regresión:
  $ bash .jcode/tests/run_all.sh --quick
  Exit code: 0/1
  Output: <resumen pass/fail>
[timestamp] VEREDICTO: PASSED / FAILED (motivo)
```

### Regla 3: No shortcuts en tests anti-fraude

Los tests anti-fraude **NO pueden**:
- Solo validar `test -f` (existencia de archivo)
- Solo validar `grep -q` (presencia de keyword)
- Solo validar `exit 0` (cualquier cosa que retorne 0 pasa)
- Hardcodear valores esperados que el agente controla
- Skip el test con `|| true`

Los tests anti-fraude **DEBEN**:
- Ejecutar el código real con inputs controlados
- Validar output con aserciones específicas (no solo exit code)
- Recalcular métricas independientemente (no leerlas de archivos del agente)
- Cubrir casos edge que el agente no controla

### Regla 4: Auditoría continua

Después de cada blocker resuelto, el auditor (cualquier agente externo al que hace el fix) debe poder ejecutar un solo comando que valide el fix:

```bash
bash .jcode/tests/audit/verify_blocker_C1.sh
# Output esperado:
# [PASS] C-1: handbook escanea 100% de .jcode/lib/*.py
# [PASS] C-1: 30+ funciones en program_graph.json (no 12)
# [PASS] C-1: phase2/phase3/resync/verify en PG
```

Si el comando no existe o no pasa, el fix NO se considera completo.

---

## Orden de remediación — 8 blockers en secuencia estricta

### BLOCKER C-1 — Circularidad falsa (handbook no escanea su propio código)

**Problema**: `handbook_builder.py` solo escanea `_config_parse.py` y `handbook_builder.py`. Los otros 4 scripts del paper no están en program_graph.json.

**Causa raíz**: `scan_dirs` hardcodeado a `["src", ".jcode/lib", "backend", "frontend"]` y además solo escanea archivos existentes en el momento de la generación original (12 funciones). No reescanea cuando se agregan phase2/phase3/resync/verify.

**Fix requerido**:

```python
# .jcode/lib/handbook_builder.py — función extract()

def extract(repo_root: Path, language: str = "python") -> dict:
    """Phase I: extract static facts from ALL source files in repo."""
    adapter = _get_adapter(language)

    # FIX C-1: scan_dirs dinámico, no hardcodeado
    # 1. Leer source_dirs desde config.toml
    source_dirs = _read_source_dirs_from_config(repo_root)

    # 2. SIEMPRE incluir .jcode/lib/ (circularidad del harness)
    if ".jcode/lib" not in source_dirs:
        source_dirs.append(".jcode/lib")

    # 3. Auto-detect: si source_dirs está vacío o no existe,
    #    escanear todo el repo (excluyendo .git, node_modules, etc.)
    existing_dirs = [d for d in source_dirs if (repo_root / d).exists()]
    if not existing_dirs:
        existing_dirs = _auto_detect_source_dirs(repo_root)

    # 4. Escanear recursivamente, SIN cachear el snapshot
    all_functions, all_calls, all_state = [], [], []
    for sd in existing_dirs:
        for path in (repo_root / sd).rglob(f"*{adapter.FILE_EXT}"):
            if _is_excluded(path):
                continue
            result = adapter.parse_file(path)
            all_functions.extend(result["functions"])
            all_calls.extend(result["calls"])
            all_state.extend(result["state"])

    # 5. NUNCA escribir PG vacío (ver C-4)
    if not all_functions:
        raise RuntimeError(
            f"No functions found in {existing_dirs}. "
            f"Verificar --repo path y source_dirs en config.toml"
        )

    return _build_program_graph(all_functions, all_calls, all_state,
                                  language, files_scanned=len(all_files))

def _read_source_dirs_from_config(repo_root: Path) -> list:
    """Lee [workspace] source_dirs desde config.toml."""
    config_path = repo_root / ".jcode" / "config.toml"
    if not config_path.exists():
        return ["src", "tests"]  # default
    # Usar config_reader.sh o parser TOML
    import tomllib  # Python 3.11+
    with open(config_path, "rb") as f:
        config = tomllib.load(f)
    return config.get("workspace", {}).get("source_dirs", ["src", "tests"])

def _auto_detect_source_dirs(repo_root: Path) -> list:
    """Si no hay source_dirs configurados, detectar automáticamente."""
    candidates = ["src", "lib", "app", "tests", ".jcode/lib"]
    return [d for d in candidates if (repo_root / d).exists()]
```

**Tests anti-fraude**:

Test propio del agente (`.jcode/tests/audit/verify_blocker_C1.sh`):
```bash
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# 1. Rebuild handbook desde cero
rm -rf "$JCODE_DIR/handbook"
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" 2>&1 | \
  tee /tmp/c1_rebuild.log

# 2. Verificar que program_graph.json tiene 30+ funciones
func_count=$(python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
print(len(pg['functions']))
")
[[ $func_count -ge 30 ]] || fail "Solo $func_count funciones (esperado ≥30)"

# 3. Verificar que los 6 scripts del harness están en PG
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
files = {f['file'] for f in pg['functions']}
required = [
    '.jcode/lib/handbook_builder.py',
    '.jcode/lib/handbook_phase2.py',
    '.jcode/lib/handbook_phase3.py',
    '.jcode/lib/handbook_resync.py',
    '.jcode/lib/handbook_verify.py',
    '.jcode/lib/_config_parse.py',
]
for r in required:
    # Match por sufijo (path puede ser absoluto o relativo)
    if not any(f.endswith(r) for f in files):
        print(f'❌ Falta: {r}')
        exit(1)
print('✅ Todos los 6 scripts del harness en PG')
"

pass "C-1: handbook escanea 100% del harness"
exit 0
```

Test independiente del auditor (ejecutar DESPUÉS del test del agente):
```bash
# .jcode/tests/audit/verify_blocker_C1_independiente.sh
#!/usr/bin/env bash
# Test independiente: recalcula métricas SIN usar archivos del agente
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Contar funciones Python reales en .jcode/lib/ (ground truth)
real_func_count=$(find "$JCODE_DIR/lib" -name "*.py" -exec \
    python3 -c "
import ast, sys
for path in sys.argv[1:]:
    try:
        tree = ast.parse(open(path).read())
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                print(node.name)
    except: pass
" {} + | wc -l)

# 2. Contar funciones en program_graph.json
pg_func_count=$(python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
print(len(pg['functions']))
")

# 3. Verificar que coinciden (con tolerancia ±2 por funciones anidadas)
diff=$((real_func_count - pg_func_count))
[[ $diff -lt 0 ]] && diff=$((-diff))
[[ $diff -le 5 ]] || {
    echo "❌ MISMATCH: real=$real_func_count pg=$pg_func_count (diff=$diff)"
    exit 1
}

echo "✅ PG cubre $pg_func_count de $real_func_count funciones reales (diff=$diff)"
exit 0
```

**Criterio de aprobación C-1**:
- `verify_blocker_C1.sh` retorna exit 0
- `verify_blocker_C1_independiente.sh` retorna exit 0
- `run_all.sh --quick` sigue pasando (regresión)
- diff entre funciones reales y PG ≤ 5

**Budget**: 5 iteraciones. Si no pasa, escalar.

---

### BLOCKER C-2 — Distribución de stages artificial (100% execute)

**Problema**: Las 11 L3 entries están todas en `relations.stages = ["execute"]`.

**Causa raíz**: `classify_function_stub` en `handbook_phase2.py` usa keyword matching simplista. Las funciones del harness contienen `parse` y `extract` que siempre matchean a `execute`. Default es `["execute"]`.

**Fix requerido — opciones (elegir UNA)**:

**Opción A (preferida): Integración LLM real con z-ai-web-dev-sdk**

```python
# .jcode/lib/handbook_phase2.py

import os, sys

# Intentar importar z-ai SDK
try:
    from zai import ZaiClient
    LLM_CLIENT = ZaiClient()
    LLM_AVAILABLE = True
except ImportError:
    LLM_CLIENT = None
    LLM_AVAILABLE = False
    print("[warn] z-ai-web-dev-sdk no disponible — usando heurística avanzada",
          file=sys.stderr)

CLASSIFY_PROMPT = """You are analyzing one function from a codebase and
classifying it into one or more stages of a hand-authored data-flow skeleton.

STAGE ASSIGNMENT
- Pick stage IDs ONLY from the list provided.
- Use caller/callee context to disambiguate.
- A function can belong to multiple stages if it serves multiple roles.

STAGES:
{stages}

FUNCTION:
qualname: {qualname}
file: {file}
line_range: {line_range}

SOURCE:
```python
{source}
```

CALLER/CALLEE CONTEXT:
{context}

OUTPUT: ONLY a JSON object inside ```json fenced block:
{{
  "qualname": "<exact qualname>",
  "purpose": "<60-150 word description>",
  "function_assignments": ["stage-id", ...]
}}
"""

def classify_function(func: dict, context: dict, stages: list) -> dict:
    """Classify function into stages. Uses LLM if available, heuristic otherwise."""
    if LLM_AVAILABLE:
        return _classify_with_llm(func, context, stages)
    else:
        return _classify_with_heuristic(func, context, stages)

def _classify_with_llm(func, context, stages):
    """LLM-based classification following paper Appendix D.1.1."""
    source = _read_source(func)
    prompt = CLASSIFY_PROMPT.format(
        stages=json.dumps(stages, indent=2),
        qualname=func["qualname"],
        file=func["file"],
        line_range=func["line_range"],
        source=source,
        context=json.dumps(context, indent=2)
    )
    try:
        resp = LLM_CLIENT.chat.completions.create(
            model="glm-4.6",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2
        )
        return _extract_json_from_response(resp.choices[0].message.content)
    except Exception as e:
        print(f"[warn] LLM call failed for {func['qualname']}: {e}",
              file=sys.stderr)
        return _classify_with_heuristic(func, context, stages)

def _classify_with_heuristic(func, context, stages):
    """Heurística avanzada (no solo keyword matching)."""
    source = _read_source(func).lower()
    qualname = func["qualname"].lower()

    # Reglas basadas en caller/callee context (no solo source)
    callers = context.get("callers", [])
    callees = context.get("callees", [])

    assignments = []

    # 1. Funciones llamadas por __init__ o sessionstart → init
    if any("__init__" in c or "sessionstart" in c for c in callers):
        assignments.append("init")

    # 2. Funciones que llaman a grep, search, lookup → interpret
    if any("grep" in c or "search" in c or "lookup" in c for c in callees):
        assignments.append("interpret")

    # 3. Funciones con "plan", "loop", "declare" en qualname → plan
    if any(k in qualname for k in ["plan", "loop", "declare", "set_current"]):
        assignments.append("plan")

    # 4. Funciones que modifican archivos (open + write) → execute
    if "open(" in source and ("write" in source or ".write" in source):
        assignments.append("execute")

    # 5. Funciones con "verify", "check", "test", "validate" → verify
    if any(k in qualname or k in source for k in
           ["verify", "check", "test", "validate", "fixed_check"]):
        assignments.append("verify")

    # 6. Funciones con "handoff", "closeout", "commit", "update_plan" → handoff
    if any(k in qualname or k in source for k in
           ["handoff", "closeout", "commit", "update_plan_vivo"]):
        assignments.append("handoff")

    # 7. Cross-cutting: funciones pequeñas llamadas desde muchos lugares
    if len(callers) >= 3 and len(source.splitlines()) <= 10:
        assignments.append("crosscut")

    # Default: SI no hay matches, NO asignar a execute automáticamente
    # En su lugar, marcar como unmapped
    if not assignments:
        return {
            "qualname": func["qualname"],
            "purpose": f"(unmapped) {func['qualname']}",
            "function_assignments": [],  # unmapped, no execute por defecto
            "regions": None,
            "file": func["file"],
            "line_range": func["line_range"],
            "_unmapped_reason": "heuristic_no_match"
        }

    return {
        "qualname": func["qualname"],
        "purpose": f"(heuristic) {func['qualname']} → {assignments}",
        "function_assignments": list(set(assignments)),  # dedupe
        "regions": None,
        "file": func["file"],
        "line_range": func["line_range"]
    }
```

**Opción B (si LLM no disponible): Heurística avanzada (código arriba)**

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_C2.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# 1. Rebuild completo
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT"
python3 "$JCODE_DIR/lib/handbook_phase2.py"
python3 "$JCODE_DIR/lib/handbook_phase3.py"

# 2. Verificar distribución de stages (no 100% en uno solo)
python3 -c "
import json
from collections import Counter
bm = json.load(open('$JCODE_DIR/handbook/behavioral_mapping.json'))
assignments = bm['function_assignments']

stages = Counter()
for fa in assignments:
    for s in fa.get('function_assignments', []):
        stages[s] += 1

print(f'Distribución: {dict(stages)}')
total = sum(stages.values())

# Verificar que al menos 4 stages diferentes tienen funciones
assert len(stages) >= 4, f'❌ Solo {len(stages)} stages con funciones (esperado ≥4)'

# Verificar que ningún stage tiene >70% de las funciones
for stage, count in stages.items():
    pct = count / total * 100
    assert pct <= 70, f'❌ Stage {stage} tiene {pct:.0f}% (esperado ≤70%)'

# Verificar que hay unmapped (no todo clasificado)
unmapped = bm.get('coverage_record', {}).get('unmapped_functions', [])
print(f'Unmapped: {len(unmapped)}')

print('✅ Distribución de stages correcta')
"

pass "C-2: distribución de stages no artificial"
exit 0
```

**Criterio de aprobación C-2**:
- Al menos 4 stages diferentes tienen funciones asignadas
- Ningún stage tiene > 70% de las funciones
- Si LLM disponible: prompt usa Appendix D.1.1 del paper
- Si LLM no disponible: heurística documentada y unmapped ≠ 0

**Budget**: 5 iteraciones.

---

### BLOCKER C-3 — Modo stub permanente (no LLM real)

**Problema**: `handbook_phase2.py` solo implementa `classify_function_stub`. No hay código que invoque el SDK z-ai.

**Causa raíz**: Ver C-2 — la opción A implementa el LLM real.

**Fix requerido**:
- Si z-ai-web-dev-sdk está instalado: usarlo (ver C-2 opción A)
- Si no está instalado: documentar explícitamente en `handbook_phase2.py` y `README.md` que el modo LLM requiere `pip install z-ai-web-dev-sdk`
- El modo stub NO debe ser silencioso: debe imprimir warning visible al inicio

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_C3.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Verificar que el código LLM existe en handbook_phase2.py
grep -q "from zai import\|ZaiClient\|glm-4.6" "$JCODE_DIR/lib/handbook_phase2.py" || {
    echo "❌ No hay integración LLM en handbook_phase2.py"
    exit 1
}

# 2. Si z-ai SDK disponible, ejecutar con LLM
if python3 -c "from zai import ZaiClient" 2>/dev/null; then
    echo "z-ai SDK disponible — ejecutando Phase II con LLM real"
    output=$(python3 "$JCODE_DIR/lib/handbook_phase2.py" 2>&1)
    echo "$output" | grep -qiE "llm|glm|zai" || {
        echo "❌ LLM disponible pero no se usó"
        exit 1
    }
    # Verificar que al menos una function_assignments tiene purpose detallado (no stub)
    python3 -c "
import json
bm = json.load(open('$JCODE_DIR/handbook/behavioral_mapping.json'))
for fa in bm['function_assignments']:
    purpose = fa.get('purpose', '')
    if not purpose.startswith('(stub)') and not purpose.startswith('(heuristic)') and not purpose.startswith('(unmapped)'):
        print(f'✅ LLM generó purpose: {purpose[:80]}...')
        exit(0)
print('❌ Ningún purpose generado por LLM')
exit(1)
"
else
    echo "z-ai SDK no disponible — verificando modo fallback documentado"
    # Verificar que el warning está en el código
    grep -q "LLM_AVAILABLE = False" "$JCODE_DIR/lib/handbook_phase2.py" || {
        echo "❌ No hay flag LLM_AVAILABLE en el código"
        exit 1
    }
    # Verificar que README documenta el requisito
    grep -qi "z-ai-web-dev-sdk\|pip install zai" "$JCODE_DIR/README.md" 2>/dev/null || \
        grep -qi "z-ai-web-dev-sdk\|pip install zai" "$REPO_ROOT/README.md" 2>/dev/null || {
        echo "❌ README no documenta requisito de z-ai SDK"
        exit 1
    }
fi

echo "✅ C-3: integración LLM real o fallback documentado"
exit 0
```

**Criterio de aprobación C-3**:
- Código LLM existe y es invocable cuando SDK disponible
- Modo fallback imprime warning visible
- README documenta el requisito

**Budget**: 5 iteraciones.

---

### BLOCKER C-4 — Builder corrompe PG con path inválido

**Problema**: `handbook_builder.py --repo /nonexistent/path` escribe PG vacío sin error.

**Fix requerido**:

```python
# .jcode/lib/handbook_builder.py — al inicio de extract()

def extract(repo_root: Path, language: str = "python") -> dict:
    # FIX C-4: validar repo_root ANTES de cualquier operación
    if not repo_root.exists():
        raise FileNotFoundError(
            f"repo_root no existe: {repo_root}. "
            f"Verificar --repo path."
        )
    if not repo_root.is_dir():
        raise NotADirectoryError(
            f"repo_root no es directorio: {repo_root}"
        )
    if not os.access(repo_root, os.R_OK):
        raise PermissionError(
            f"Sin permisos de lectura en: {repo_root}"
        )

    # FIX C-4: nunca escribir PG vacío
    adapter = _get_adapter(language)
    # ... (resto del código)

    if not all_functions:
        raise RuntimeError(
            f"No functions found in {existing_dirs}. "
            f"Verificar --repo path y source_dirs en config.toml. "
            f"Files scanned: {files_scanned}. "
            f"NO se escribió program_graph.json."
        )

    # Solo escribir si hay contenido
    pg = _build_program_graph(...)
    return pg

# En main():
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True, help="Repo root (REQUIRED)")
    # ...
    args = parser.parse_args()

    try:
        pg = extract(Path(args.repo), args.language)
        # Solo escribir si extract() retorna (no exception)
        out_path = Path(args.repo) / ".jcode" / "handbook" / "program_graph.json"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(pg, indent=2))
        print(f"[ok] PG saved: {len(pg['functions'])} functions")
    except (FileNotFoundError, NotADirectoryError, PermissionError, RuntimeError) as e:
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)
```

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_C4.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Backup del PG actual
cp "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_backup_c4.json

# 2. Ejecutar con path inexistente
output=$(python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /nonexistent/path 2>&1)
exit_code=$?

# 3. Verificar que falla (exit code != 0)
[[ $exit_code -ne 0 ]] || {
    echo "❌ Exit code 0 con path inexistente"
    cp /tmp/pg_backup_c4.json "$JCODE_DIR/handbook/program_graph.json"
    exit 1
}

# 4. Verificar que NO se escribió PG vacío
# (el script no debe tocar el archivo existente)
diff "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_backup_c4.json > /dev/null || {
    echo "❌ PG fue sobreescrito con contenido vacío"
    cp /tmp/pg_backup_c4.json "$JCODE_DIR/handbook/program_graph.json"
    exit 1
}

# 5. Verificar que el error es claro
echo "$output" | grep -qiE "not exist|no existe|FileNotFoundError|invalid path" || {
    echo "❌ Error no claro: $output"
    cp /tmp/pg_backup_c4.json "$JCODE_DIR/handbook/program_graph.json"
    exit 1
}

# 6. Verificar casos edge adicionales
# Path es archivo (no directorio)
echo "test" > /tmp/not_a_dir
output=$(python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /tmp/not_a_dir 2>&1)
[[ $? -ne 0 ]] || {
    echo "❌ Exit code 0 con path que es archivo"
    exit 1
}

# Path sin permisos de lectura
mkdir -p /tmp/no_read_dir
chmod 000 /tmp/no_read_dir
output=$(python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /tmp/no_read_dir 2>&1)
chmod 755 /tmp/no_read_dir  # restaurar para cleanup
[[ $? -ne 0 ]] || {
    echo "❌ Exit code 0 con path sin permisos"
    exit 1
}

echo "✅ C-4: builder valida path y no corrompe PG"
exit 0
```

**Criterio de aprobación C-4**:
- Exit code != 0 para path inexistente, archivo, sin permisos
- PG existente NO se sobreescribe
- Mensaje de error claro
- `run_all.sh --quick` sigue pasando

**Budget**: 5 iteraciones.

---

### BLOCKER H-1 — source_hash vacío en L3 entries

**Problema**: Las 11 L3 entries en `cache_B.json` tienen `source_hash = ""`.

**Fix requerido**:

```python
# .jcode/lib/handbook_phase3.py — en _generate_l3_entry()

import hashlib

def _generate_l3_entry(func: dict, pg: dict) -> dict:
    """Generate L3 entry con source_hash REAL."""
    file_path = func["file"]
    line_range = func["line_range"]

    # FIX H-1: calcular source_hash real
    source_hash = _compute_source_hash(file_path, line_range)

    locator = {
        "file": file_path,
        "anchor": func["qualname"],
        "line_range": line_range,
        "source_hash": source_hash  # NO vacío
    }
    # ...

def _compute_source_hash(file_path: str, line_range: list) -> str:
    """SHA256 del source excerpt real."""
    p = Path(file_path)
    if not p.exists():
        return "sha256:FILE_NOT_FOUND"

    try:
        lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
        start, end = line_range
        # Ajustar índices (line_range es 1-indexed, Python es 0-indexed)
        region = "\n".join(lines[max(0, start-1):end])
        return f"sha256:{hashlib.sha256(region.encode()).hexdigest()}"
    except Exception as e:
        return f"sha256:ERROR:{type(e).__name__}"
```

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_H1.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Rebuild completo
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT"
python3 "$JCODE_DIR/lib/handbook_phase2.py"
python3 "$JCODE_DIR/lib/handbook_phase3.py"

# 2. Verificar que TODAS las L3 entries tienen source_hash no vacío
python3 -c "
import json
cb = json.load(open('$JCODE_DIR/handbook/cache_B.json'))
entries = cb.get('l3_entries', {})
empty_count = 0
valid_count = 0
for qn, entry in entries.items():
    sh = entry.get('locator', {}).get('source_hash', '')
    if not sh or sh == '':
        empty_count += 1
        print(f'❌ {qn}: source_hash vacío')
    elif sh.startswith('sha256:') and len(sh) > 10:
        valid_count += 1
    else:
        print(f'⚠️  {qn}: source_hash inválido: {sh}')
        empty_count += 1

assert empty_count == 0, f'❌ {empty_count} entries con source_hash vacío'
assert valid_count >= 10, f'❌ Solo {valid_count} entries con source_hash válido'
print(f'✅ {valid_count} L3 entries con source_hash válido')
"

# 3. Verificar que source_hash corresponde al source real
python3 -c "
import json, hashlib
cb = json.load(open('$JCODE_DIR/handbook/cache_B.json'))
entries = cb.get('l3_entries', {})

# Verificar al menos 3 entries aleatorias
import random
sample = random.sample(list(entries.items()), min(3, len(entries)))

for qn, entry in sample:
    loc = entry['locator']
    file_path = loc['file']
    line_range = loc['line_range']
    expected_hash = loc['source_hash']

    # Recalcular hash independientemente
    with open(file_path) as f:
        lines = f.read().splitlines()
    start, end = line_range
    region = '\n'.join(lines[max(0, start-1):end])
    actual_hash = f'sha256:{hashlib.sha256(region.encode()).hexdigest()}'

    assert actual_hash == expected_hash, \
        f'❌ {qn}: hash mismatch. expected={expected_hash[:30]}... actual={actual_hash[:30]}...'
    print(f'✅ {qn}: source_hash verificado')

print('✅ H-1: source_hash real y verificable')
"

exit 0
```

**Criterio de aprobación H-1**:
- 0 entries con source_hash vacío
- 100% de entries con hash `sha256:<64 chars>`
- Hash recalculado independientemente coincide con el almacenado

**Budget**: 5 iteraciones.

---

### BLOCKER H-2 — Call edges inflados con builtins

**Problema**: 101 call edges incluyen `split`, `join`, `match`, `startswith`, etc.

**Fix requerido**:

```python
# .jcode/lib/handbook_builder.py — en PythonAdapter._extract_calls()

import builtins

# Lista de métodos built-in de tipos comunes que NO son calls reales
BUILTIN_METHODS = {
    # str methods
    'split', 'join', 'rsplit', 'splitlines', 'strip', 'rstrip', 'lstrip',
    'upper', 'lower', 'title', 'capitalize', 'swapcase', 'replace',
    'startswith', 'endswith', 'find', 'rfind', 'index', 'rindex',
    'count', 'encode', 'decode', 'format', 'format_map', 'isalpha',
    'isdigit', 'isalnum', 'isupper', 'islower', 'isspace', 'istitle',
    'isidentifier', 'isprintable', 'isnumeric', 'isdecimal', 'isascii',
    'expandtabs', 'ljust', 'rjust', 'center', 'zfill', 'partition',
    'rpartition', 'removeprefix', 'removesuffix', 'translate', 'maketrans',
    # list methods
    'append', 'extend', 'insert', 'remove', 'pop', 'clear', 'index',
    'count', 'sort', 'reverse', 'copy',
    # dict methods
    'keys', 'values', 'items', 'get', 'pop', 'popitem', 'clear',
    'update', 'setdefault', 'copy', 'fromkeys',
    # set methods
    'add', 'remove', 'discard', 'pop', 'clear', 'copy',
    'union', 'intersection', 'difference', 'symmetric_difference',
    'update', 'intersection_update', 'difference_update',
    'symmetric_difference_update', 'issubset', 'issuperset',
    'isdisjoint',
    # file methods
    'read', 'readline', 'readlines', 'write', 'writelines',
    'close', 'flush', 'seek', 'tell', 'truncate', 'fileno',
    # bytes/bytearray methods
    'hex', 'fromhex',
    # common stdlib calls
    'print', 'len', 'range', 'enumerate', 'zip', 'map', 'filter',
    'sorted', 'reversed', 'sum', 'min', 'max', 'abs', 'round',
    'isinstance', 'issubclass', 'hasattr', 'getattr', 'setattr',
    'delattr', 'dir', 'vars', 'globals', 'locals', 'type', 'id',
    'hash', 'repr', 'str', 'int', 'float', 'bool', 'complex',
    'list', 'tuple', 'set', 'frozenset', 'dict', 'bytes', 'bytearray',
    'open', 'input',
    # match/regex
    'match', 'search', 'findall', 'finditer', 'sub', 'subn', 'split',
    'escape', 'fullmatch',
    # json
    'load', 'loads', 'dump', 'dumps',
    # os/sys/os.path
    'exists', 'isfile', 'isdir', 'join', 'split', 'splitext',
    'basename', 'dirname', 'abspath', 'relpath', 'normpath',
    'getcwd', 'chdir', 'listdir', 'mkdir', 'makedirs', 'remove',
    'rmdir', 'removedirs', 'rename', 'renames', 'walk',
}

def _extract_calls(self, node, caller_qualname) -> list:
    """Extract calls excluding built-in methods."""
    calls = []
    for child in ast.walk(node):
        if isinstance(child, ast.Call):
            callee = self._call_target(child.func)
            if not callee:
                continue

            # FIX H-2: filtrar builtins
            callee_short = callee.split('.')[-1]
            if callee_short in BUILTIN_METHODS:
                continue
            # Filtrar también builtins del módulo builtins
            if hasattr(builtins, callee_short):
                continue

            calls.append({
                "caller": caller_qualname,
                "callee": callee,
                "line": child.lineno,
                "resolved": False
            })
    return calls
```

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_H2.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Rebuild PG
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT"

# 2. Verificar que no hay builtins en call_edges
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
edges = pg['call_edges']

builtins_to_check = ['split', 'join', 'match', 'startswith', 'endswith',
                     'strip', 'append', 'write', 'read', 'load', 'loads',
                     'dump', 'dumps', 'print', 'len', 'range', 'enumerate',
                     'zip', 'map', 'filter', 'sorted', 'isinstance']

builtin_edges = []
for e in edges:
    callee_short = e['callee'].split('.')[-1]
    if callee_short in builtins_to_check:
        builtin_edges.append(e)

assert len(builtin_edges) == 0, \
    f'❌ {len(builtin_edges)} call edges a builtins: ' + \
    ', '.join(set(e['callee'] for e in builtin_edges[:5]))

print(f'✅ 0 call edges a builtins en {len(edges)} edges totales')
"

# 3. Verificar que el ratio calls/function es razonable (no 8.4)
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
n_func = len(pg['functions'])
n_edges = len(pg['call_edges'])
ratio = n_edges / n_func if n_func > 0 else 0
print(f'Ratio calls/function: {ratio:.1f}')
assert ratio <= 5.0, f'❌ Ratio sospechosamente alto: {ratio:.1f}'
print('✅ Ratio calls/function razonable')
"

exit 0
```

**Criterio de aprobación H-2**:
- 0 call edges a métodos built-in listados
- Ratio calls/function ≤ 5.0
- Tests de regresión pasan

**Budget**: 5 iteraciones.

---

### BLOCKER H-3 — State accesses son calls disfrazados

**Problema**: Los 5 state_accesses son `self._extract_from_tree`, `self._record_function`, etc. (métodos bound, no atributos).

**Fix requerido**:

```python
# .jcode/lib/handbook_builder.py — en PythonAdapter._extract_state()

def _extract_state(self, node, func_qualname) -> list:
    """Extract ONLY real self.X attribute accesses (not method calls)."""
    accesses = []
    for child in ast.walk(node):
        # Caso 1: self.X read (Attribute dentro de otra expresión, NO en Call)
        if isinstance(child, ast.Attribute) and \
           isinstance(child.value, ast.Name) and \
           child.value.id == "self":
            # FIX H-3: verificar que NO es una llamada a método
            # Si el parent es Call y child es func, es una llamada, no un acceso
            # AST no tiene parent pointer, hay que trackearlo
            attr_name = child.attr
            # Heurística: si empieza con _ y NO tiene (), podría ser atributo
            # Mejor: excluir si el siguiente token es (
            # En AST, si child es el .func de un Call, es método
            # Para detectar esto, caminamos el árbol con parent tracking

            # Skip si parece método (empieza con verb o tiene patrón snake_case verb)
            # Mejor enfoque: verificar si es Assign target (write) o no
            pass

    # Enfoque correcto: walk con parent tracking
    accesses = []
    for parent, child in self._walk_with_parents(node):
        if isinstance(child, ast.Attribute) and \
           isinstance(child.value, ast.Name) and \
           child.value.id == "self":

            # Es llamada a método si parent es Call y child es Call.func
            is_method_call = (
                isinstance(parent, ast.Call) and
                parent.func is child
            )
            if is_method_call:
                continue  # skip, es self.method()

            # Es write si parent es Assign y child está en targets
            is_write = (
                isinstance(parent, ast.Assign) and
                child in parent.targets
            )
            # También: AugAssign (self.x += 1)
            is_aug_write = (
                isinstance(parent, ast.AugAssign) and
                parent.target is child
            )
            # También: AnnAssign (self.x: int = 0)
            is_ann_write = (
                isinstance(parent, ast.AnnAssign) and
                parent.target is child
            )

            access = "write" if (is_write or is_aug_write or is_ann_write) else "read"

            accesses.append({
                "function": func_qualname,
                "attribute": f"self.{child.attr}",
                "access": access,
                "line": child.lineno
            })
    return accesses

def _walk_with_parents(self, node):
    """Walk AST yielding (parent, child) pairs."""
    for parent in ast.walk(node):
        for child in ast.iter_child_nodes(parent):
            yield parent, child
```

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_H3.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Rebuild PG
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT"

# 2. Verificar que state_accesses no contiene métodos (no self.method())
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
sa = pg['state_accesses']

# Lista de métodos conocidos del harness que NO deberían aparecer
known_methods = ['_extract_from_tree', '_record_function', '_extract_calls',
                 '_extract_state', '_call_target', '_attr_chain',
                 '_qualname', 'parse_file', 'extract']

method_in_state = []
for s in sa:
    attr = s['attribute'].replace('self.', '')
    if attr in known_methods:
        method_in_state.append(s)

assert len(method_in_state) == 0, \
    f'❌ {len(method_in_state)} métodos en state_accesses: ' + \
    ', '.join(s['attribute'] for s in method_in_state)

print(f'✅ 0 métodos en state_accesses ({len(sa)} accesos reales)')
"

# 3. Verificar que state_accesses tienen access=read o write (no vacío)
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
sa = pg['state_accesses']
for s in sa:
    assert s['access'] in ('read', 'write'), f\"❌ access inválido: {s['access']}\"
print(f'✅ Todos los state_accesses tienen access válido')
"

# 4. Verificar que hay al menos algunos writes (no solo reads)
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
sa = pg['state_accesses']
writes = [s for s in sa if s['access'] == 'write']
reads = [s for s in sa if s['access'] == 'read']
print(f'Writes: {len(writes)}, Reads: {len(reads)}')
# Si hay 0 writes, el detector de writes está roto
if len(sa) > 0:
    assert len(writes) > 0, '❌ 0 writes detectados — detector de writes roto'
print('✅ Detector de writes funciona')
"

exit 0
```

**Criterio de aprobación H-3**:
- 0 métodos en state_accesses
- access es siempre `read` o `write` (no vacío)
- Si hay state_accesses, hay al menos algunos writes

**Budget**: 5 iteraciones.

---

### BLOCKER H-4 — Resync sin rebuild no detecta cambios

**Problema**: `handbook_resync.py --auto` después de un rename retorna `no_op` si no se ejecuta Phase I primero.

**Fix requerido**:

```python
# .jcode/lib/handbook_resync.py

def resync(diff_text=None, repo_root="."):
    """Resync_g(H, R, R', ∆, Γ) — versión corregida."""

    # FIX H-4: SIEMPRE ejecutar Phase I antes de comparar
    # El resync no puede confiar en que program_graph.json está actualizado
    print("[resync] Step 0: Re-extracting static facts (Phase I)", file=sys.stderr)

    try:
        # Re-ejecutar Phase I para obtener el program graph actualizado
        sys.path.insert(0, str(Path(".jcode/lib")))
        from handbook_builder import extract
        from pathlib import Path as P

        new_pg = extract(P(repo_root))

        # Comparar con el PG cached
        k_g = _load_json(HANDBOOK_DIR / "K_g.json")
        old_pg_hash = k_g.get("program_graph_hash")

        # Calcular hash del nuevo PG
        import hashlib
        new_pg_hash = f"sha256:{hashlib.sha256(
            json.dumps(new_pg, sort_keys=True).encode()).hexdigest()[:16]}"

        if new_pg_hash == old_pg_hash:
            return {"status": "no_op", "reason": "graph_unchanged_after_rebuild"}

        # Guardar nuevo PG
        (HANDBOOK_DIR / "program_graph.json").write_text(
            json.dumps(new_pg, indent=2))

        # Actualizar K_g
        k_g["program_graph_hash"] = new_pg_hash
        (HANDBOOK_DIR / "K_g.json").write_text(json.dumps(k_g, indent=2))

        print(f"[resync] PG changed: {old_pg_hash} → {new_pg_hash}",
              file=sys.stderr)

    except Exception as e:
        print(f"[resync] Phase I failed: {e}", file=sys.stderr)
        return {"status": "error", "reason": f"phase1_failed: {e}"}

    # Continuar con el resync normal usando diff_text si se proporcionó
    if diff_text is None:
        diff_text = _last_commit_diff(repo_root)

    if not diff_text.strip():
        # Aún si diff está vacío, el PG cambió → continuar
        print("[resync] No diff but PG changed — continuing", file=sys.stderr)

    # ... (resto del resync: version alignment, scoped update, conservative handling)
    # Identificar funciones afectadas comparando old PG con new PG
    old_pg = _load_json(HANDBOOK_DIR / "program_graph.json.bak")  # backup antes de sobreescribir
    # (en realidad, comparar k_g["cached_functions"] vs new_pg["functions"])

    affected_qualnames = _diff_functions(old_pg, new_pg)

    # ... (resto del código)

def _diff_functions(old_pg, new_pg):
    """Identificar funciones added, removed, modified."""
    old_funcs = {f["qualname"]: f for f in old_pg.get("functions", [])}
    new_funcs = {f["qualname"]: f for f in new_pg.get("functions", [])}

    added = set(new_funcs) - set(old_funcs)
    removed = set(old_funcs) - set(new_funcs)
    modified = set()
    for qn in set(old_funcs) & set(new_funcs):
        if old_funcs[qn].get("body_hash") != new_funcs[qn].get("body_hash"):
            modified.add(qn)
        elif old_funcs[qn].get("line_range") != new_funcs[qn].get("line_range"):
            modified.add(qn)

    return {
        "added": list(added),
        "removed": list(removed),
        "modified": list(modified)
    }
```

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_H4.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Backup estado actual
cp "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_before_h4.json

# 2. Modificar una función existente (sin rebuild manual)
TEST_FILE="$REPO_ROOT/.jcode/lib/handbook_verify.py"
cp "$TEST_FILE" /tmp/verify_backup.py
# Agregar una línea a una función existente
sed -i 's/def verify_candidates/def verify_candidates_renamed/' "$TEST_FILE"
git add -A && git commit -m "test: rename verify_candidates for H-4 test" -q

# 3. Ejecutar resync (sin Phase I manual previo)
output=$(python3 "$JCODE_DIR/lib/handbook_resync.py" --auto 2>&1)
echo "$output"

# 4. Verificar que resync detectó el cambio (no no_op)
echo "$output" | grep -q "no_op" && {
    echo "❌ resync retornó no_op después de rename — H-4 NO arreglado"
    # Restore
    cp /tmp/verify_backup.py "$TEST_FILE"
    git checkout HEAD~1 -- "$TEST_FILE" 2>/dev/null
    exit 1
}

# 5. Verificar que program_graph.json se actualizó
diff "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_before_h4.json > /dev/null && {
    echo "❌ program_graph.json no se actualizó después de resync"
    cp /tmp/verify_backup.py "$TEST_FILE"
    git checkout HEAD~1 -- "$TEST_FILE" 2>/dev/null
    exit 1
}

# 6. Verificar que la función renombrada aparece en el PG actualizado
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
qualnames = [f['qualname'] for f in pg['functions']]
assert 'verify_candidates_renamed' in qualnames or \
       any('verify_candidates_renamed' in q for q in qualnames), \
       '❌ función renombrada no aparece en PG'
print('✅ función renombrada detectada por resync')
"

# 7. Cleanup
cp /tmp/verify_backup.py "$TEST_FILE"
git add -A && git commit -m "test: cleanup H-4 test" -q
git reset --hard HEAD~2 -q  # deshacer los 2 commits de test

echo "✅ H-4: resync detecta cambios sin rebuild manual"
exit 0
```

**Criterio de aprobación H-4**:
- Resync ejecuta Phase I automáticamente
- Detecta renames sin rebuild manual
- `program_graph.json` se actualiza después de resync
- Función renombrada aparece en PG actualizado

**Budget**: 5 iteraciones.

---

### BLOCKER H-5 — Race condition sin locks

**Problema**: `save_json()` escribe sin lock. Resyncs concurrentes pueden perder cambios.

**Fix requerido**:

```python
# .jcode/lib/handbook_resync.py (y otros scripts que escriben JSON)

import fcntl
import tempfile
import os

def save_json_atomic(path: Path, data: dict):
    """Write JSON atomically with file locking."""
    path.parent.mkdir(parents=True, exist_ok=True)

    # FIX H-5: usar lock file para exclusión mutua
    lock_path = path.with_suffix(path.suffix + ".lock")

    with open(lock_path, "w") as lock_file:
        try:
            # Lock exclusivo (blocks hasta adquirir)
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)

            # Escritura atómica: escribir a temp file, luego rename
            with tempfile.NamedTemporaryFile(
                mode="w",
                dir=str(path.parent),
                prefix=path.stem + ".",
                suffix=".tmp",
                delete=False
            ) as tmp_file:
                json.dump(data, tmp_file, indent=2, default=str)
                tmp_path = tmp_file.name

            # Atomic rename (POSIX guarantee)
            os.rename(tmp_path, path)

        finally:
            # Liberar lock
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)

    # Cleanup lock file (opcional, pero limpio)
    try:
        lock_path.unlink()
    except FileNotFoundError:
        pass

# Reemplazar todos los writes JSON con save_json_atomic:
# ANTES:
# (HANDBOOK_DIR / "frozen_entries.json").write_text(json.dumps(data, indent=2))
# DESPUÉS:
# save_json_atomic(HANDBOOK_DIR / "frozen_entries.json", data)
```

**Tests anti-fraude**:

```bash
# .jcode/tests/audit/verify_blocker_H5.sh
#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
JCODE_DIR="$REPO_ROOT/.jcode"

# 1. Verificar que save_json_atomic existe y se usa
grep -q "def save_json_atomic" "$JCODE_DIR/lib/handbook_resync.py" || {
    echo "❌ save_json_atomic no existe en handbook_resync.py"
    exit 1
}
grep -q "fcntl.flock\|fcntl.LOCK_EX" "$JCODE_DIR/lib/handbook_resync.py" || {
    echo "❌ No hay file locking en handbook_resync.py"
    exit 1
}

# 2. Test de concurrencia real: lanzar 5 resyncs en paralelo
echo "[test] Lanzando 5 resyncs concurrentes..."
for i in 1 2 3 4 5; do
    python3 "$JCODE_DIR/lib/handbook_resync.py" --auto > /tmp/resync_$i.log 2>&1 &
done
wait

# 3. Verificar que frozen_entries.json no está corrupto
python3 -c "
import json
try:
    data = json.load(open('$JCODE_DIR/handbook/frozen_entries.json'))
    print(f'✅ JSON válido después de 5 resyncs concurrentes ({len(data)} entries)')
except json.JSONDecodeError as e:
    print(f'❌ JSON corrupto: {e}')
    exit(1)
"

# 4. Verificar que no hay archivos .tmp huérfanos
tmp_files=$(find "$JCODE_DIR/handbook" -name "*.tmp" 2>/dev/null | wc -l)
[[ $tmp_files -eq 0 ]] || {
    echo "❌ $tmp_files archivos .tmp huérfanos (escritura no atómica)"
    exit 1
}

# 5. Verificar que no hay archivos .lock huérfanos
lock_files=$(find "$JCODE_DIR/handbook" -name "*.lock" 2>/dev/null | wc -l)
[[ $lock_files -eq 0 ]] || {
    echo "⚠️  $lock_files archivos .lock huérfanos (posible deadlock)"
    # No es fatal, pero suspicious
}

echo "✅ H-5: escritura atómica con locks funciona"
exit 0
```

**Criterio de aprobación H-5**:
- `save_json_atomic` existe y usa `fcntl.flock`
- 5 resyncs concurrentes no corrompen JSON
- 0 archivos .tmp huérfanos
- Tests de regresión pasan

**Budget**: 5 iteraciones.

---

## Loop de insistencia global

Después de los 8 blockers individuales, ejecutar **loop de insistencia global**:

### Iteración global 1: Re-auditar con audit_metrics.py y audit_security.py

```bash
# 1. Re-ejecutar scripts de auditoría original
python3 analisi-harnes/auditoria-evidencia/audit_metrics.py
python3 analisi-harnes/auditoria-evidencia/audit_security.py

# 2. Verificar que TODOS los hallazgos previos están resueltos
python3 -c "
import json
# Cargar reporte original
with open('analisi-harnes/REPORTE-AUDITORIA-FORENSE.md') as f:
    reporte = f.read()

# Hallazgos esperados a resolver
hallazgos = ['C-1', 'C-2', 'C-3', 'C-4', 'H-1', 'H-2', 'H-3', 'H-4', 'H-5']

# Para cada hallazgo, ejecutar su test de verificación
import subprocess
for h in hallazgos:
    test_file = f'.jcode/tests/audit/verify_blocker_{h}.sh'
    result = subprocess.run(['bash', test_file], capture_output=True, text=True)
    if result.returncode != 0:
        print(f'❌ {h} NO resuelto:')
        print(result.stdout)
        print(result.stderr)
    else:
        print(f'✅ {h} resuelto')
"
```

### Iteración global 2: Tests edge case adicionales

```bash
# 1. Test: rebuild completo desde cero
rm -rf .jcode/handbook
python3 .jcode/lib/handbook_builder.py --repo .
python3 .jcode/lib/handbook_phase2.py
python3 .jcode/lib/handbook_phase3.py
bash .jcode/tests/audit/verify_blocker_C1.sh
bash .jcode/tests/audit/verify_blocker_C2.sh
bash .jcode/tests/audit/verify_blocker_H1.sh
bash .jcode/tests/audit/verify_blocker_H2.sh
bash .jcode/tests/audit/verify_blocker_H3.sh

# 2. Test: resync con diff real
echo "def new_function(): pass" >> .jcode/lib/handbook_builder.py
git add -A && git commit -m "test: add function for resync test"
python3 .jcode/lib/handbook_resync.py --auto
# Verificar que new_function aparece en PG
python3 -c "
import json
pg = json.load(open('.jcode/handbook/program_graph.json'))
assert any('new_function' in f['qualname'] for f in pg['functions']), \
    '❌ resync no detectó nueva función'
print('✅ resync detectó nueva función')
"
git reset --hard HEAD~1  # cleanup

# 3. Test: BGPD end-to-end real
python3 .jcode/lib/handbook_verify.py --request "modificar extract function"
# Debe retornar ≥1 verified site

# 4. Test: 0 contaminación mantenido
bash .jcode/lib/harness.sh check
```

### Iteración global 3: Re-auditoría independiente

```bash
# Re-ejecutar TODOS los tests de auditoría original
for test in .jcode/tests/audit/verify_blocker_*.sh; do
    echo "=== $test ==="
    bash "$test"
    echo "Exit: $?"
    echo ""
done

# Si TODOS pasan, ejecutar audit_security.py original
python3 analisi-harnes/auditoria-evidencia/audit_security.py

# Verificar que 0 hallazgos CRITICAL o HIGH quedan
```

---

## Criterios de aprobación FINAL

El loop de insistencia se considera **completo** solo cuando TODAS estas condiciones se cumplen simultáneamente:

### Tests de blockers (8/8)
- [ ] `verify_blocker_C1.sh` exit 0
- [ ] `verify_blocker_C2.sh` exit 0
- [ ] `verify_blocker_C3.sh` exit 0
- [ ] `verify_blocker_C4.sh` exit 0
- [ ] `verify_blocker_H1.sh` exit 0
- [ ] `verify_blocker_H2.sh` exit 0
- [ ] `verify_blocker_H3.sh` exit 0
- [ ] `verify_blocker_H4.sh` exit 0
- [ ] `verify_blocker_H5.sh` exit 0

### Tests independientes (3/3)
- [ ] `verify_blocker_C1_independiente.sh` exit 0
- [ ] `audit_metrics.py` reporta 0 discrepancias
- [ ] `audit_security.py` reporta 0 CRITICAL/HIGH

### Tests de regresión (todos)
- [ ] `run_all.sh` retorna 10+ pass, 0 fail
- [ ] `harness.sh check` retorna 0 contaminación
- [ ] `smoke_paper_compliance.sh` pasa con aserciones reales (no solo `test -f`)

### Validación end-to-end
- [ ] Rebuild desde cero funciona (rm -rf .jcode/handbook && rebuild)
- [ ] Resync detecta rename sin rebuild manual
- [ ] Resync detecta add/remove function
- [ ] BGPD verify retorna ≥1 verified site con código real
- [ ] 5 resyncs concurrentes no corrompen JSON
- [ ] source_hash verificable (recalculo independiente coincide)

### Calidad del código
- [ ] 0 `eval()`, `exec()`, `__import__()` en scripts del harness
- [ ] 0 hardcoded secrets o paths absolutos
- [ ] Permisos 644 o más restrictivos en archivos handbook
- [ ] Todos los scripts Python tienen `if __name__ == "__main__":` con try/except

---

## Anti-patrones de remediación (PROHIBIDOS)

1. **❌ NO saltar blockers**: cada blocker debe resolverse antes del siguiente.
2. **❌ NO usar "ya está arreglado" sin test**: cada fix necesita test anti-fraude propio + independiente.
3. **❌ NO modificar tests para que pasen**: si un test falla, fix el código, no el test.
4. **❌ NO hardcodear valores esperados en tests**: los tests deben recalcular independientemente.
5. **❌ NO usar `|| true` para forzar pass**: si un comando falla, el test falla.
6. **❌ NO borrar logs de iteraciones fallidas**: se documentan para auditoría.
7. **❌ NO commitear con tests pendientes**: cada commit deja el repo verde.
8. **❌ NO escalar al usuario sin haber agotado las 5 iteraciones**: el budget existe por razón.
9. **❌ NO usar mocks en tests anti-fraude**: los mocks falsean la verificación.
10. **❌ NO aceptar "funciona en mi máquina"**: evidencia reproducible obligatoria.

---

## Reporte final esperado

Al completar el loop de insistencia, el agente debe entregar:

```markdown
# REPORTE DE REMEDIACIÓN CRÍTICA

## Resumen

- **Blockers resueltos**: 9/9 (4 CRITICAL + 5 HIGH)
- **Iteraciones totales**: N
- **Tests creados**: 9 verify_blocker_*.sh + 1 independiente
- **Commits**: N atómicos, uno por blocker + commits de test

## Verificación por blocker

| Blocker | Iteraciones | Test propio | Test independiente | Regresión | Estado |
|---------|-------------|-------------|---------------------|-----------|--------|
| C-1     | N/5         | ✅/❌        | ✅/❌                | ✅/❌      | RESUELTO/BLOQUEADO |
| C-2     | N/5         | ...         | ...                 | ...       | ...    |
| ...     | ...         | ...         | ...                 | ...       | ...    |

## Métricas antes vs después

| Métrica                | Antes (audit) | Después (remediación) |
|------------------------|---------------|----------------------|
| Funciones en PG        | 12            | N (esperado ≥30)     |
| L3 entries             | 11            | N                    |
| Stages con funciones   | 1 (execute)   | N (esperado ≥4)      |
| source_hash vacíos     | 11            | 0                    |
| Call edges a builtins  | ~50           | 0                    |
| State accesses falsos  | 5             | 0                    |
| Resync detecta rename  | No            | Sí                   |
| Race condition segura  | No            | Sí                   |

## Evidencia

- Logs de iteraciones: .jcode/logs/remediation-*.log
- Tests creados: .jcode/tests/audit/verify_blocker_*.sh
- Output de tests independientes: capturado en este reporte

## Veredicto

- [ ] APROBADO — todos los criterios cumplidos, ready para merge
- [ ] APROBADO CON RECOMENDACIONES — algunos MEDIUM/LOW pendientes
- [ ] BLOQUEADO — N blockers no resueltos tras 5 iteraciones cada uno

Si BLOQUEADO, listar blockers pendientes y razón de bloqueo.
```

---

## Cómo empezar

1. **Lean el REPORTE-AUDITORIA-FORENSE.md adjunto** completo. Sin skimming.
2. **Verifiquen que los scripts de auditoría originales están disponibles**:
   - `analisi-harnes/auditoria-evidencia/audit_metrics.py`
   - `analisi-harnes/auditoria-evidencia/audit_security.py`
3. **Empiecen por BLOCKER C-1** (circularidad). Es el más grave y los demás dependen de él.
4. **Por cada blocker**: implementar fix → escribir test propio → ejecutar test propio → si pasa, ejecutar test independiente → si pasa, ejecutar regresión → si pasa, commit → siguiente blocker.
5. **Si cualquier test falla**: iterar (máximo 5 por blocker). Documentar cada iteración en log.
6. **Si agotan 5 iteraciones**: escalar al usuario con evidencia.

**Regla de oro**: la confianza se gana con evidencia, no con afirmaciones. Cada claim debe estar respaldado por output de comando reproducible.

---

**Tiempo estimado**: 3-5 días (1-2 dev full-time) si todo va bien. Más si hay blockers que escalan.

**Fin del prompt de remediación con loop de insistencia.**
