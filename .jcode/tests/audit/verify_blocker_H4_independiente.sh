#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== H-4 INDEPENDIENTE: resync detecta cambios ==="

cp "$JCODE_DIR/handbook/program_graph.json" /tmp/pg_h4i_before.json
cp "$JCODE_DIR/lib/handbook_verify.py" /tmp/verify_h4i_backup.py

# Renombrar función real
sed -i 's/def verify_site(/def verify_site_RENAMED_INDEPENDIENTE(/' "$JCODE_DIR/lib/handbook_verify.py"

output=$(python3 "$JCODE_DIR/lib/handbook_resync.py" --auto 2>&1)
echo "$output" | grep -q "PG changed" || fail "resync no detectó PG changed"

python3 -c "
import json
pg = json.load(open('$JCODE_DIR/handbook/program_graph.json'))
qns = [f['qualname'] for f in pg['functions']]
assert any('verify_site_RENAMED_INDEPENDIENTE' in q for q in qns), 'Función no en PG'
print('✅ Rename detectado en PG')
"

cp /tmp/verify_h4i_backup.py "$JCODE_DIR/lib/handbook_verify.py"
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1

pass "H-4: resync detecta rename"
exit 0
