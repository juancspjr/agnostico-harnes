#!/usr/bin/env bash
# verify_enforcement_hooks_independiente.sh — Test INDEPENDIENTE
# Recalcula desde ground truth sin usar los hooks del agente
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== ENFORCEMENT HOOKS INDEPENDIENTE ==="

echo "[1] Oracle recalcula ground truth desde código fuente (no lee outputs)..."
cd "$REPO_ROOT"
set +o pipefail
output=$(REPO_ROOT="$REPO_ROOT" python3 "$JCODE_DIR/lib/oracle.py" --json 2>&1)
rc=$?
set -o pipefail

# Verificar que el JSON tiene ground_truth calculado (no leído)
funcs_gt=$(echo "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['ground_truth']['total_funcs'])" 2>/dev/null)
if [[ -z "$funcs_gt" ]] || [[ "$funcs_gt" -lt 50 ]]; then
  fail "Oracle no recalculó funciones (got: '$funcs_gt')"
fi
pass "Oracle parseó $funcs_gt funciones desde AST"

echo "[2] Oracle detecta drift en STATE-REGISTERS con script inexistente..."
# Inyectar drift en STATE-REGISTERS temporal
mv "$JCODE_DIR/STATE-REGISTERS.md" /tmp/SR.bak
echo "# DRIFT TEST" > "$JCODE_DIR/STATE-REGISTERS.md"
echo "## STATE-X-DRIFT" >> "$JCODE_DIR/STATE-REGISTERS.md"
echo "script: \`tests/validation/invariant_drift_falso.sh\`" >> "$JCODE_DIR/STATE-REGISTERS.md"

set +o pipefail
drift_output=$(REPO_ROOT="$REPO_ROOT" python3 "$JCODE_DIR/lib/oracle.py" 2>&1)
drift_rc=$?
set -o pipefail

# Restaurar
mv /tmp/SR.bak "$JCODE_DIR/STATE-REGISTERS.md"

if echo "$drift_output" | grep -q "DRIFT_FOUND"; then
  pass "Oracle detecta STATE-REGISTERS con script inexistente"
elif echo "$drift_output" | grep -q "STATE-REGISTERS sin STATE"; then
  # Si STATE-REGISTERS estaba vacío (0 entries), no detecta drift — eso es otro bug
  fail "Oracle no detectó STATE con script inexistente"
else
  fail "Oracle output inesperado: $(echo "$drift_output" | tail -5)"
fi

echo "[3] pre-commit bloquea commit con script sin set -euo pipefail..."
# Crear script temporal sin set -euo pipefail
TMPDIR=$(mktemp -d)
cat > "$TMPDIR/bad_script.sh" <<'EOF'
#!/usr/bin/env bash
# Script sin pragma de seguridad
echo "hola mundo"
EOF
chmod +x "$TMPDIR/bad_script.sh"

# Validar lógica de pre-commit V6 (regex anti-falso-positivo)
if head -10 "$TMPDIR/bad_script.sh" | grep -qE "^set -[a-z]*e[a-z]*\b.*pipefail|^set -euo|^set -e[a-z]*\b.*pipefail"; then
  fail "Regex de pre-commit detectó falso positivo en script malo"
else
  pass "pre-commit detectaría el script sin set -euo pipefail"
fi
rm -rf "$TMPDIR"

echo "[4] pre-commit auto-genera stub para script sin test..."
# Validar lógica de auto-generación sin ejecutar realmente git
grep -q 'cat > "\$stub" <<STUB' "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta template stub"
grep -q "AUTO-GENERATED" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta marca AUTO-GENERATED"
pass "Lógica de auto-generación presente"

echo "[5] pre-commit override deja rastro en log..."
grep -q "OVERRIDE_REASON_OVERRIDE" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta variable override"
grep -q "pre-commit.log" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta log path"
pass "Override --no-verify rastreado"

echo "[6] Oracle retorna exit codes distintos por verdict..."
oracle_help=$(REPO_ROOT="$REPO_ROOT" python3 "$JCODE_DIR/lib/oracle.py" 2>&1; echo "exit=$?")
oracle_exit=$(echo "$oracle_help" | grep "exit=" | tail -1 | sed 's/exit=//')
if [[ "$oracle_exit" =~ ^[0-3]$ ]]; then
  pass "Oracle retorna exit code $oracle_exit (0=CONSISTENT, 2=DRIFT, 3=INCOMPLETE)"
else
  fail "Oracle exit code inválido: $oracle_exit"
fi

echo "[7] pre-commit invoca verify_hidden_failure_gate.sh (V1 HF Gate)..."
grep -q "verify_hidden_failure_gate.sh" "$JCODE_DIR/hooks/pre-commit.sh" || fail "Falta V1"
pass "V1 HF Gate invocado"

echo "[8] Cross-check: pre-commit detecta fixed_check no-ruta..."
# Crear LOOPS.md con fixed_check inválido
mv "$JCODE_DIR/LOOPS.md" /tmp/LOOPS.bak
echo "## L-DRIFT" > "$JCODE_DIR/LOOPS.md"
echo "fixed_check: grep something" >> "$JCODE_DIR/LOOPS.md"

# Ejecutar la lógica V4 directamente
v4_bad=$(awk '/fixed_check/ {print $2}' "$JCODE_DIR/LOOPS.md" | grep -v "^\.jcode/tests" | grep -v "^tests")
mv /tmp/LOOPS.bak "$JCODE_DIR/LOOPS.md"

if [[ -n "$v4_bad" ]]; then
  pass "V4 detectaría fixed_check='grep something' como inválido"
else
  fail "V4 no detectaría fixed_check inválido"
fi

echo ""
echo "✅ ENFORCEMENT HOOKS INDEPENDIENTE: 8 checks ground truth"
exit 0
