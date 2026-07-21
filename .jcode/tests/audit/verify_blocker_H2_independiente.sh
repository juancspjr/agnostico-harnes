#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== H-2 INDEPENDIENTE: call edges sin builtins ==="

python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1

python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
edges = pg['call_edges']
n_func = len(pg['functions'])

# Buscar tipos de builtins conocidos
builtins = {'split','join','strip','startswith','endswith','append','write',
            'read','load','dump','print','len','range','open','isinstance'}
found = {e['callee'] for e in edges if e['callee'] in builtins}
assert len(found) == 0, f'{len(found)} builtins: {found}'

# Ratio
ratio = len(edges) / n_func
print(f'Total edges: {len(edges)}, ratio: {ratio:.2f}')
assert ratio <= 5.0, f'Ratio {ratio:.2f} > 5.0'
"
[[ $? -eq 0 ]] || fail "H-2 independiente falló"
pass "H-2: 0 builtins, ratio OK"
exit 0
