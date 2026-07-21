#!/usr/bin/env bash
# Test independiente: recalcula desde ground truth
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }
echo "=== HF Gate INDEPENDIENTE ==="

echo "[1] Verifying compliance.json structure..."
python3 -c "
import json
c = json.load(open('$JCODE_DIR/state/compliance.json'))
hfc = c.get('hidden_failure_catalog', {})
assert 'hf_gate_passed' in hfc, 'missing hf_gate_passed'
assert 'hf_evidence_bundle_path' in hfc, 'missing evidence_bundle_path'
assert 'hf_strikes' in hfc, 'missing hf_strikes'
all_strikes = hfc['hf_strikes']
required = ['HF-V1','HF-V2','HF-V3','HF-V4','HF-V5','HF-V6',
            'HF-S1','HF-S2','HF-S3','HF-S4','HF-S5',
            'HF-E1','HF-E2','HF-E3','HF-E4','HF-E5','HF-E6','HF-E7','HF-E8',
            'HF-G1','HF-G2','HF-G3','HF-G4','HF-G5','HF-G6','HF-G7']
for r in required:
    assert r in all_strikes, f'Missing {r}'
    assert all_strikes[r] == 0, f'{r} strike > 0 en inicio'
print(f'  OK: {len(required)} strikes, all 0')
"
[[ $? -eq 0 ]] || fail "compliance estructura incorrecta"

echo "[2] Verifying HF Gate normativo en PRINCIPLES.md..."
grep -q "R-HIDDEN-FAILURE-CATALOG" "$JCODE_DIR/PRINCIPLES.md" || fail "Falta R-HIDDEN-FAILURE-CATALOG"
grep -q "HF Gate" "$JCODE_DIR/PRINCIPLES.md" || fail "Falta HF Gate en glosario"
pass "PRINCIPLES.md referencias OK"

echo "[3] Verifying HF checklist en AGENT-PROTOCOL.md..."
grep -q "HF1." "$JCODE_DIR/AGENT-PROTOCOL.md" || fail "Falta HF1 en checklist"
grep -q "HF12." "$JCODE_DIR/AGENT-PROTOCOL.md" || fail "Falta HF12 en checklist"
pass "AGENT-PROTOCOL.md checklist HF OK"

echo "[4] Verifying policy en config.toml..."
grep -q "policy.hidden_failures" "$JCODE_DIR/config.toml" || fail "Falta policy.hidden_failures"
grep -q "enabled = true" "$JCODE_DIR/config.toml" || fail "policy no enabled"
pass "config.toml policy OK"

echo "[5] Verifying PLAN-VIVO.md existe..."
[[ -f "$JCODE_DIR/iterations/PLAN-VIVO.md" ]] || fail "Falta PLAN-VIVO.md"
pass "PLAN-VIVO.md activo"

echo ""
echo "✅ HF Gate INDEPENDIENTE: todo OK"
exit 0
