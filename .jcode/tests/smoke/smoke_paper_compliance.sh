#!/usr/bin/env bash
# =============================================================================
# smoke_paper_compliance.sh — Valida los 3 pilares del paper Harness Handbook
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# Pilar 1: Construction Pipeline
test -f "$JCODE_DIR/lib/handbook_builder.py" || fail "Falta handbook_builder.py"
test -f "$JCODE_DIR/lib/handbook_phase2.py" || fail "Falta handbook_phase2.py"
test -f "$JCODE_DIR/lib/handbook_phase3.py" || fail "Falta handbook_phase3.py"
test -f "$JCODE_DIR/handbook/program_graph.json" || fail "Falta program_graph.json"
test -f "$JCODE_DIR/handbook/behavioral_mapping.json" || fail "Falta behavioral_mapping.json"
test -f "$JCODE_DIR/handbook/references/overview.md" || fail "Falta overview.md (L1)"
test -f "$JCODE_DIR/handbook/references/index.md" || fail "Falta index.md"
test -f "$JCODE_DIR/handbook/references/registers.md" || fail "Falta registers.md (vista Z)"
ls "$JCODE_DIR/handbook/references/stages/"*.md >/dev/null 2>&1 || fail "Faltan L2 stage pages"
pass "Pilar 1: Construction Pipeline completo"

# Pilar 2: Resync
test -f "$JCODE_DIR/lib/handbook_resync.py" || fail "Falta handbook_resync.py"
test -f "$JCODE_DIR/handbook/K_g.json" || fail "Falta K_g.json (resync state)"
test -f "$JCODE_DIR/handbook/frozen_entries.json" || fail "Falta frozen_entries.json"
grep -q "handbook_resync.py" "$JCODE_DIR/hooks/turnend.sh" || fail "turnend.sh no invoca resync"
pass "Pilar 2: Resync automático configurado"

# Pilar 3: BGPD verification
test -f "$JCODE_DIR/lib/handbook_verify.py" || fail "Falta handbook_verify.py"
test -f "$JCODE_DIR/skills/handbook/SKILL.md" || fail "Falta skill handbook/SKILL.md"
grep -qE 'VERIFY' "$JCODE_DIR/skills/orient/SKILL.md" || fail "skill orient/ sin paso VERIFY"
pass "Pilar 3: BGPD con source verification"

# Edit Planning con Γ
grep -q "will_modify" "$JCODE_DIR/templates/OP.md" || fail "OP.md sin Γ declarations"
grep -q "will_add" "$JCODE_DIR/templates/OP.md" || fail "OP.md sin Γ declarations"
grep -q "will_remove" "$JCODE_DIR/templates/OP.md" || fail "OP.md sin Γ declarations"
pass "Edit Planning con Γ declarations"

# Validar L3 entries > 0
l3_count=$(python3 -c "import json; d=json.load(open('$JCODE_DIR/handbook/cache_B.json')); print(len(d.get('l3_entries', {})))" 2>/dev/null || echo "0")
[[ $l3_count -gt 0 ]] || fail "L3 entries = 0 (esperado > 0)"
pass "L3 entries > 0: $l3_count"

echo "smoke_paper_compliance: OK"
exit 0