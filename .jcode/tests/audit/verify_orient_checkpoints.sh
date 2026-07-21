#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
SKILL="$JCODE_DIR/skills/orient/SKILL.md"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_orient_checkpoints: skill orient como mecanismo de seguridad ==="

echo "[1] FASE 0 (Checkpoint F0: bootstrap) presente..."
grep -q "FASE 0: CHECKPOINT DE ESTADO DEL PROYECTO" "$SKILL" || fail "Falta FASE 0"
grep -q "CHECKPOINT F0" "$SKILL" || fail "Falta CHECKPOINT F0"
grep -q "bootstrap-proyecto" "$SKILL" || fail "Falta referencia a bootstrap-proyecto"
pass "FASE 0 + CHECKPOINT F0 presentes"

echo "[2] Árbol de decisión tiene 5 preguntas (no 4)..."
python3 -c "
import re
content = open('$SKILL').read()
p_count = len(re.findall(r'^P\d\.', content, re.MULTILINE))
assert p_count >= 5, f'Solo {p_count} preguntas, se esperan ≥5'
print(f'  Preguntas: {p_count}')
"
[[ $? -eq 0 ]] || fail "Árbol incompleto"
pass "5 preguntas en árbol"

echo "[3] Flujo REMEDIATION (Fase 2-C) presente..."
grep -q "FASE 2-C\|Flujo REMEDIATION" "$SKILL" || fail "Falta Flujo REMEDIATION"
grep -q "remediation-.*\.log\|remediation-" "$SKILL" || fail "Falta reference a iteration logs"
pass "Fase 2-C con iteration logs"

echo "[4] CHECKPOINTS F1-F5 ejecutables..."
for chk in F1 F2 F3 F4 F5; do
  grep -q "Checkpoint $chk\|CHECKPOINT $chk" "$SKILL" || fail "Falta checkpoint $chk"
done
pass "5 checkpoints ejecutables"

echo "[5] Cada checkpoint tiene comando bash..."
python3 -c "
content = open('$SKILL').read()
# Buscar cada CHECKPOINT y verificar que tiene un bloque bash después
import re
for chk in ['F0', 'F1', 'F2', 'F3', 'F4', 'F5']:
    pattern = rf'Checkpoint {chk}.*?```bash(.*?)```'
    m = re.search(pattern, content, re.DOTALL)
    assert m, f'Checkpoint {chk} sin bloque bash'
print('  Todos los checkpoints tienen comando bash')
"
[[ $? -eq 0 ]] || fail "Checkpoints sin comando"
pass "Checkpoints con comandos bash"

echo "[6] Anti-patrones nuevos (HF Gate, evidence, self-critique, reviewer)..."
grep -q "Cerrar tarea sin pasar F1" "$SKILL" || fail "Falta anti-patrón F1"
grep -q "F3 (Evidence bundle)" "$SKILL" || fail "Falta anti-patrón F3"
grep -q "F4 (Self-critique)" "$SKILL" || fail "Falta anti-patrón F4"
grep -q "F5 (Reviewer)" "$SKILL" || fail "Falta anti-patrón F5"
pass "4 nuevos anti-patrones"

echo "[7] Validación de cierre (compliance ≥80, PLAN-VIVO)..."
grep -q "harness.sh status" "$SKILL" || fail "Falta validación de compliance"
grep -q "PLAN-VIVO" "$SKILL" || fail "Falta referencia a PLAN-VIVO"
pass "Validación de cierre presente"

echo "[8] Orient referencia quality-preamble y FAILURE-PATTERNS..."
grep -q "quality-preamble" "$SKILL" || fail "Falta referencia a quality-preamble"
grep -q "FAILURE-PATTERNS" "$SKILL" || fail "Falta referencia a FAILURE-PATTERNS"
pass "Referencias normativas presentes"

echo ""
echo "✅ Skill orient: 6 checkpoints + 5 preguntas + 2-C remediación + anti-patrones"
exit 0
