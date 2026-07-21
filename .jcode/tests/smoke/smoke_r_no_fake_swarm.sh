#!/usr/bin/env bash
# =============================================================================
# smoke_r_no_fake_swarm.sh — Valida detector R-FAKE-COORDINATOR
# =============================================================================
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

# 1. Verificar que posttool.sh implementa el detector
grep -q "R-FAKE-COORDINATOR" "$JCODE_DIR/hooks/posttool.sh" \
  || fail "posttool.sh no implementa detector R-FAKE-COORDINATOR"
pass "posttool.sh implementa R-FAKE-COORDINATOR"

# 2. Verificar que la función state_record_swarm_spawn existe
grep -q "state_record_swarm_spawn" "$JCODE_DIR/lib/state_manager.sh" \
  || fail "state_manager.sh no define state_record_swarm_spawn"
pass "state_record_swarm_spawn definido"

# 3. Verificar que state_swarm_recent_within_turns existe
grep -q "state_swarm_recent_within_turns" "$JCODE_DIR/lib/state_manager.sh" \
  || fail "state_manager.sh no define state_swarm_recent_within_turns"
pass "state_swarm_recent_within_turns definido"

# 4. Verificar que el patrón de extensiones está (post-fix H-01)
if grep -qE "\\\\\\.\(go\|ts\|astro\|tsx\|jsx\|sql\|svelte\|css\|scss\|vue\)" "$JCODE_DIR/hooks/posttool.sh"; then
  pass "Patrón de extensiones presente (post-fix H-01)"
elif grep -qE "workspace.code_extensions" "$JCODE_DIR/hooks/posttool.sh"; then
  pass "Patrón lee de config.toml (post-fix H-02)"
else
  fail "Patrón de extensiones ausente en posttool.sh"
fi

# 5. Verificar bypass clause
grep -q "coord-self-authorize\|fake-coordinator-override" "$JCODE_DIR/hooks/posttool.sh" \
  || fail "posttool.sh sin bypass clause"
pass "Bypass clause §4.7 presente"

echo "smoke_r_no_fake_swarm: OK"
exit 0