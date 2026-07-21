#!/usr/bin/env bash
# =============================================================================
# smoke_r_aa_1.sh — Valida que R-AA-1 anti-autoengaño funciona
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"
STATE_FILE="$JCODE_DIR/state/compliance.json"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# Backup
[[ -f "$STATE_FILE" ]] && cp "$STATE_FILE" "$STATE_FILE.bak"

# 1. Obtener conteo actual de violaciones
before=$(python3 -c "
import json
try:
    d = json.load(open('$STATE_FILE'))
    print(len(d.get('aa1_violations', [])))
except Exception:
    print(0)
" 2>/dev/null || echo 0)

# 2. Simular strike (commit sin SRSI previo)
bash "$JCODE_DIR/lib/state_manager.sh" strike "srsi_missing" "smoke test" >/dev/null 2>&1

# 3. Verificar que aa1_violations se incrementó
after=$(python3 -c "
import json
try:
    d = json.load(open('$STATE_FILE'))
    print(len(d.get('aa1_violations', [])))
except Exception:
    print(0)
" 2>/dev/null || echo 0)

if [[ $after -le $before ]]; then
  # Cleanup y fail
  [[ -f "$STATE_FILE.bak" ]] && mv "$STATE_FILE.bak" "$STATE_FILE"
  fail "aa1_violations no incrementó: before=$before after=$after"
fi
pass "aa1_violations incrementó: $before → $after"

# 4. Verificar r_aa_1_strikes también se incrementó
strikes=$(bash "$JCODE_DIR/lib/state_manager.sh" get r_aa_1_strikes 2>/dev/null || echo "0")
[[ $strikes -gt 0 ]] || fail "r_aa_1_strikes sigue en 0"
pass "r_aa_1_strikes = $strikes"

# Cleanup
[[ -f "$STATE_FILE.bak" ]] && mv "$STATE_FILE.bak" "$STATE_FILE"

echo "smoke_r_aa_1: OK"
exit 0