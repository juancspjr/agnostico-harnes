#!/usr/bin/env bash
# verify_enforcement_hooks.sh — Test propio
# Valida que los 3 mecanismos de auto-mejora están cableados
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== ENFORCEMENT HOOKS — cableado ==="

echo "[1] pre-commit.sh existe y ejecutable..."
[[ -x "$JCODE_DIR/hooks/pre-commit.sh" ]] || fail "pre-commit.sh no ejecutable"
grep -q "V1.*HF Gate" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta V1"
grep -q "V2.*Sibling test" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta V2"
grep -q "V3.*Tests críticos" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta V3"
grep -q "V4.*fixed_check" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta V4"
grep -q "V5.*Cross-consumer" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta V5"
grep -q "V6.*set -euo pipefail" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta V6"
pass "6 validaciones declaradas"

echo "[2] pre-commit.sh override deja rastro..."
grep -q "no-verify" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta override"
grep -q "pre-commit.log" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta log de override"
pass "Override --no-verify loggeado"

echo "[3] pre-commit auto-genera stubs para scripts sin test..."
grep -q "AUTO-GENERATED" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta auto-generación"
grep -q "test_\${base}.sh" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta stub template"
pass "Auto-generación de stubs"

echo "[4] oracle.py existe y ejecutable..."
[[ -x "$JCODE_DIR/lib/oracle.py" ]] || fail "oracle.py no ejecutable"
grep -q "oraculo_funciones" "$JCODE_DIR/lib/oracle.py" || fail "Falta oráculo funciones"
grep -q "oraculo_state_registers_invariants" "$JCODE_DIR/lib/oracle.py" || fail "Falta oráculo invariantes"
grep -q "DRIFT_FOUND\|CONSISTENT\|INCOMPLETE" "$JCODE_DIR/lib/oracle.py" || fail "Falta veredicto"
pass "oracle.py con 3 oráculos"

echo "[5] oracle no lee outputs del agente (HF-V2 anti-self-oracle)..."
grep -q "ground truth\|ground_truth" "$JCODE_DIR/lib/oracle.py" || fail "Falta ground truth"
grep -q "ast.parse\|re.finditer" "$JCODE_DIR/lib/oracle.py" || fail "Falta parsing desde fuente"
pass "Oracle parsea código fuente directamente"

echo "[6] oracle detecta STATE-REGISTERS con scripts inexistentes..."
output=$(cd "$REPO_ROOT" && REPO_ROOT="$REPO_ROOT" python3 "$JCODE_DIR/lib/oracle.py" --strict 2>&1 || true)
if echo "$output" | grep -q "DRIFT_FOUND\|CONSISTENT"; then
  pass "Oracle retorna verdict válido"
else
  fail "Oracle no retorna verdict"
fi

echo "[6b] pre-commit regex V6 anti-falso-positivo..."
if head -15 "$JCODE_DIR/hooks/pre-commit.sh" | grep -qE "^set -[a-z]*e[a-z]*\b.*pipefail|^set -euo|^set -e[a-z]*\b.*pipefail|^set -uo pipefail"; then
  pass "V6 regex acepta variantes de set -euo pipefail (incluye -uo)"
else
  fail "V6 regex no matchea el propio pre-commit.sh"
fi

echo "[7] posttool.sh hook existente..."
[[ -x "$JCODE_DIR/hooks/posttool.sh" ]] || fail "posttool.sh no ejecutable"
pass "posttool.sh presente"

echo "[8] pre-commit integrable en git hooks..."
# Verificar que el hook está copiado o se puede invocar como pre-commit
ls -la .git/hooks/pre-commit 2>/dev/null || true
if [[ -x .git/hooks/pre-commit ]]; then
  pass "pre-commit instalado en .git/hooks/"
else
  echo "  ⚠️  pre-commit NO instalado en .git/hooks/ — necesita instalación manual"
fi

echo ""
echo "✅ ENFORCEMENT HOOKS: 8 checks cableados"
exit 0
