#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== C-3 INDEPENDIENTE: modo stub visible ==="

# 1. Verificar que LLM_AVAILABLE está en False (independientemente)
grep -q "LLM_AVAILABLE = False" "$JCODE_DIR/lib/handbook_phase2.py" || fail "No LLM_AVAILABLE flag"

# 2. Verificar que el warning se emite capturando stderr
output=$(python3 "$JCODE_DIR/lib/handbook_phase2.py" 2>&1 >/dev/null)
echo "$output" | grep -qi "HEURÍSTICO\|heuristic\|no LLM" || fail "Warning no visible"

# 3. Verificar en README
grep -qi "z-ai-web-dev-sdk\|zai.*sdk" "$REPO_ROOT/README.md" || fail "README sin docs z-ai"

pass "C-3: modo stub visible y documentado"
exit 0
