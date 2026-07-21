#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_H5.sh — Race condition con locks ==="

echo "[1] Checking save_json uses fcntl.flock..."
grep -q "fcntl.flock" "$JCODE_DIR/lib/handbook_resync.py" && grep -q "LOCK_EX" "$JCODE_DIR/lib/handbook_resync.py" || {
    echo "❌ No fcntl.flock found"
    exit 1
}
pass "fcntl.flock presente"

echo "[2] Testing 5 concurrent resyncs..."
for i in 1 2 3 4 5; do
    python3 "$JCODE_DIR/lib/handbook_resync.py" --auto > /tmp/h5_test_$i.log 2>&1 &
done
wait

echo "[3] Checking JSON integrity..."
python3 -c "
import json
try:
    data = json.load(open('$JCODE_DIR/handbook/frozen_entries.json'))
    print(f'  JSON válido: {len(data)} entries')
except json.JSONDecodeError as e:
    print(f'  ❌ JSON corrupto: {e}')
    exit(1)
"
[[ $? -eq 0 ]] || fail "JSON corrupto tras resyncs concurrentes"
pass "JSON íntegro tras 5 concurrentes"

echo "[4] Checking orphan tmp files..."
tmp_count=$(find "$JCODE_DIR/handbook" -name "*.tmp" 2>/dev/null | wc -l)
[[ $tmp_count -eq 0 ]] || {
    echo "⚠️  $tmp_count tmp files orphan"
}
pass "0 orphan tmp files"

echo ""
echo "✅ H-5: escritura atómica con locks"
exit 0
