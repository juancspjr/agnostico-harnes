#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_C1.sh — Circularidad del handbook ==="

# 1. Rebuild handbook desde cero
echo "[1] Rebuilding handbook..."
rm -rf "$JCODE_DIR/handbook/program_graph.json"
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" 2>&1 | tee /tmp/c1_rebuild.log

# 2. Verificar que program_graph.json tiene 30+ funciones
echo "[2] Checking function count (≥30)..."
func_count=$(python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
print(len(pg['functions']))
")
echo "  Functions: $func_count"
[[ $func_count -ge 30 ]] || fail "Solo $func_count funciones (esperado ≥30)"
pass "Funciones: $func_count (esperado ≥30)"

# 3. Verificar que los 6 scripts del harness están en PG
echo "[3] Checking harness scripts coverage..."
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
all_ok = True
for r in required:
    if any(f.endswith(r) for f in files):
        print(f'  ✅ {r}')
    else:
        print(f'  ❌ FALTA: {r}')
        all_ok = False
if not all_ok:
    exit(1)
"
[[ $? -eq 0 ]] || fail "Faltan scripts del harness en PG"
pass "Todos los 6 scripts del harness en PG"

# 4. Verificar que phase2/phase3/resync/verify tienen funciones
echo "[4] Checking non-zero functions per harness script..."
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
from collections import Counter
files = Counter(f['file'] for f in pg['functions'])
for fname in ['.jcode/lib/handbook_phase2.py', '.jcode/lib/handbook_phase3.py',
              '.jcode/lib/handbook_resync.py', '.jcode/lib/handbook_verify.py']:
    count = files.get(fname, 0)
    assert count > 0, f'{fname}: 0 funciones'
    print(f'  ✅ {fname}: {count} funciones')
"
[[ $? -eq 0 ]] || fail "Scripts del paper sin funciones en PG"
pass "Todos los scripts tienen funciones en PG"

echo ""
echo "✅ C-1: handbook escanea 100% del harness"
exit 0
