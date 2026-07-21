#!/usr/bin/env bash
# =============================================================================
# .jcode/hooks/turn_start.sh — Inicio de turno (mínimo)
# =============================================================================
# Bug fixed: eliminada llamada a state_record_violation (no existía).
#           Ahora llama a state_record_strike (correcto).
# =============================================================================

set -uo pipefail

REPO_ROOT="${JCODE_HOOK_CWD:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

source "$JCODE_DIR/lib/state_manager.sh"

# 1. Bumpear turno
state_new_turn

# 2. Reminder (5 líneas máximo)
cat <<EOF
[turn_start] turn=$(state_get turn)
[turn_start] Checklist: SRSI → DDLP → scope → backend↔frontend → §6 → fixed_check → autojudge
[turn_start] Loop actual: $(state_get current_loop_id) ($(state_get current_loop_iter)/$(state_get current_loop_budget))
EOF

# 3. Si hay strikes previos, alertar
strikes=$(state_get r_aa_1_strikes)
if [[ $strikes -ge 2 ]]; then
  echo "[turn_start] 🚨 $strikes strikes acumulados — activar R-3STRIKE-MVP" >&2
fi

exit 0
