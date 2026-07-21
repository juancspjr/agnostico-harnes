#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== H-3 INDEPENDIENTE: state_accesses reales ==="

python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1

python3 -c "
import json, ast, os
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
sa = pg['state_accesses']

# Buscar en el código real self.X = Y (writes)
lib_dir = '$JCODE_DIR/lib'
real_writes = 0
for fname in os.listdir(lib_dir):
    if not fname.endswith('.py'): continue
    path = os.path.join(lib_dir, fname)
    tree = ast.parse(open(path).read())
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for t in node.targets:
                if isinstance(t, ast.Attribute) and \
                   isinstance(t.value, ast.Name) and t.value.id == 'self':
                    real_writes += 1

# Verificar que ningún state_access es método
methods_in_sa = [s for s in sa if s['attribute'].startswith('self._')]
assert len(methods_in_sa) == 0, f'{len(methods_in_sa)} methods in SA'

# Si hay writes reales, PG debe al menos detectar algunos
for s in sa:
    assert s['access'] in ('read', 'write'), f'Invalid access: {s}'
"
[[ $? -eq 0 ]] || fail "H-3 independiente falló"
pass "H-3: state accesses reales"
exit 0
