#!/usr/bin/env bash
# =============================================================================
# .jcode/hooks/turnend.sh — Fin de turno (mínimo)
# =============================================================================
# Bug fixed: eliminada dependencia state-mapa-report.sh (no existía).
# Bug fixed: score ahora puede llegar a 100 (bug matemático corregido).
# Bug fixed (H-02): patrones hardcoded de paths de modelos/frontend ahora
#   se derivan de config.toml vía config_reader.sh (stack-agnóstico).
# =============================================================================

set -uo pipefail

REPO_ROOT="${JCODE_HOOK_CWD:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

source "$JCODE_DIR/lib/state_manager.sh"
source "$JCODE_DIR/lib/config_reader.sh"

# ----------------------------------------------------------------------------
# Construir regex de extensiones desde config.toml (H-02)
# ----------------------------------------------------------------------------
_build_code_ext_regex() {
  local exts
  exts=$(config_get_array workspace.code_extensions.extensions 2>/dev/null)
  if [[ -z "$exts" ]]; then
    exts=$'.go\n.ts\n.astro\n.tsx\n.jsx\n.sql\n.svelte\n.css\n.scss\n.vue'
  fi
  echo "$exts" | sed 's/^\.//' | paste -sd'|' - | sed 's/^/\\./;s/$/([^A-Za-z0-9]|$)/'
}

CODE_EXT_REGEX=$(_build_code_ext_regex)

# 1. Calcular score
score=$(state_compliance_score)

# 2. Verificar handoff
handoff=$(state_get handoff_written)
loop=$(state_get current_loop_id)

# 3. Reporte (mínimo)
cat <<EOF
[turnend] turn=$(state_get turn) score=$score/100
[turnend] srsi=$(state_get srsi_done_this_turn) ddlp=$(state_get ddlp_done) handoff=$handoff
EOF

# 4. Warning si score < 80 (no bloquear, solo avisar)
if [[ $score -lt 80 ]]; then
  echo "[turnend] ⚠️  Score $score < 80 — revisar compliance" >&2
fi

# 5. Reminder handoff si hay loop activo y no se escribió handoff
if [[ "$loop" != "" ]] && [[ "$loop" != "null" ]] && [[ "$handoff" != "true" ]]; then
  echo "[turnend] ⚠️  Loop $loop activo sin handoff — bumpear PLAN-VIVO §8" >&2
fi

# 5b. AUDITORÍA 3 (2026-07-20): verificar que hubo update de PLAN-VIVO §6 si hubo commit en últimos 5 min
source "$JCODE_DIR/lib/git_age.sh"
last_commit_age=$(last_commit_minutes)
if [[ $last_commit_age -le 5 ]]; then
  # commit reciente — verificar que la última entrada de §6 menciona algún loop related al commit
  last_commit_msg=$(last_commit_subject)
  section6_hit=$(grep -c "L-" "$JCODE_DIR/iterations/PLAN-VIVO.md" 2>/dev/null || echo "0")
  if [[ $section6_hit -le 4 ]]; then
    echo "[turnend] ⚠️  Commit reciente ($last_commit_msg) sin update de PLAN-VIVO §6 (auditoría 3/3 — trazabilidad)" >&2
  fi
fi

# 6b. Handbook resync (Pilar 2 del paper) — paper ref §3.3.3 + Appendix B.4
if [[ $last_commit_age -le 5 ]]; then
  HANDBOOK_DIR="$JCODE_DIR/handbook"
  if [[ -d "$HANDBOOK_DIR" ]] && [[ -f "$HANDBOOK_DIR/K_g.json" ]]; then
    echo "[turnend] Sincronizando handbook (Resync_g)…"
    if python3 "$JCODE_DIR/lib/handbook_resync.py" --auto 2>&1 | \
       tee -a "$JCODE_DIR/logs/handbook_resync.log"; then
      echo "[turnend] ✅ Handbook resync OK"
    else
      echo "[turnend] ⚠️  Handbook resync falló — ver log" >&2
    fi
  fi
