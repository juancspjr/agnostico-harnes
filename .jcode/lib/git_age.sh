#!/usr/bin/env bash
# =============================================================================
# .jcode/lib/git_age.sh — Helper para turnend.sh (auditoría 3/3, 2026-07-20)
# =============================================================================
# Provee:
#   - last_commit_minutes: edad en minutos del último commit
#   - last_commit_subject: subject (línea 1) del último commit
#   - last_commit_paths: paths tocados por HEAD (vs HEAD~1), uno por línea
# =============================================================================

set -uo pipefail

REPO_ROOT="${JCODE_HOOK_CWD:-$PWD}"

# Edad en minutos del último commit (0 si ahora, 999 si no hay commits)
last_commit_minutes() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "999"
    return
  fi
  local ts
  ts=$(git log -1 --pretty=format:'%ct' 2>/dev/null || echo "0")
  if [[ "$ts" == "0" ]]; then
    echo "999"
    return
  fi
  local now
  now=$(date +%s)
  echo $(( (now - ts) / 60 ))
}

# Subject (línea 1) del último commit
last_commit_subject() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "(no commits)"
    return
  fi
  git log -1 --pretty=format:'%s' 2>/dev/null || echo "(error)"
}

# Paths tocados por HEAD (uno por línea)
last_commit_paths() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo ""
    return
  fi
  local parent
  parent=$(git rev-parse HEAD~1 2>/dev/null || echo "")
  if [[ -z "$parent" ]]; then
    # Primer commit del repo — listar todos los archivos
    git ls-tree -r --name-only HEAD 2>/dev/null || echo ""
  else
    git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || echo ""
  fi
}

# Si se ejecuta directo (debug), mostrar info
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "last_commit_minutes: $(last_commit_minutes)"
  echo "last_commit_subject: $(last_commit_subject)"
  echo "last_commit_paths:"
  last_commit_paths | head -10
fi
