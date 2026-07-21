#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_H3.sh — State accesses reales ==="

echo "[1] Rebuilding PG..."
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1

echo "[2] Checking state_accesses..."
python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
sa = pg['state_accesses']
known_methods = ['_extract_from_tree', '_record_function', '_extract_calls',
                 '_get_call_name', '_is_assign_target', '_compute', '_build_']
method_access = [s for s in sa if s['attribute'].replace('self.', '') in known_methods]
assert len(method_access) == 0, f'{len(method_access)} methods in state: {method_access}'
print(f'  State accesses: {len(sa)}')
print(f'  Methods filtered: {len(method_access)}')
for s in sa:
    assert s['access'] in ('read', 'write'), f'Invalid access: {s[\"access\"]}'
print('  ✅ All state_accesses are real')
"
[[ $? -eq 0 ]] || fail "State access check failed"
pass "state_accesses sin métodos"
echo ""
echo "✅ H-3: state accesses reales"
exit 0
