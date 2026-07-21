#!/usr/bin/env bash
# =============================================================================
# smoke_agent_protocol.sh — Valida que los 11 items del checklist tienen mecanismo
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

PROTOCOL="$JCODE_DIR/AGENT-PROTOCOL.md"
[[ -f "$PROTOCOL" ]] || fail "Falta AGENT-PROTOCOL.md"

# Verificar que existen los items del checklist (1-11)
for i in 0 1 2 3 4 5 6 7 8 9 10 11; do
  # Buscar patrón "item N" o "Paso N" en el documento
  if ! grep -qE "(\*\*[0-9]+\.\*\*|\*\*[0-9]+\b|item $i|Paso $i)" "$PROTOCOL"; then
    fail "Item $i del checklist no encontrado en AGENT-PROTOCOL.md"
  fi
done
pass "Los 11 items del checklist están presentes"

# Verificar que los hooks principales existen
for h in sessionstart turn_start turnend posttool; do
  [[ -x "$JCODE_DIR/hooks/$h.sh" ]] || fail "Hook $h.sh faltante"
done
pass "Los 4 hooks principales son ejecutables"

# Verificar SRSI en posttool (item 1)
grep -q "grep|rg|agentgrep|ripgrep)" "$JCODE_DIR/hooks/posttool.sh" \
  || fail "posttool.sh no implementa item 1 (SRSI)"
pass "Item 1 (SRSI) implementado en posttool.sh"

# Verificar DDLP en §2 (manual)
grep -q "DDLP" "$PROTOCOL" || fail "DDLP no mencionado en protocolo"
pass "Item 2 (DDLP) referenciado"

# Verificar fixed_check (item 7)
grep -q "fixed_check" "$PROTOCOL" || fail "fixed_check no mencionado en protocolo"
pass "Item 7 (fixed_check) referenciado"

echo "smoke_agent_protocol: OK"
exit 0