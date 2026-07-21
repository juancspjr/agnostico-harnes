#!/usr/bin/env bash
# test_all.sh — Runner de tests bootstrap-proyecto
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
PASS=0; FAIL=0; SKIP=0

red='\033[31m'; green='\033[32m'; yellow='\033[33m'; nc='\033[0m'
pass() { PASS=$((PASS+1)); printf "  ${green}PASS${nc}  %s\n" "$*"; }
fail() { FAIL=$((FAIL+1)); printf "  ${red}FAIL${nc}  %s\n" "$*" >&2; }
skip() { SKIP=$((SKIP+1)); printf "  ${yellow}SKIP${nc}  %s\n" "$*"; }

echo "═══════════════════════════════════════"
echo "   Bootstrap-Proyecto — Tests estrictos"
echo "═══════════════════════════════════════"

for test in "$REPO_ROOT/.jcode/tests/bootstrap/test_gap"*.sh; do
  name="$(basename "$test")"
  echo ""
  echo "── $name ──"
  if [[ ! -x "$test" ]]; then
    skip "$test no ejecutable"; continue
  fi
  if output=$(bash "$test" 2>&1); then
    echo "$output" | grep -E "PASS|FAIL|Error|❌" | head -5
    pass "$name"
  else
    echo "$output" | tail -10
    fail "$name"
  fi
done

echo ""
echo "═══════════════════════════════════════"
echo "  Resultados: $PASS pass, $FAIL fail, $SKIP skip"
echo "═══════════════════════════════════════"
[[ $FAIL -eq 0 ]] || exit 1
exit 0
