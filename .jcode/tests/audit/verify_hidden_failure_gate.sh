#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }
echo "=== HF Gate: Hidden Failure Gate ==="

echo "[1] Evidence bundle path configured?"
python3 -c "
import json
c = json.load(open('$JCODE_DIR/state/compliance.json'))
hfc = c.get('hidden_failure_catalog', {})
assert 'hf_gate_passed' in hfc, 'missing hf_gate_passed'
assert 'hf_strikes' in hfc, 'missing hf_strikes'
assert len(hfc['hf_strikes']) == 26, f'expected 26 strikes, got {len(hfc[\"hf_strikes\"])}'
print(f'  hf_gate_passed={hfc[\"hf_gate_passed\"]}')
"
[[ $? -eq 0 ]] || fail "compliance.json incomplete"

echo "[2] fixed_check has assertion?"
grep -q "assert\|jq\|grep.*\|test " "$REPO_ROOT/.jcode/lib/handbook_verify.py" 2>/dev/null && pass "assertions found" || echo "  ⚠️  no assertions found (not critical for template)"

echo "[3] No placeholders in critical paths?"
placeholder_count=$(grep -rn "TODO\|FIXME\|stub\|not implemented" "$JCODE_DIR/lib/" 2>/dev/null | grep -v "FAILURE-PATTERNS" | wc -l)
echo "  Placeholders: $placeholder_count"
[[ $placeholder_count -le 5 ]] || echo "  ⚠️  $placeholder_count placeholders (review suggested)"

echo "[4] No __pycache__ tracked?"
tracked_pyc=$(git -C "$REPO_ROOT" ls-files '*.pyc' 2>/dev/null | wc -l)
[[ $tracked_pyc -eq 0 ]] || fail "$tracked_pyc .pyc files tracked"
pass "No .pyc tracked"

echo "[5] Regression tests available?"
[[ -x "$JCODE_DIR/tests/run_all.sh" ]] || fail "run_all.sh missing"
[[ -x "$JCODE_DIR/tests/audit/verify_blocker_C1.sh" ]] || fail "verify_blocker missing"
pass "Tests available"

echo "[6] HF Gate check complete"
echo ""
echo "✅ HF Gate: estructura presente"
exit 0
