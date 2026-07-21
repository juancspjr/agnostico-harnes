#!/usr/bin/env bash
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
SKILL="$JCODE_DIR/skills/orient/SKILL.md"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== verify_orient_checkpoints v101.4: skill orient completo ==="

echo "[1] FASE 0 (Checkpoint F0: bootstrap) presente..."
grep -q "FASE 0: CHECKPOINT" "$SKILL" || fail "Falta FASE 0"
grep -qE "Checkpoint F0|CHECKPOINT F0" "$SKILL" || fail "Falta CHECKPOINT F0"
pass "FASE 0 + CHECKPOINT F0 presentes"

echo "[2] Árbol de decisión tiene 10 preguntas (P1-P10)..."
python3 -c "
import re
content = open('$SKILL').read()
p_count = len(re.findall(r'^P\d+\.', content, re.MULTILINE))
assert p_count >= 10, f'Solo {p_count} preguntas, se esperan ≥10'
print(f'  Preguntas: {p_count}')
"
[[ $? -eq 0 ]] || fail "Árbol incompleto"
pass "10 preguntas en árbol"

echo "[3] Flujo MAINTENANCE (Fase 2-D) presente..."
grep -q "FASE 2-D" "$SKILL" || fail "Falta Fase 2-D"
grep -q "MAINTENANCE" "$SKILL" || fail "Falta MAINTENANCE"
pass "Fase 2-D MAINTENANCE presente"

echo "[4] CHECKPOINTS F0-F11 ejecutables (11 total)..."
for chk in F0 F1 F1.5 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11; do
  if ! grep -qE "Checkpoint $chk|CHECKPOINT $chk" "$SKILL"; then
    fail "Falta checkpoint $chk"
  fi
done
pass "11+ checkpoints presentes"

echo "[5] Cada checkpoint tiene comando bash..."
SKILL_PATH="$JCODE_DIR/skills/orient/SKILL.md" python3 - << 'PYEOF'
import os, re, pathlib
content = pathlib.Path(os.environ['SKILL_PATH']).read_text()
checks = re.findall(r'### Checkpoint (\S+)[^`]*```bash(.*?)```', content, re.DOTALL)
assert len(checks) >= 11, f'Solo {len(checks)} checkpoints con bash, esperado ≥11'
for name, _ in checks:
    print(f'  F{name}: OK')
PYEOF
[[ $? -eq 0 ]] || fail "Checkpoints sin comando bash"
pass "Checkpoints con comandos bash"

echo "[6] Validación de cierre extendida..."
grep -q "compliance" "$SKILL" || fail "Falta compliance"
grep -q "PLAN-VIVO" "$SKILL" || fail "Falta PLAN-VIVO"
grep -q "harness.sh status" "$SKILL" || fail "Falta harness.sh status"
pass "Validación de cierre presente"

echo "[7] Anti-patrones nuevos (F1-F11)..."
for ap in "F1 (HF Gate)" "F3 (Evidence bundle)" "F4 (Self-critique)" "F5 (Reviewer)" "F11 (Cross-check)" "F9"; do
  grep -q "$ap" "$SKILL" || fail "Falta anti-patrón: $ap"
done
pass "Anti-patrones nuevos presentes"

echo "[8] Compatibilidad con 14 principios..."
for sec in "§3 SRSI" "§4 DDLP" "§7 R-VERIFY" "§8 R-INDEPENDENT" "§9 R-ITERATION" "§11 R-REGRESSION" "§12 R-CONTAMINATION" "§13 R-HIDDEN" "§14 R-FRONTIER"; do
  grep -q "$sec" "$SKILL" || fail "Falta referencia: $sec"
done
pass "9+ principios referenciados"

echo "[9] Skill referencia todos los archivos canónicos clave..."
for f in PRINCIPLES FAILURE-PATTERNS quality-preamble bootstrap-proyecto handbook_verify handbook_resync evidence_bundle; do
  grep -q "$f" "$SKILL" || fail "Falta referencia a $f"
done
pass "6+ archivos canónicos referenciados"

echo ""
echo "✅ Orient v101.4: 11 checkpoints + 10 preguntas + Fase 2-D + anti-patrones"
exit 0
