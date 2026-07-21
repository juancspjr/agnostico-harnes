#!/usr/bin/env bash
# post-loop.sh — Hook ejecutado al final de cada loop del arnés.
# Por ahora solo loguea. Auto-stop de Chrome CDP queda como opt-in via flag.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Auto-stop Chrome CDP solo si el flag está activo (default off)
if [ "${AUTO_STOP_CDP:-0}" = "1" ]; then
  bash "$ROOT/bin/stop-cdp-chrome.sh" || true
fi

exit 0