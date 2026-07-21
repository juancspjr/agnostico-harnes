#!/usr/bin/env bash
# =============================================================================
# .jcode/hooks/sessionstart.sh — Inicio de sesión (mínimo, agnóstico)
# =============================================================================
# Bug fixed: eliminado go build (era lock-in Go).
# Bug fixed: eliminado session_safety_check.sh (era 100% específico del proyecto).
# Bug fixed: eliminado coordinator_self_repair.sh (tenía bugs de spawn).
# Bug fixed: eliminado banner 25 líneas a stderr.
# =============================================================================

set -uo pipefail

REPO_ROOT="${JCODE_HOOK_CWD:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

# Source state manager
source "$JCODE_DIR/lib/state_manager.sh"

# 1. Init state
state_init
state_set session_id "\"${JCODE_SESSION_ID:-session_$(date +%s)_$$}\""
state_set turn 0
state_set reads_this_turn 0

# 2. Integrity check (sin run_all.sh — instantáneo)
missing_hooks=0
for h in sessionstart turn_start turnend posttool; do
  if [[ ! -x "$JCODE_DIR/hooks/$h.sh" ]]; then
    missing_hooks=$((missing_hooks + 1))
  fi
done

if [[ $missing_hooks -gt 0 ]]; then
  echo "[sessionstart] WARN: $missing_hooks hooks faltantes o no ejecutables" >&2
  # Intentar git restore de hooks (reemplazo minimalista de coordinator_self_repair)
  if command -v git >/dev/null && [[ -d "$REPO_ROOT/.git" ]]; then
    (cd "$REPO_ROOT" && git checkout -- .jcode/hooks/ 2>/dev/null) || true
  fi
fi

# 3. Banner mínimo (3 líneas máximo, no 25)
cat <<EOF
[sessionstart] session=${JCODE_SESSION_ID:-unknown}
[sessionstart] repo=$REPO_ROOT
[sessionstart] Read AGENTS.md + PROJECT.md + .jcode/AGENT-PROTOCOL.md
EOF

exit 0
