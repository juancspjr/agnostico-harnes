#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== H-5 INDEPENDIENTE: race condition ==="

# Verificar que save_json usa fcntl.flock (independientemente)
grep -q "fcntl.flock\|LOCK_EX" "$JCODE_DIR/lib/handbook_resync.py" || fail "fcntl no presente"
grep -q "os.replace\|os.rename" "$JCODE_DIR/lib/handbook_resync.py" || fail "atomic rename no presente"

# 10 concurrentes
for i in $(seq 1 10); do
    python3 "$JCODE_DIR/lib/handbook_resync.py" --auto > /dev/null 2>&1 &
done
wait

python3 -c "
import json
try:
    data = json.load(open('$JCODE_DIR/handbook/frozen_entries.json'))
    print(f'JSON OK: {len(data)} entries')
except json.JSONDecodeError as e:
    print(f'JSON corrupto: {e}')
    exit(1)
"
[[ $? -eq 0 ]] || fail "JSON corrupto"

tmp_count=$(find "$JCODE_DIR/handbook" -name "*.tmp" 2>/dev/null | wc -l)
[[ $tmp_count -eq 0 ]] || echo "⚠️ $tmp_count tmp orphan"

pass "H-5: locks y concurrencia OK"
exit 0
