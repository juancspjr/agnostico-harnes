#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== Frontier Quality Automation ==="

echo "[1] Effort routing en config.toml..."
grep -q "policy.effort_routing" "$JCODE_DIR/config.toml" || fail "Falta effort_routing"
grep -q "MICROFIX" "$JCODE_DIR/config.toml" || fail "Falta MICROFIX mapping"
pass "Effort routing configurado"

echo "[2] Frontier quality flags..."
grep -q "require_self_critique" "$JCODE_DIR/config.toml" || fail "Falta require_self_critique"
grep -q "require_evidence_bundle" "$JCODE_DIR/config.toml" || fail "Falta evidence_bundle"
grep -q "auto_spawn_reviewer" "$JCODE_DIR/config.toml" || fail "Falta auto_spawn_reviewer"
grep -q "reasoning_trace" "$JCODE_DIR/config.toml" || fail "Falta reasoning_trace"
pass "4 flags de frontier_quality activos"

echo "[3] evidence_bundle.sh existe y funciona..."
[[ -x "$JCODE_DIR/lib/evidence_bundle.sh" ]] || fail "evidence_bundle.sh no ejecutable"
output=$(bash "$JCODE_DIR/lib/evidence_bundle.sh" L-TEST 2>&1)
[[ "$?" -eq 0 ]] || fail "evidence_bundle.sh falló"
echo "$output" | grep -q "escrito" || fail "No escribió bundle"
pass "evidence_bundle.sh funcional"

echo "[4] turnend.sh invoca frontier quality..."
grep -q "SELF-CRITIQUE" "$JCODE_DIR/hooks/turnend.sh" || fail "Falta SELF-CRITIQUE"
grep -q "evidence_bundle.sh" "$JCODE_DIR/hooks/turnend.sh" || fail "Falta evidence_bundle"
grep -q "REVIEWER REQUIRED" "$JCODE_DIR/hooks/turnend.sh" || fail "Falta REVIEWER"
pass "3 mecanismos en turnend.sh"

echo "[5] posttool.sh captura reasoning trace..."
grep -q "trace-" "$JCODE_DIR/hooks/posttool.sh" || fail "Falta trace en posttool"
grep -q "reasoning_trace" "$JCODE_DIR/hooks/posttool.sh" || fail "Falta config_get reasoning"
pass "Reasoning trace en posttool.sh"

echo "[6] swarm-prompt.md tiene reasoning explícito..."
grep -q "Reasoning explícito" "$JCODE_DIR/swarm-prompt.md" || fail "Falta sección reasoning"
pass "Reasoning explícito en swarm-prompt.md"

echo ""
echo "✅ Frontier Quality: 5 mecanismos activos"
exit 0
