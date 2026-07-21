#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_H4.sh — Resync detecta cambios ==="

cp "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_before_h4.json

# Renombrar función, commit, resync
echo "[1] Renaming function..."
cp "$JCODE_DIR/lib/_config_parse.py" /tmp/cp_backup_h4.py
sed -i 's/def parse_toml(/def parse_toml_H4_TEST(/' "$JCODE_DIR/lib/_config_parse.py"

echo "[2] Running resync..."
output=$(python3 "$JCODE_DIR/lib/handbook_resync.py" --auto 2>&1)
echo "$output"

# Restaurar
cp /tmp/cp_backup_h4.py "$JCODE_DIR/lib/_config_parse.py"

# Verificar no_op
echo ""
echo "[3] Checking no no_op..."
echo "$output" | grep -q "no_op" && {
    echo "❌ resync retornó no_op después de rename"
    exit 1
}
pass "resync no retornó no_op"

# Verificar Step 0
echo "[4] Checking Phase I re-extraction..."
echo "$output" | grep -q "Step 0\|Re-extracting\|PG changed" || {
    echo "❌ Phase I re-extraction not detected"
    exit 1
}
pass "Phase I re-extraction ejecutada"

# Rebuild completo para restaurar
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1
python3 "$JCODE_DIR/lib/handbook_phase2.py" > /dev/null 2>&1
python3 "$JCODE_DIR/lib/handbook_phase3.py" > /dev/null 2>&1

echo ""
echo "✅ H-4: resync detecta cambios sin rebuild manual"
exit 0
