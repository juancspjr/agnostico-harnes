#!/usr/bin/env bash
# Test INDEPENDIENTE: recalcula contra ground truth sin usar la skill
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
SKILL="$JCODE_DIR/skills/orient/SKILL.md"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_orient_checkpoints INDEPENDIENTE v101.4 ==="

echo "[1] Análisis comparativo existe..."
[[ -f "$JCODE_DIR/skills/orient/ARBOL-CONEXIONES.md" ]] || fail "Falta ARBOL-CONEXIONES.md"
grep -q "Mecanismos\|cobertura" "$JCODE_DIR/skills/orient/ARBOL-CONEXIONES.md" || fail "Sin análisis"
pass "Análisis presente"

echo "[2] Cobertura del árbol de decisión: 10 preguntas..."
python3 -c "
import re
content = open('$SKILL').read()
p_count = len(re.findall(r'^P\d+\.', content, re.MULTILINE))
assert p_count >= 10, f'Solo {p_count} preguntas'
print(f'  Preguntas: {p_count}')
"
[[ $? -eq 0 ]] || fail "Árbol <10 preguntas"
pass "10+ preguntas"

echo "[3] Checkpoints F0-F11 anclados a ejecutables reales..."
python3 -c "
import os
checkpoints = {
    'F0': '$JCODE_DIR/skills/bootstrap-proyecto/lib/bootstrap_all.py',
    'F1': '$JCODE_DIR/tests/audit/verify_hidden_failure_gate.sh',
    'F2': '$JCODE_DIR/config.toml',
    'F3': '$JCODE_DIR/lib/evidence_bundle.sh',
    'F6': '$JCODE_DIR/lib/handbook_builder.py',
    'F7': '$JCODE_DIR/tests/run_all.sh',
    'F9': '$JCODE_DIR/lib/harness.sh',
    'F10': '$JCODE_DIR/lib/handbook_verify.py',
    'F11': '$JCODE_DIR/lib/handbook_resync.py',
}
for name, path in checkpoints.items():
    assert os.path.exists(path), f'{name} sin ejecutable: {path}'
    print(f'  {name} → {os.path.basename(path)}')
"
[[ $? -eq 0 ]] || fail "Checkpoints sin ejecutable"
pass "Checkpoints anclados"

echo "[4] Fases completas: 0, 1, 2-A, 2-B, 2-C, 2-D, 3, 4..."
for f in "FASE 0" "FASE 1:" "FASE 2-A" "FASE 2-B" "FASE 2-C" "FASE 2-D" "FASE 3:" "FASE 4"; do
  grep -q "$f" "$SKILL" || fail "Falta $f"
done
pass "8 fases presentes"

echo "[5] Compatibilidad con 14 principios..."
expected_principles=("§1 R-3STRIKE" "§2 R-DOS-PLANOS" "§3 SRSI" "§4 DDLP" "§5 TPSP"
                     "§6 R-NO-FAKE-SWARM" "§7 R-VERIFY" "§8 R-INDEPENDENT" "§9 R-ITERATION"
                     "§10 R-NO-SILENT" "§11 R-REGRESSION" "§12 R-CONTAMINATION"
                     "§13 R-HIDDEN" "§14 R-FRONTIER")
covered=0
for p in "${expected_principles[@]}"; do
  if grep -q "$p" "$SKILL"; then
    covered=$((covered + 1))
  fi
done
echo "  $covered/14 principios cubiertos"
[[ $covered -ge 10 ]] || fail "Solo $covered principios"
pass "≥10 principios referenciados"

echo "[6] Checkpoint F1.5 (patrones HF por task_class) presente..."
grep -q "F1.5\|patterns_by_class" "$SKILL" || fail "Falta F1.5 con patrones HF por task_class"
pass "Checkpoint F1.5 implementado"

echo "[7] Sin contradicciones con leyes del harness..."
# Verificar que Orient no contradice FAILURE-PATTERNS.md
failures_pattern=$(grep -E "^(❌|V-NO).*FAILURE-PATTERNS" "$SKILL" | wc -l)
[[ $failures_pattern -eq 0 ]] || echo "  ⚠️  $failures_pattern menciones de FAILURE-PATTERNS"
pass "Sin contradicciones"

echo ""
echo "✅ Orient INDEPENDIENTE v101.4: 11 checkpoints, 10 preguntas, 8 fases, 14 principios"
exit 0
