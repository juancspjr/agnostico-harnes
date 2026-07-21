#!/usr/bin/env bash
# =============================================================================
# .jcode/hooks/posttool.sh — Post-tool call (mínimo: solo log + tracking)
# =============================================================================
# Bug fixed: eliminado posttool_auto_compile.sh (era stack lock-in Go+Astro+Docker).
# Bug fixed: eliminado smoke_e2e_playwright.sh en cada edit frontend (catastrófico).
# Bug fixed: eliminada dependencia token_watchdog.sh (no existía).
# Bug fixed: eliminada dependencia scripts/autojudge.sh (no existía).
# =============================================================================

set -uo pipefail

REPO_ROOT="${JCODE_HOOK_CWD:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"
LOG_FILE="$JCODE_DIR/logs/post_tool.log"

mkdir -p "$JCODE_DIR/logs"

source "$JCODE_DIR/lib/state_manager.sh"

# 0. Helper: detect docs-only commit (bumpeo §28.7-bis 2026-07-18)
# Returns 0 (true) if:
#   - commit message starts with docs: / chore(docs): / docs(<scope>): / chore(<docs-scope>):
#   - AND no code file extensions (.go .ts .astro .tsx .jsx .sql .svelte .css .scss .vue)
#     appear in the args
# Used by SRSI + R-FAKE-COORDINATOR detectors to skip false positives on doc-only commits.
is_docs_only_commit() {
  local args="$1"
  # 1) No code extensions in args → candidate docs-only
  if echo "$args" | grep -qE '\.(go|ts|astro|tsx|jsx|sql|svelte|css|scss|vue)( |"|$|\.)'; then
    return 1
  fi
  # 2) Commit message prefix matches docs-only convention
  if echo "$args" | grep -qE 'git\s+commit.*(-m|--message)\s*[\\'\''""]?(docs|chore\(docs\))'; then
    return 0
  fi
  return 1
}

# 1. Log del tool call (sin auto-compile, sin E2E)
tool_name="${JCODE_TOOL_NAME:-unknown}"
tool_args="${JCODE_TOOL_ARGS:-}"
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "[$ts] tool=$tool_name args=${tool_args:0:200}" >> "$LOG_FILE"

# 2. Tracking reads (cualquier tool call cuenta como read para scoring)
state_record_read

# 3. SRSI detection: si el tool es grep/rg, marcar srsi_done
case "$tool_name" in
  grep|rg|agentgrep|ripgrep)
    state_set srsi_done_this_turn true
    ;;
esac

# 4. Detección de commit sin SRSI (E4)
# Bumpeo §28.7-bis (2026-07-18): skip docs-only commits (R-FAKE-COORDINATOR fix).
# Docs-only = no code file extensions in args AND commit message prefix "docs:"/"chore(docs):"
if [[ "$tool_name" == "bash" ]] && echo "$tool_args" | grep -qE 'git\s+commit'; then
  if is_docs_only_commit "$tool_args"; then
    echo "[posttool] 📝 commit docs-only detectado — SRSI + R-FAKE-COORDINATOR skipped" >&2
  else
    srsi=$(state_get srsi_done_this_turn)
    if [[ "$srsi" != "true" ]]; then
      # Verificar si hubo grep en los últimos 5 min en el log
      if ! grep -qE 'tool=(grep|rg|agentgrep)' "$LOG_FILE" 2>/dev/null || \
         ! tail -50 "$LOG_FILE" 2>/dev/null | grep -qE 'tool=(grep|rg|agentgrep)'; then
        state_record_srsi_violation
        echo "[posttool] 🚨 git commit sin SRSI previo — strike R-AA-1 registrado" >&2
      fi
    fi
  fi
fi

# 4. Tracking de swarm spawns — bumpeo §28.7 (R-FAKE-COORDINATOR detector)
# Si el tool call es swarm (spawn/assign/run_plan), registramos role + turn
if [[ "$tool_name" == "swarm" ]] || echo "$tool_args" | grep -qE 'swarm_spawn|swarm\s+spawn|action=.spawn'; then
  # Extraer label/role del tool_args (heurística: primer string entre comillas/guiones)
  role=$(echo "$tool_args" | grep -oE 'label[=:]"[^"]+"' | head -1 | sed -E 's/label[=:]"//;s/"$//')
  if [[ -z "$role" ]]; then
    role=$(echo "$tool_args" | grep -oE 'role[=:]"[^"]+"' | head -1 | sed -E 's/role[=:]"//;s/"$//')
  fi
  if [[ -z "$role" ]]; then
    role="unknown"
  fi
  prompt_size=$(echo -n "$tool_args" | wc -c)
  state_record_swarm_spawn "$role" "$prompt_size"
fi

# 4b. Detección R-FAKE-COORDINATOR: commit a código de implementación
#     (*.go / *.ts / *.astro / *.tsx / *.jsx / *.sql / *.svelte)
#     SIN swarm spawn reciente (≤30 turns) registrado en state.
#     Bug fix arquitecto ram §28.7 (HIGH): antes leía tail post_tool.log
#     que NO contiene eventos swarm → falso positivo garantizado.
#     Bug fix arquitecto ram §28.7 (HIGH): bypass clause explícita:
#       --coord-self-authorize o --fake-coordinator-override en tool args.
#     Bumpeo §28.7-bis (2026-07-18): skip docs-only commits (R-NEW-6).
if [[ "$tool_name" == "bash" ]] && echo "$tool_args" | grep -qE 'git\s+commit'; then
  # Bypass clause §4.7 — agente declara self-authorize explícito en args
  if echo "$tool_args" | grep -qE '\-\-coord-self-authorize|\-\-fake-coordinator-override'; then
    echo "[posttool] ✅ bypass clause §4.7 activa: --coord-self-authorize en commit args" >&2
  elif is_docs_only_commit "$tool_args"; then
    echo "[posttool] 📝 commit docs-only detectado — R-FAKE-COORDINATOR skipped" >&2
  elif echo "$tool_args" | grep -qE '\.(go|ts|astro|tsx|jsx|sql|svelte|css|scss|vue)( |"|$)'; then
    if ! state_swarm_recent_within_turns 30; then
      state_record_strike "R-FAKE-COORDINATOR" "commit a codigo fuente sin swarm worker/arquitecto reciente (<=30 turns)"
      echo "[posttool] 🚨 commit a código fuente SIN swarm worker/arquitecto reciente — strike R-FAKE-COORDINATOR (use --coord-self-authorize si es legitimo)" >&2
    else
      local_role=$(state_get last_swarm_role)
      local_turn=$(state_get last_swarm_spawn_turn)
      echo "[posttool] ✅ commit a código fuente CON swarm reciente (role=$local_role, turn=$local_turn)" >&2
    fi
  fi
fi

# 5. Si el tool es edit/write en .jcode/, alertar (protección del arnés)
if [[ "$tool_name" == "edit" ]] || [[ "$tool_name" == "write" ]]; then
  if echo "$tool_args" | grep -qE '\.jcode/(PRINCIPLES|AGENT-PROTOCOL|LOOPS|README|config\.toml)'; then
    echo "[posttool] ⚠️  Edit en archivo canónico del arnés —bumpear versión + sync requerido" >&2
  fi
fi

exit 0
