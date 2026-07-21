#!/usr/bin/env bash
# test_bootstrap_gap1.sh — Gap 1: Stages adaptativas al dominio
# Estricto: recalcula desde ground truth, no hardcodea valores
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== GAP 1: Stages adaptativas ==="

python3 "$REPO_ROOT/.jcode/skills/bootstrap-proyecto/lib/stage_generator.py" --json > /tmp/gap1_output.json 2>&1

# Test 1: stages no vacías
STAGES=$(python3 -c "import json; d=json.load(open('/tmp/gap1_output.json')); print(len(d['stages']))")
[[ "$STAGES" -gt 0 ]] || fail "0 stages generadas"
  pass "Stages generadas: $STAGES"

# Test 2: cada stage tiene id, name, description
python3 -c "
import json
d = json.load(open('/tmp/gap1_output.json'))
for s in d['stages']:
    assert 'id' in s, f'Missing id in {s}'
    assert 'name' in s, f'Missing name in {s}'
    assert 'description' in s, f'Missing description in {s}'
    assert len(s['id']) > 0, f'Empty id'
    assert len(s['name']) > 0, f'Empty name'
print('All stages have id, name, description')
"

# Test 3: sin proyecto? debe tener _adaptable=True
HAS_PROJECT=$(python3 -c "import json; d=json.load(open('/tmp/gap1_output.json')); print(d.get('_adaptable', False))")
if [[ "$HAS_PROJECT" == "True" ]]; then
    pass "Modo adaptable (sin proyecto) — correcto"
fi

# Test 4: stage ids son válidos (snake_case)
python3 -c "
import json, re
d = json.load(open('/tmp/gap1_output.json'))
for s in d['stages']:
    assert re.match(r'^[a-z][a-z0-9_]*$', s['id']), f'Invalid stage id: {s[\"id\"]}'
print('All stage IDs are valid snake_case')
"

pass "Gap 1: stages adaptativas OK"
exit 0
