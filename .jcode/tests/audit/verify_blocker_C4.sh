#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_C4.sh — Builder valida path ==="

# Backup
cp "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_backup_c4.json

# Test 1: Path inexistente
echo "[1] Path inexistente..."
output=$(python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /nonexistent/xyz 2>&1)
[[ $? -ne 0 ]] || fail "Exit code 0 con path inexistente"
echo "$output" | grep -qiE "not exist|no existe|FileNotFoundError|invalid path" || fail "Error no claro: $output"
pass "Path inexistente → error"

# Test 2: PG no corrompido
echo "[2] Verificando PG no corrompido..."
diff "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_backup_c4.json > /dev/null || {
    fail "PG fue sobreescrito"
}
pass "PG intacto"

# Test 3: Path es archivo (no directorio)
echo "[3] Path es archivo..."
echo "test" > /tmp/not_a_dir_test
output=$(python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /tmp/not_a_dir_test 2>&1)
[[ $? -ne 0 ]] || fail "Exit code 0 con path que es archivo"
echo "$output" | grep -qiE "no es directorio|not a directory|NotADirectoryError" || fail "Error no claro: $output"
pass "Path archivo → error"
rm -f /tmp/not_a_dir_test

# Test 4: Path sin permisos de lectura
echo "[4] Path sin permisos..."
mkdir -p /tmp/no_read_test
chmod 000 /tmp/no_read_test
output=$(python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /tmp/no_read_test 2>&1)
[[ $? -ne 0 ]] || fail "Exit code 0 con path sin permisos"
echo "$output" | grep -qiE "permisos|permission|PermissionError" || fail "Error no claro: $output"
chmod 755 /tmp/no_read_test
rmdir /tmp/no_read_test
pass "Path sin permisos → error"

# Cleanup
cp /tmp/pg_backup_c4.json "$JCODE_DIR/handbook/program_graph.json"

echo ""
echo "✅ C-4: builder valida path correctamente"
exit 0
