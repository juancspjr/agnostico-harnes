#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== H-1 INDEPENDIENTE: source_hash real ==="

python3 "$JCODE_DIR/lib/handbook_builder.py" --repo "$REPO_ROOT" > /dev/null 2>&1
python3 "$JCODE_DIR/lib/handbook_phase2.py" > /dev/null 2>&1
python3 "$JCODE_DIR/lib/handbook_phase3.py" > /dev/null 2>&1

python3 -c "
import json, hashlib
cb = json.load(open('$JCODE_DIR/handbook/cache_B.json'))
entries = cb['l3_entries']

# Ni un solo source_hash vacío
empty = [qn for qn, e in entries.items() if not e.get('source_hash', '')]
assert len(empty) == 0, f'{len(empty)} empty: {empty[:3]}'

# Todos sha256 con hash real
for qn, e in entries.items():
    sh = e['source_hash']
    assert sh.startswith('sha256:'), f'{qn}: bad prefix: {sh}'
    assert len(sh) > 30, f'{qn}: too short: {sh}'

# Verificar 3 random contra source real
import random
samples = random.sample(list(entries.items()), 3)
for qn, e in samples:
    fp = e['file']; lr = e['line_range']
    lines = open(fp).read().splitlines()
    region = '\n'.join(lines[max(0,lr[0]-1):lr[1]])
    expected = 'sha256:' + hashlib.sha256(region.encode()).hexdigest()
    assert e['source_hash'] == expected, f'{qn}: hash mismatch'
    print(f'  Verified: {qn}')
print(f'✅ {len(entries)} entries, all valid')
"
[[ $? -eq 0 ]] || fail "H-1 independiente falló"
pass "H-1: source_hash verificable"
exit 0
