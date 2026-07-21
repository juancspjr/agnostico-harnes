#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_blocker_H1.sh — source_hash en L3 entries ==="

echo "[1] Rebuilding..."
python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1
python3 "$JCODE_DIR/lib/handbook_phase2.py" > /dev/null 2>&1
python3 "$JCODE_DIR/lib/handbook_phase3.py" > /dev/null 2>&1

echo "[2] Checking source_hash..."
python3 -c "
import json, hashlib
cb = json.load(open('$JCODE_DIR/handbook/cache_B.json'))
entries = cb.get('l3_entries', {})
empty = [qn for qn, e in entries.items() if not e.get('source_hash') or e['source_hash'] == '']
valid = [qn for qn, e in entries.items() if e.get('source_hash', '').startswith('sha256:') and len(e['source_hash']) > 30]
assert len(empty) == 0, f'{len(empty)} empty hashes: {empty[:3]}'
assert len(valid) > 0, 'No valid hashes'
print(f'  Valid: {len(valid)}/{len(entries)}')
import random
samples = random.sample(list(entries.items()), min(3, len(entries)))
for qn, entry in samples:
    sh = entry['source_hash']
    fp = entry['file']
    lr = entry['line_range']
    lines = open(fp).read().splitlines()
    region = '\n'.join(lines[max(0, lr[0]-1):lr[1]])
    expected = 'sha256:' + hashlib.sha256(region.encode()).hexdigest()
    assert sh == expected, f'{qn}: hash mismatch'
    print(f'  \u2705 {qn}: hash verified')
"
[[ $? -eq 0 ]] || fail "source_hash verification failed"
pass "source_hash real y verificable"
echo ""
echo "✅ H-1: source_hash en L3 entries"
exit 0
