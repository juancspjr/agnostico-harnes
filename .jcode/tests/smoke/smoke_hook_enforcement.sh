#!/usr/bin/env bash
# =============================================================================
# smoke_hook_enforcement.sh — Valida detectores del hook posttool.sh
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"
STATE_FILE="$JCODE_DIR/state/compliance.json"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# Backup del state
[[ -f "$STATE_FILE" ]] && cp "$STATE_FILE" "$STATE_FILE.bak"

# 1. Simular tool=grep/rg → marcar srsi_done_this_turn=true
# Verificar lógica inspeccionando el código (case grep|rg|agentgrep|ripgrep)
grep -q "grep|rg|agentgrep|ripgrep)" "$JCODE_DIR/hooks/posttool.sh" \
  || fail "posttool.sh no detecta tool=grep/rg para SRSI"
pass "posttool.sh detecta grep/rg y marca SRSI"

# 2. Detecta git commit sin SRSI previo → strike R-AA-1
grep -q "state_record_srsi_violation" "$JCODE_DIR/hooks/posttool.sh" \
  || fail "posttool.sh no llama state_record_srsi_violation"
pass "posttool.sh llama state_record_srsi_violation"

# 3. Verificar función state_record_srsi_violation existe en state_manager.sh
grep -q "state_record_srsi_violation" "$JCODE_DIR/lib/state_manager.sh" \
  || fail "state_manager.sh no define state_record_srsi_violation"
pass "state_manager.sh define state_record_srsi_violation"

# 4. Verificar que turnend.sh también audita SRSI
grep -q "srsi_done" "$JCODE_DIR/hooks/turnend.sh" \
  || fail "turnend.sh no audita srsi_done"
pass "turnend.sh audita srsi_done"

# Cleanup
[[ -f "$STATE_FILE.bak" ]] && mv "$STATE_FILE.bak" "$STATE_FILE"

echo "smoke_hook_enforcement: OK"
exit 0