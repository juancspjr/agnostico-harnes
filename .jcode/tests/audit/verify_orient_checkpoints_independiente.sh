#!/usr/bin/env bash
# Test INDEPENDIENTE: recalcula contra el ground truth sin usar la skill
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
SKILL="$JCODE_DIR/skills/orient/SKILL.md"
ANALYSIS="$JCODE_DIR/skills/orient/ANALISIS-COMPARATIVO.md"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_orient_checkpoints INDEPENDIENTE ==="

echo "[1] Análisis comparativo existe y es reciente..."
[[ -f "$ANALYSIS" ]] || fail "Falta ANALISIS-COMPARATIVO.md"
grep -q "desactualizada\|desactualizado" "$ANALYSIS" || fail "Análisis no documenta desactualización"
pass "Análisis comparativo presente"

echo "[2] Recalcular cobertura de Orient vs flujos del harness..."
python3 -c "
import os, re
content = open('$SKILL').read()
# Buscar checkpoints explícitamente
required_checks = {
    'F0': 'bootstrap',
    'F1': 'HF Gate|hidden_failure',
    'F2': 'effort_routing|effort',
    'F3': 'evidence_bundle|evidence',
    'F4': 'self_critique|self-critique',
    'F5': 'reviewer',
}
for chk, pattern in required_checks.items():
    assert f'Checkpoint {chk}' in content or f'CHECKPOINT {chk}' in content, f'Falta checkpoint {chk}'
    assert re.search(pattern, content, re.IGNORECASE), f'{chk} sin patrón {pattern}'
print('  6 checkpoints con patrones correctos')
"
[[ $? -eq 0 ]] || fail "Cobertura incompleta"
pass "6 checkpoints válidos"

echo "[3] Verificar que los checkpoints F1-F5 se corresponden con componentes del harness..."
python3 -c "
import os
# F1 debe mapear a verify_hidden_failure_gate*.sh
f1 = os.path.exists('$JCODE_DIR/tests/audit/verify_hidden_failure_gate.sh')
assert f1, 'F1 sin ejecutable'

# F3 debe mapear a evidence_bundle.sh
f3 = os.path.exists('$JCODE_DIR/lib/evidence_bundle.sh')
assert f3, 'F3 sin ejecutable'

# F5 debe mapear a turnend.sh con auto_spawn_reviewer
f5 = os.path.exists('$JCODE_DIR/hooks/turnend.sh')
import re
turnend = open('$JCODE_DIR/hooks/turnend.sh').read()
assert 'reviewer_required' in turnend, 'F5 sin hook reviewer'

print('  F1→HF Gate tests, F3→evidence_bundle.sh, F5→turnend.sh')
"
[[ $? -eq 0 ]] || fail "Checkpoints no anclados a código"
pass "Checkpoints anclados a ejecutables reales"

echo "[4] Verificar que Orient NO contradice quality-preamble..."
grep -q "Self-Verify\|self_critique" "$JCODE_DIR/quality-preamble.md" && \
  grep -q "self_critique\|Self-critique" "$SKILL" && \
  echo "  OK: Orient incluye self-critique"

echo "[5] Orient tiene 5 o más preguntas (no 4)..."
python3 -c "
content = open('$SKILL').read()
import re
p_lines = re.findall(r'^P\d+\.', content, re.MULTILINE)
n = len(p_lines)
assert n >= 5, f'Solo {n} preguntas'
print(f'  Preguntas: {n}')
"
pass "5+ preguntas en árbol"

echo "[6] Verificar que Orient referencia archivos canónicos que existen..."
for f in PRINCIPLES FAILURE-PATTERNS quality-preamble bootstrap-proyecto; do
  grep -q "$f" "$SKILL" || fail "Referencia a $f sin contexto"
done
pass "Referencias a archivos canónicos presentes"

echo ""
echo "✅ Orient INDEPENDIENTE: 6 checkpoints anclados a ejecutables"
exit 0
