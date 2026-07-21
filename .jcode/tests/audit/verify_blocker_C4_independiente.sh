#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== C-4 INDEPENDIENTE: builder valida path ==="

cp "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_backup_c4i.json

# 1. Path es archivo existente (no directorio)
echo "test" > /tmp/c4i_file_test
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /tmp/c4i_file_test > /tmp/c4i_out1.log 2>&1
[[ $? -ne 0 ]] || fail "Exit 0 con path=archivo"
rm -f /tmp/c4i_file_test

# 2. PG no corrompido
diff "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_backup_c4i.json > /dev/null || fail "PG corrupto"

# 3. Sin permisos
mkdir -p /tmp/c4i_no_read
chmod 000 /tmp/c4i_no_read
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo /tmp/c4i_no_read > /tmp/c4i_out2.log 2>&1
rc=$?
chmod 755 /tmp/c4i_no_read; rmdir /tmp/c4i_no_read
[[ $rc -ne 0 ]] || fail "Exit 0 con path sin permisos"

pass "C-4: path validation independiente OK"
cp /tmp/pg_backup_c4i.json "$JCODE_DIR/handbook/program_graph.json"
exit 0
