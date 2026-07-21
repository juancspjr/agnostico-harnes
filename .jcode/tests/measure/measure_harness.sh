#!/usr/bin/env bash
# =============================================================================
# measure_harness.sh — Mide tiempos de respuesta del arnés
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

MAX_MS=5000  # 5 segundos como umbral máximo

measure() {
  local name="$1"
  shift
  local start end dur_ms
  start=$(date +%s%N)
  "$@" >/dev/null 2>&1
  end=$(date +%s%N)
  dur_ms=$(( (end - start) / 1000000 ))
  echo "  $name: ${dur_ms}ms"
  if [[ $dur_ms -gt $MAX_MS ]]; then
    fail "$name excedió ${MAX_MS}ms (dur=${dur_ms}ms)"
  fi
}

# 1. Medir init
measure "harness.sh init" bash "$JCODE_DIR/lib/harness.sh" init
pass "harness.sh init < ${MAX_MS}ms"

# 2. Medir check
measure "harness.sh check" bash "$JCODE_DIR/lib/harness.sh" check
pass "harness.sh check < ${MAX_MS}ms"

# 3. Medir score
measure "state_manager.sh score" bash "$JCODE_DIR/lib/state_manager.sh" score
pass "state_manager.sh score < ${MAX_MS}ms"

# 4. Medir breakdown
measure "state_manager.sh breakdown" bash "$JCODE_DIR/lib/state_manager.sh" breakdown
pass "state_manager.sh breakdown < ${MAX_MS}ms"

# 5. Medir status
measure "harness.sh status" bash "$JCODE_DIR/lib/harness.sh" status
pass "harness.sh status < ${MAX_MS}ms"

echo "measure_harness: OK"
exit 0