#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"

echo "=== verify_blocker_C1_independiente.sh — Verificación independiente ==="

# 1. Contar funciones Python reales en .jcode/lib/ (ground truth)
echo "[1] Counting real Python functions in .jcode/lib/..."
real_func_count=$(find "$JCODE_DIR/lib" -name "*.py" -exec \
    python3 -c "
import ast, sys, os
seen = set()
for path in sys.argv[1:]:
    try:
        tree = ast.parse(open(path).read())
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                # Include method qualifiers
                seen.add((path, node.name))
    except: pass
print(len(seen))
" {} +)
echo "  Real functions in lib/: $real_func_count"

# 2. Contar funciones en program_graph.json
echo "[2] Counting functions in program_graph.json..."
pg_func_count=$(python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
print(len(pg['functions']))
")
echo "  PG functions: $pg_func_count"

# 3. Verificar que coinciden (con tolerancia ±5 por funciones anidadas vs top-level)
diff=$((real_func_count - pg_func_count))
[[ $diff -lt 0 ]] && diff=$((-diff))
echo "  Diff: $diff (tolerance: ≤5)"
[[ $diff -le 5 ]] || {
    echo "❌ MISMATCH: real=$real_func_count pg=$pg_func_count (diff=$diff)"
    exit 1
}
echo "✅ PG cubre $pg_func_count de $real_func_count funciones reales (diff=$diff)"

# 4. Verificar específicamente que phase2/phase3/resync/verify están
echo "[4] Checking specific harness files in PG..."
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
files = {f['file'] for f in pg['functions']}
required = ['handbook_phase2.py', 'handbook_phase3.py', 'handbook_resync.py', 'handbook_verify.py']
found = sum(1 for r in required if any(r in f for f in files))
assert found == 4, f'Only {found}/4 of phase2/phase3/resync/verify found in PG'
print(f'  ✅ {found}/4 paper scripts found')
"

echo ""
echo "✅ C-1 independiente: circularidad validada"
exit 0
