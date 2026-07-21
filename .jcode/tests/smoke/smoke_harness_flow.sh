#!/usr/bin/env bash
# =============================================================================
# smoke_harness_flow.sh — Valida estructura canónica del harness
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# 1. Archivos canónicos existen
for f in PRINCIPLES.md AGENT-PROTOCOL.md LOOPS.md README.md config.toml mcp.json; do
  [[ -f "$JCODE_DIR/$f" ]] || fail "Falta archivo canónico: $f"
done
pass "6 archivos canónicos presentes"

# 2. 4 hooks ejecutables
missing=0
for h in sessionstart turn_start turnend posttool; do
  [[ -x "$JCODE_DIR/hooks/$h.sh" ]] || missing=$((missing + 1))
done
[[ $missing -eq 0 ]] || fail "$missing hooks faltantes o no ejecutables"
pass "4 hooks bash ejecutables"

# 3. compliance.json válido
[[ -f "$JCODE_DIR/state/compliance.json" ]] || fail "Falta compliance.json"
python3 -c "import json; json.load(open('$JCODE_DIR/state/compliance.json'))" 2>/dev/null \
  || fail "compliance.json inválido"
pass "compliance.json válido"

# 4. Score ≤ 100
score=$(bash "$JCODE_DIR/lib/state_manager.sh" score 2>/dev/null || echo "0")
[[ $score -le 100 ]] || fail "Score fuera de rango: $score"
pass "Score en rango (≤100): $score/100"

echo "smoke_harness_flow: OK"
exit 0