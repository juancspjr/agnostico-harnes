#!/usr/bin/env bash
# =============================================================================
# smoke_ddlp_tpsp.sh — Valida estructura DDLP/TPSP en PLAN-VIVO.template
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

TEMPLATE="$JCODE_DIR/iterations/PLAN-VIVO.template.md"
[[ -f "$TEMPLATE" ]] || fail "Falta PLAN-VIVO.template.md"

# DDLP: §3 gaps, §4 solicitudes, §5 cronología
grep -q "## §3" "$TEMPLATE" || fail "Falta §3 (gaps)"
grep -q "## §4" "$TEMPLATE" || fail "Falta §4 (solicitudes)"
grep -q "## §5" "$TEMPLATE" || fail "Falta §5 (cronología)"
pass "PLAN-VIVO.template tiene §3, §4, §5 (DDLP)"

# TPSP: §3 backlog + §5 cronología + manejo de "cliente pide algo nuevo"
grep -q "Backlog\|backlog\|gaps" "$TEMPLATE" || fail "Falta referencia a backlog"
grep -q "cronología\|cronologia" "$TEMPLATE" || fail "Falta referencia a cronología"
pass "PLAN-VIVO.template referencia backlog y cronología (TPSP)"

# Verificar principios DDLP y TPSP en PRINCIPLES.md
grep -q "DDLP" "$JCODE_DIR/PRINCIPLES.md" || fail "PRINCIPLES.md no menciona DDLP"
grep -q "TPSP" "$JCODE_DIR/PRINCIPLES.md" || fail "PRINCIPLES.md no menciona TPSP"
pass "PRINCIPLES.md declara DDLP y TPSP"

echo "smoke_ddlp_tpsp: OK"
exit 0