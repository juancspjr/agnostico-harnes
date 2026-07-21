#!/usr/bin/env bash
# verify_reusable_verification.sh — Test propio
# Valida que el protocolo R-REUSABLE-VERIFICATION-INJECTION está cableado
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== R-REUSABLE-VERIFICATION-INJECTION — cableado ==="

echo "[1] Capa A — AGENT-PROTOCOL §5.7 cableada..."
grep -q "5\.7\." "$JCODE_DIR/AGENT-PROTOCOL.md" || fail "Falta §5.7"
grep -q "INYECCIÓN DE VERIFICACIÓN REUTILIZABLE" "$JCODE_DIR/AGENT-PROTOCOL.md" || fail "Falta ítem §5.7"
pass "AGENT-PROTOCOL §5.7 presente"

echo "[2] Capa A — STATE-REGISTERS R-SYNC-3 referencia invariant scripts..."
grep -q "R-SYNC-3" "$JCODE_DIR/STATE-REGISTERS.md" || fail "Falta R-SYNC-3"
grep -q "tests/validation/invariant_<campo>.sh" "$JCODE_DIR/STATE-REGISTERS.md" || fail "Falta referencia a invariant script"
grep -q "R-SYNC-5" "$JCODE_DIR/STATE-REGISTERS.md" || fail "Falta R-SYNC-5"
pass "STATE-REGISTERS R-SYNC-3/5 presentes"

echo "[3] Capa A — BEHAVIOR-INDEX R-MAINT-5/6 + Tests críticos..."
grep -q "R-MAINT-5" "$JCODE_DIR/BEHAVIOR-INDEX.md" || fail "Falta R-MAINT-5"
grep -q "R-MAINT-6" "$JCODE_DIR/BEHAVIOR-INDEX.md" || fail "Falta R-MAINT-6"
grep -q "tests/integration/test_<feature>.sh" "$JCODE_DIR/BEHAVIOR-INDEX.md" || fail "Falta referencia integration"
grep -q "tests/validation/contract_<modulo>.sh" "$JCODE_DIR/BEHAVIOR-INDEX.md" || fail "Falta referencia contract"
pass "BEHAVIOR-INDEX cableado"

echo "[4] Capa B — LOOPS.md fixed_check como ruta a tests/..."
grep -q "tests/integration/test_<feature>.sh" "$JCODE_DIR/LOOPS.md" || fail "Falta fixed_check como ruta"
pass "LOOPS fixed_check es ruta"

echo "[5] Capa B — bootstrap-proyecto genera_test_skeletons..."
python3 -c "
import sys
sys.path.insert(0, '$JCODE_DIR/skills/bootstrap-proyecto/lib')
from stage_generator import generate_test_skeletons
fn = generate_test_skeletons
import inspect
sig = inspect.signature(fn)
assert 'repo_root' in sig.parameters, 'falta param'
src = inspect.getsource(fn)
assert 'TODO' in src, 'falta placeholder TODO'
assert 'set -euo pipefail' in src, 'falta set -euo pipefail'
print('  OK')
"
[[ $? -eq 0 ]] || fail "generate_test_skeletons mal"
pass "stage_generator.generate_test_skeletons implementado"

echo "[6] Capa C — evidence_bundle.sh valida behavior_index_registered..."
grep -q "behavior_index_registered\|BEHAVIOR_REGISTERED" "$JCODE_DIR/lib/evidence_bundle.sh" || fail "Falta validación"
pass "evidence_bundle valida registry"

echo "[7] Capa C — turnend.sh detecta campos STATE-REGISTERS..."
grep -q "invariant_<campo>.sh" "$JCODE_DIR/hooks/turnend.sh" || fail "Falta recordatorio"
pass "turnend.sh detecta invariantes"

echo "[8] Capa C — orient F12 implementado..."
grep -q "Checkpoint F12\|Test registry sync" "$JCODE_DIR/skills/orient/SKILL.md" || fail "Falta F12"
grep -q "F9-F12\|F12" "$JCODE_DIR/skills/orient/SKILL.md" || fail "F12 no en matriz"
pass "orient F12 cableado"

echo "[9] Capa A/B/C — quality-preamble.md tiene el protocolo..."
grep -q "R-REUSABLE-VERIFICATION-INJECTION" "$JCODE_DIR/quality-preamble.md" || fail "Falta protocolo en preamble"
grep -q "CAPA A" "$JCODE_DIR/quality-preamble.md" || fail "Falta Capa A"
grep -q "CAPA B" "$JCODE_DIR/quality-preamble.md" || fail "Falta Capa B"
grep -q "CAPA C" "$JCODE_DIR/quality-preamble.md" || fail "Falta Capa C"
pass "quality-preamble.md inyecta el protocolo"

echo ""
echo "✅ R-REUSABLE-VERIFICATION-INJECTION: 9 checks, 3 capas cableadas"
exit 0
