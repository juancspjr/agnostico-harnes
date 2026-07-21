#!/usr/bin/env bash
# =============================================================================
# .jcode/hooks/posttool.sh — Post-tool call (mínimo: solo log + tracking)
# =============================================================================
# Bug fixed: eliminado posttool_auto_compile.sh (era stack lock-in Go+Astro+Docker).
# Bug fixed: eliminado smoke_e2e_playwright.sh en cada edit frontend (catastrófico).
# Bug fixed: eliminada dependencia token_watchdog.sh (no existía).
# Bug fixed: eliminada dependencia scripts/autojudge.sh (no existía).
# Bug fixed (H-01): regex con comilla doble sin escapar reemplazada por pattern
#   basado en clase de caracteres que no requiere escape.
# Bug fixed (H-02): extensiones de código movidas a config.toml
#   ([workspace.code_extensions.extensions]) + leídas vía config_reader.sh,
#   haciendo el detector stack-agnóstico.
# =============================================================================

set -uo pipefail

REPO_ROOT="${JCODE_HOOK_CWD:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"
LOG_FILE="$JCODE_DIR/logs/post_tool.log"

mkdir -p "$JCODE_DIR/logs"

source "$JCODE_DIR/lib/state_manager.sh"
source "$JCODE_DIR/lib/config_reader.sh"

# ----------------------------------------------------------------------------
# Construir regex de extensiones desde config.toml (H-02)
# ----------------------------------------------------------------------------
_build_code_ext_regex() {
  local exts
  exts=$(config_get_array workspace.code_extensions.extensions 2>/dev/null)
  if [[ -z "$exts" ]]; then
    # Fallback agnóstico: extensiones web comunes
    exts=$'.go\n.ts\n.astro\n.tsx\n.jsx\n.sql\n.svelte\n.css\n.scss\n.vue'
  fi
  # Convertir [".go", ".ts"] → \.(go|ts) con terminador seguro
  echo "$exts" | sed 's/^\./\\./' | paste -sd'|' - | sed 's/^/(/' | sed 's/$/)([^A-Za-z0-9]|$)/'
}

CODE_EXT_REGEX=$(_build_code_ext_regex)

# 0. Helper: detect docs-only commit
# Returns 0 (true) if:
#   - commit message starts with docs: / chore(docs): / docs(<scope>): / chore(<docs-scope>):
#   - AND no code file extensions appear in the args
# Usado por SRSI + R-FAKE-COORDINATOR detectors para evitar falsos positivos.
is_docs_only_commit() {
  local args="$1"
  # 1) No code extensions in args → candidate docs-only (H-01: regex sin comilla doble sin escapar)
  if echo "$args" | grep -qE "$CODE_EXT_REGEX"; then
    return 1
  fi
  # 2) Commit message prefix matches docs-only convention
  #    Patrón simplificado para evitar problemas de escape en bash
  if echo "$args" | grep -qE "git +commit.*(-m|--message) +(-m +|-m)?['\"]?(docs|chore\\(docs\\))"; then
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
if [[ "$tool_name" == "bash" ]] && echo "$tool_args" | grep -qE 'git[[:space:]]+commit'; then
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
if [[ "$tool_name" == "swarm" ]] || echo "$tool_args" | grep -qE 'swarm_spawn|swarm[[:space:]]+spawn|action=.spawn'; then
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
#     (extensiones desde config.toml — H-02 stack-agnóstico)
#     SIN swarm spawn reciente (≤30 turns) registrado en state.
if [[ "$tool_name" == "bash" ]] && echo "$tool_args" | grep -qE 'git[[:space:]]+commit'; then
  # Bypass clause §4.7 — agente declara self-authorize explícito en args
  if echo "$tool_args" | grep -qE '\-\-coord-self-authorize|\-\-fake-coordinator-override'; then
    echo "[posttool] ✅ bypass clause §4.7 activa: --coord-self-authorize en commit args" >&2
  elif is_docs_only_commit "$tool_args"; then
    echo "[posttool] 📝 commit docs-only detectado — R-FAKE-COORDINATOR skipped" >&2
  elif echo "$tool_args" | grep -qE "$CODE_EXT_REGEX"; then
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
    echo "[posttool] ⚠️  Edit en archivo canónico del arnés — bumpear versión + sync requerido" >&2
  fi
fi

exit 0