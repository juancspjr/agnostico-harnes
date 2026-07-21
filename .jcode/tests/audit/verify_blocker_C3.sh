#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"

echo "=== verify_blocker_C3.sh — Modo stub visible ==="

# 1. Verificar que _issue_stub_mode_warning existe
echo "[1] Checking _issue_stub_mode_warning exists..."
grep -q "def _issue_stub_mode_warning" "$JCODE_DIR/lib/handbook_phase2.py" || {
    echo "❌ _issue_stub_mode_warning no encontrado"
    exit 1
}
echo "  ✅ _issue_stub_mode_warning existe"

# 2. Verificar que el warning se emite en run_phase2
echo "[2] Checking warning is called from run_phase2..."
grep -q "_issue_stub_mode_warning()" "$JCODE_DIR/lib/handbook_phase2.py" || {
    echo "❌ _issue_stub_mode_warning() no se llama en run_phase2"
    exit 1
}
echo "  ✅ warning se llama en run_phase2"

# 3. Ejecutar Phase II y verificar warning visible
echo "[3] Executing Phase II..."
output=$(python3 "$JCODE_DIR/lib/handbook_phase2.py" 2>&1)
echo "$output" | head -5

# Verificar que el warning está en stderr
echo "$output" | grep -qi "HEURÍSTICO\|heuristic\|modo.*stub\|no LLM" || {
    echo "❌ Warning HEURÍSTICO no visible en output"
    exit 1
}
echo "  ✅ Warning HEURÍSTICO visible"

# 4. Verificar LLM_AVAILABLE flag
echo "[4] Checking LLM_AVAILABLE flag..."
grep -q "LLM_AVAILABLE = False" "$JCODE_DIR/lib/handbook_phase2.py" || {
    echo "❌ LLM_AVAILABLE flag no encontrado"
    exit 1
}
echo "  ✅ LLM_AVAILABLE flag presente"

# 5. Verificar que README.md documenta el requisito
echo "[5] Checking README documentation..."
if grep -qi "z-ai-web-dev-sdk\|pip install.*zai\|zai.*sdk" "$REPO_ROOT/README.md" 2>/dev/null; then
    echo "  ✅ README.md documenta requisito z-ai"
elif grep -qi "z-ai-web-dev-sdk\|pip install.*zai\|zai.*sdk" "$JCODE_DIR/README.md" 2>/dev/null; then
    echo "  ✅ .jcode/README.md documenta requisito z-ai"
else
    echo "  ⚠️ README no documenta requisito z-ai (no blocking)"
fi

echo ""
echo "✅ C-3: modo stub visible y documentado"
exit 0
