#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== C-2 INDEPENDIENTE: distribución stages ==="

python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1
python3 "$JCODE_DIR/lib/handbook_phase2.py" > /dev/null 2>&1

# Recalcular distribución independentemente desde behavioral_mapping.json
python3 -c "
import json
bm = json.load(open('$JCODE_DIR/handbook/behavioral_mapping.json'))
fa = bm['function_assignments']
stages = {}
for f in fa:
    for s in f.get('stage_assignments', []):
        stages[s] = stages.get(s, 0) + 1
total_assigned = sum(stages.values())
n_stages = len(stages)
unmapped = bm.get('coverage_record', {}).get('unmapped_functions', [])

# Criterios (NO hardcodeados):
assert n_stages >= 4, f'Only {n_stages} stages'
for stage, count in stages.items():
    pct = count / total_assigned * 100
    assert pct <= 70, f'{stage} has {pct:.0f}%'
# Debe haber al menos algunas unmapped (la heurística no cubre todo)
assert len(unmapped) >= 5, f'Only {len(unmapped)} unmapped — sospechoso'

print(f'Stages: {n_stages}, distribution: {dict(stages)}')
print(f'Max: {max(stages.values())/total_assigned*100:.0f}%')
print(f'Unmapped: {len(unmapped)}')
"
[[ $? -eq 0 ]] || fail "C-2 independiente falló"
pass "C-2: distribución validada independientemente"
exit 0