fi

# 5c. AUDITORÍA 3: si commit reciente tocó modelos de datos, recordar STATE-REGISTERS + BEHAVIOR-INDEX
# Patrones derivados de config.toml (H-02)
if [[ $last_commit_age -le 5 ]]; then
  diff_paths=$(last_commit_paths)
  # Patrones backend (models, migrations, dto)
  backend_patterns=$(config_get_array workspace.backend_patterns.patterns 2>/dev/null || echo "models/
migrations/
dto/")
  backend_regex=$(echo "$backend_patterns" | sed 's/\/$//' | paste -sd'|' -)
  if echo "$diff_paths" | grep -qE "($backend_regex)"; then
    echo "[turnend] ⚠️  Commit tocó modelos/dto/migrations → actualizar STATE-REGISTERS (escribir bitácora de writers/readers/invariantes)" >&2
  fi
  # Patrones frontend (desde config)
  frontend_ext=$(config_get_array workspace.frontend_extensions.extensions 2>/dev/null || echo ".astro
.tsx
.ts")
  frontend_regex=$(echo "$frontend_ext" | sed 's/^\./\\./' | paste -sd'|' - | sed 's/^/.*(/;s/$/)/')
  if echo "$diff_paths" | grep -qE "frontend/src/" || echo "$diff_paths" | grep -qE "($frontend_regex)"; then
    echo "[turnend] ⚠️  Commit tocó frontend → considerar entrada en BEHAVIOR-INDEX (comportamiento observable nuevo/fix)" >&2
  fi
fi

# 6. Closeout check (no bloquea, solo reporta)
if [[ $score -ge 80 ]] && [[ "$handoff" == "true" ]]; then
  state_set closeout_passed true
  echo "[turnend] ✅ closeout OK"
else
  state_set closeout_passed false
fi

# ----------------------------------------------------------------------------
# Frontier quality gate (quality-preamble.md)
# ----------------------------------------------------------------------------
TASK_CLASS="$(state_get current_loop_task_class 2>/dev/null || echo 'MICROFIX')"
SELF_CRITIQUE_REQUIRED="$(config_get policy.frontier_quality.require_self_critique 2>/dev/null || echo 'false')"
EVIDENCE_REQUIRED="$(config_get policy.frontier_quality.require_evidence_bundle 2>/dev/null || echo 'false')"
REVIEWER_AUTO="$(config_get policy.frontier_quality.auto_spawn_reviewer 2>/dev/null || echo 'false')"

# 1. Self-critique prompt
if [[ "$SELF_CRITIQUE_REQUIRED" == "true" ]]; then
  echo "[turnend] SELF-CRITIQUE: Re-leé tu último output contra la petición original." >&2
  echo "[turnend] Si encontrás un error, corregilo ANTES de cerrar sesión." >&2
  state_set self_critique_pending true
fi

# 2. Evidence bundle automático
if [[ "$EVIDENCE_REQUIRED" == "true" && "$TASK_CLASS" != "AUDIT" ]]; then
  bash "$JCODE_DIR/lib/evidence_bundle.sh" "$loop" 2>&1 | sed 's/^/[turnend] /' >&2 || true
fi

# 3. Reviewer spawn requirement
if [[ "$REVIEWER_AUTO" == "true" ]]; then
  case "$TASK_CLASS" in
    SLICE|REMEDIATION|PHASE-CLOSE)
      echo "[turnend] REVIEWER REQUIRED: task_class=$TASK_CLASS exige revisión independiente." >&2
      echo "[turnend] En TUI: Ctrl+N → spawn reviewer con fixed_check como prompt." >&2
      state_set reviewer_required true
      state_set reviewer_task_class "$TASK_CLASS"
      ;;
  esac
fi

exit 0
