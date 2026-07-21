#!/usr/bin/env bash
# Test independiente: recalcula cada mecanismo desde ground truth
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== Frontier Quality INDEPENDIENTE ==="

echo "[1] Verificar config.toml parsea bien..."
JCODE_DIR="$REPO_ROOT/.jcode" python3 << 'PYEOF'
import os, tomllib
with open(os.path.expanduser(os.environ['JCODE_DIR']+'/config.toml'),'rb') as f:
    c = tomllib.load(f)
assert 'policy' in c, 'falta policy'
assert 'effort_routing' in c['policy'], 'falta effort_routing'
assert 'frontier_quality' in c['policy'], 'falta frontier_quality'
fq = c['policy']['frontier_quality']
required = ['require_self_critique', 'require_evidence_bundle',
            'auto_spawn_reviewer', 'reasoning_trace']
for r in required:
    assert r in fq, f'falta {r}'
    assert fq[r] is True, f'{r} no es True'
er = c['policy']['effort_routing']
for cls in ['MICROFIX','SLICE','REMEDIATION','PHASE-CLOSE','AUDIT']:
    assert cls in er, f'falta effort_routing[{cls}]'
    assert er[cls] in ['low','medium','high'], f'effort {cls} inválido'
print(f'  Effort mapping: {er}')
PYEOF
[[ $? -eq 0 ]] || fail "config.toml no parsea bien"
pass "config.toml OK"

echo "[2] Verificar evidence_bundle.sh existe y es ejecutable..."
[[ -x "$JCODE_DIR/lib/evidence_bundle.sh" ]] || fail "evidence_bundle.sh no ejecutable"
pass "evidence_bundle.sh presente"

echo "[3] Verificar turnend.sh referencia frontier_quality..."
grep -q "policy.frontier_quality" "$JCODE_DIR/hooks/turnend.sh" || fail "turnend.sh no referencia frontier_quality"
grep -q "SELF-CRITIQUE\|self_critique" "$JCODE_DIR/hooks/turnend.sh" || fail "Falta SELF-CRITIQUE"
grep -q "evidence_bundle" "$JCODE_DIR/hooks/turnend.sh" || fail "Falta evidence_bundle"
grep -q "REVIEWER REQUIRED\|reviewer_required" "$JCODE_DIR/hooks/turnend.sh" || fail "Falta REVIEWER"
pass "turnend.sh 3 mecanismos"

echo "[4] Verificar posttool.sh tiene reasoning_trace..."
grep -q "reasoning_trace" "$JCODE_DIR/hooks/posttool.sh" || fail "posttool.sh sin reasoning_trace"
grep -q "trace-.*log" "$JCODE_DIR/hooks/posttool.sh" || fail "posttool.sh sin trace log"
pass "posttool.sh trace OK"

echo "[5] Verificar swarm-prompt.md..."
grep -q "quality-preamble.md" "$JCODE_DIR/swarm-prompt.md" || fail "swarm-prompt sin preamble ref"
grep -q "SELF-APPLICATION" "$JCODE_DIR/swarm-prompt.md" || fail "sin SELF-APPLICATION"
grep -q "Reasoning explícito" "$JCODE_DIR/swarm-prompt.md" || fail "sin Reasoning explícito"
pass "swarm-prompt.md OK"

echo "[6] Cross-check: evidence_bundle.sh usa run_all.sh internamente..."
grep -q "run_all.sh" "$JCODE_DIR/lib/evidence_bundle.sh" || fail "evidence_bundle sin regresión"
pass "evidence_bundle integra run_all.sh"

echo ""
echo "✅ Frontier Quality INDEPENDIENTE: 5 mecanismos activos"
exit 0
