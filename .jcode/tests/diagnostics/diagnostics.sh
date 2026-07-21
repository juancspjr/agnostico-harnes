#!/usr/bin/env bash
# =============================================================================
# diagnostics.sh — Diagnóstico profundo del arnés
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# 1. Ejecutar harness.sh check y validar output
check_output=$(bash "$JCODE_DIR/lib/harness.sh" check 2>&1)
echo "$check_output" | grep -q "Harness Audit" || fail "check no imprime 'Harness Audit'"
echo "$check_output" | grep -q "Audit complete" || fail "check no termina con 'Audit complete'"
pass "harness.sh check produce output canónico"

# 2. Ejecutar breakdown y validar estructura
bd_output=$(bash "$JCODE_DIR/lib/state_manager.sh" breakdown 2>&1)
echo "$bd_output" | grep -qE "reads\s*:" || fail "breakdown sin 'reads:'"
echo "$bd_output" | grep -qE "TOTAL\s*:" || fail "breakdown sin 'TOTAL:'"
pass "breakdown produce desglose estructurado"

# 3. Validar que mcp.json tiene estructura esperada
python3 -c "
import json
mcp = json.load(open('$JCODE_DIR/mcp.json'))
assert 'mcpServers' in mcp, 'Falta mcpServers en mcp.json'
print('✅ mcp.json tiene mcpServers')
" || fail "mcp.json sin mcpServers"
pass "mcp.json estructura válida"

# 4. Validar config.toml parseable (vía grep)
grep -qE "^\[project\]" "$JCODE_DIR/config.toml" || fail "config.toml sin [project]"
grep -qE "^\[workspace\]" "$JCODE_DIR/config.toml" || fail "config.toml sin [workspace]"
grep -qE "^\[jcode\]" "$JCODE_DIR/config.toml" || fail "config.toml sin [jcode]"
pass "config.toml tiene secciones [project], [workspace], [jcode]"

# 5. Validar que scripts lib son ejecutables
for f in harness.sh state_manager.sh; do
  [[ -x "$JCODE_DIR/lib/$f" ]] || fail "lib/$f no ejecutable"
done
pass "Scripts lib ejecutables"

echo "diagnostics: OK"
exit 0