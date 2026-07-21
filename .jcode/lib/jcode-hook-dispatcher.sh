#!/usr/bin/env bash
# =============================================================================
# .jcode/lib/jcode-hook-dispatcher.sh — Dispatcher agnóstico de hooks
# =============================================================================
# Único archivo realmente agnóstico del arnés original. Se mantiene tal cual.
#
# Mecanismo: jcode llama este script con $JCODE_HOOK_CWD apuntando al repo
# root y $JCODE_HOOK_NAME indicando el evento. El dispatcher ejecuta el
# hook correspondiente en $JCODE_HOOK_CWD/.jcode/hooks/.
# =============================================================================

set -uo pipefail

HOOK_CWD="${JCODE_HOOK_CWD:-$PWD}"
HOOK_NAME="${JCODE_HOOK_NAME:-}"

if [[ -z "$HOOK_NAME" ]]; then
  echo "[hook-dispatcher] ERROR: JCODE_HOOK_NAME no seteado" >&2
  exit 1
fi

HOOK_FILE="$HOOK_CWD/.jcode/hooks/${HOOK_NAME}.sh"

if [[ ! -x "$HOOK_FILE" ]]; then
  # Hook no existe o no es ejecutable — salir silenciosamente
  # (no todos los proyectos implementan todos los hooks)
  exit 0
fi

# Ejecutar hook con CWD en el repo root
cd "$HOOK_CWD"
exec "$HOOK_FILE" "$@"
