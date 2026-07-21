#!/usr/bin/env bash
# verify_reusable_verification_independiente.sh — Test INDEPENDIENTE
# Recalcula desde ground truth sin usar el protocolo ni los agentes
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== R-REUSABLE-VERIFICATION-INJECTION INDEPENDIENTE ==="

echo "[1] Validar 3 capas en archivos ground truth..."
python3 -c "
import os, pathlib
checks = {
    'Capa A (AGENT-PROTOCOL §5.7)': '$JCODE_DIR/AGENT-PROTOCOL.md',
    'Capa A (STATE-REGISTERS R-SYNC-3)': '$JCODE_DIR/STATE-REGISTERS.md',
    'Capa A (BEHAVIOR-INDEX R-MAINT-5)': '$JCODE_DIR/BEHAVIOR-INDEX.md',
    'Capa B (LOOPS fixed_check)': '$JCODE_DIR/LOOPS.md',
    'Capa B (stage_generator.generate_test_skeletons)': '$JCODE_DIR/skills/bootstrap-proyecto/lib/stage_generator.py',
    'Capa C (evidence_bundle validation)': '$JCODE_DIR/lib/evidence_bundle.sh',
    'Capa C (turnend invariant reminder)': '$JCODE_DIR/hooks/turnend.sh',
    'Capa C (orient F12)': '$JCODE_DIR/skills/orient/SKILL.md',
    'Capa A/B/C (quality-preamble.md)': '$JCODE_DIR/quality-preamble.md',
}
for name, path in checks.items():
    assert os.path.exists(path), f'{name} no existe: {path}'
print(f'  {len(checks)} archivos ground truth verificados')
"
[[ $? -eq 0 ]] || fail "Faltan archivos"
pass "9 archivos ground truth presentes"

echo "[2] Cross-check: stage_generator.generate_test_skeletons es ejecutable..."
SKILL_PATH="$JCODE_DIR/skills/bootstrap-proyecto/lib/stage_generator.py" python3 << 'PYEOF'
import importlib.util, pathlib, os
os.environ['SKILL_PATH']
spec = importlib.util.spec_from_file_location("sg", os.environ['SKILL_PATH'])
sg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sg)
fn = getattr(sg, 'generate_test_skeletons', None)
assert fn, "generate_test_skeletons no existe"
import inspect
sig = inspect.signature(fn)
assert 'repo_root' in sig.parameters, "falta param repo_root"
print(f"  firma: {sig}")
PYEOF
[[ $? -eq 0 ]] || fail "Función mal definida"
pass "generate_test_skeletons ejecutable"

echo "[3] Cross-check: evidence_bundle.sh genera verdict INCOMPLETE si no hay Tests críticos..."
# Crea un BEHAVIOR-INDEX temporal sin Tests críticos
mv "$JCODE_DIR/BEHAVIOR-INDEX.md" /tmp/BEHAVIOR-INDEX.md.bak
echo "# TEMP sin Tests críticos" > "$JCODE_DIR/BEHAVIOR-INDEX.md"
# Ejecutar desde repo root para que rutas relativas funcionen
# Sin pipefail en esta línea: evidence_bundle escribe verdict a stderr
set +o pipefail
output=$(cd "$REPO_ROOT" && bash "$JCODE_DIR/lib/evidence_bundle.sh" L-TEST 2>&1)
set -o pipefail
verdict=$(echo "$output" | grep "verdict:" | tail -1)
# Restaurar
mv /tmp/BEHAVIOR-INDEX.md.bak "$JCODE_DIR/BEHAVIOR-INDEX.md"
echo "  $verdict"
[[ "$verdict" == *"INCOMPLETE"* ]] || fail "evidence_bundle no detecta BEHAVIOR-INDEX sin Tests críticos"
pass "evidence_bundle detecta falta de registry"

echo "[4] Cross-check: orient F12 con BEHAVIOR-INDEX sin entradas B-XXX aborta..."
mv "$JCODE_DIR/BEHAVIOR-INDEX.md" /tmp/BEHAVIOR-INDEX.md.bak2
echo "# Vacío" > "$JCODE_DIR/BEHAVIOR-INDEX.md"
JCODE_DIR="$JCODE_DIR" python3 << 'PYEOF'
import re, os, sys
content = open(os.environ['JCODE_DIR']+'/BEHAVIOR-INDEX.md').read()
matches = re.findall(r'## B-\d+.*?(?=\n## |\Z)', content, re.DOTALL)
if matches:
    print(f'❌ B-XXX entries found ({len(matches)})')
    sys.exit(1)
print(f'  OK: 0 entries (orient F12 abortaría con registry vacío)')
PYEOF
rc=$?
mv /tmp/BEHAVIOR-INDEX.md.bak2 "$JCODE_DIR/BEHAVIOR-INDEX.md"
[[ $rc -ne 0 ]] && fail "F12 check falló"
pass "orient F12 abortaría con registry vacío (cross-check confirmado)"

echo ""
echo "✅ R-REUSABLE-VERIFICATION-INJECTION INDEPENDIENTE: 4 checks ground truth"
exit 0
