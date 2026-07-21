#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_H2.sh — Call edges sin builtins ==="

echo "[1] Rebuilding PG..."
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1

echo "[2] Checking for builtins in call_edges..."
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
edges = pg['call_edges']
builtins_to_check = ['split', 'join', 'match', 'startswith', 'strip',
                     'append', 'write', 'read', 'load', 'print', 'len',
                     'range', 'enumerate', 'open', 'isinstance', 'sorted']
found = [e['callee'] for e in edges if e['callee'] in builtins_to_check]
assert len(found) == 0, f'{len(found)} builtins found: {set(found)}'
print(f'  Edges: {len(edges)}, builtins: 0 ✅')
"

echo "[3] Checking ratio calls/function ≤ 5.0..."
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
ratio = len(pg['call_edges']) / len(pg['functions'])
print(f'  Ratio: {ratio:.2f}')
assert ratio <= 5.0, f'Ratio {ratio:.2f} > 5.0'
print('  ✅ Ratio OK')
"
[[ $? -eq 0 ]] || fail "H-2 verification failed"
pass "0 builtins in call edges, ratio ≤ 5.0"
echo ""
echo "✅ H-2: call edges sin builtins"
exit 0
