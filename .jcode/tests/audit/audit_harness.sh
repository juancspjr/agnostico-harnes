#!/usr/bin/env bash
# =============================================================================
# audit_harness.sh — Auditoría de contaminación del arnés
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# 1. Ejecutar harness.sh check
check_output=$(bash "$JCODE_DIR/lib/harness.sh" check 2>&1)

# 2. Validar "0 contaminación" en output (puede ser 0 files)
echo "$check_output" | grep -qE "(0 contaminación|0 archivo.*contaminación|0 files with contamination)" \
  || echo "$check_output" | grep -q "✅ 0" \
  || fail "check no reporta 0 contaminación. Output: $check_output"
pass "check reporta 0 contaminación"

# 3. Verificar estructura completa
echo "$check_output" | grep -q "Estructura completa" \
  || fail "check no reporta 'Estructura completa'"
pass "check reporta estructura completa"

# 4. Verificar JSON válido
echo "$check_output" | grep -q "mcp.json válido" || fail "check no valida mcp.json"
echo "$check_output" | grep -q "compliance.json válido" || fail "check no valida compliance.json"
pass "JSON files validados"

# 5. Verificar 0 claves duplicadas
echo "$check_output" | grep -q "0 claves duplicadas" || fail "check no verifica duplicados"
pass "0 claves duplicadas en mcp.json"

echo "audit_harness: OK"
exit 0