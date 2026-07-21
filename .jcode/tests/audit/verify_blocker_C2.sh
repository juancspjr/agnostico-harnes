#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_C2.sh — Distribución de stages ==="

# 1. Rebuild Phase II
echo "[1] Running Phase II..."
python3 "$JCODE_DIR/lib/handbook_phase2.py" 2>&1

# 2. Verificar distribución
echo "[2] Checking stage distribution..."
python3 -c "
import json
from collections import Counter

bm = json.load(open('$JCODE_DIR/handbook/behavioral_mapping.json'))
assignments = bm['function_assignments']

stages = Counter()
for fa in assignments:
    for s in fa.get('stage_assignments', []):
        stages[s] += 1

print(f'Distribution: {dict(stages)}')
total_assigned = sum(stages.values())
n_stages = len(stages)

# ≥4 stages
assert n_stages >= 4, f'❌ Only {n_stages} stages (expected ≥4)'

# max stage ≤ 70%
for stage, count in stages.items():
    pct = count / total_assigned * 100
    print(f'  {stage}: {count}/{total_assigned} = {pct:.0f}%')
    assert pct <= 70, f'❌ {stage} has {pct:.0f}% (expected ≤70%)'

# Unmapped may exist
unmapped = bm.get('coverage_record', {}).get('unmapped_functions', [])
print(f'  Unmapped: {len(unmapped)}')

print('✅ Distribution valid: {n_stages} stages, max {max(pct for pct in ...):.0f}%')
"
[[ $? -eq 0 ]] || fail "Stage distribution check failed"
pass "Distribución de stages correcta"

echo ""
echo "✅ C-2: distribución de stages no artificial"
exit 0
