#!/usr/bin/env bash
# ============================================================================
# .jcode/tests/run_all.sh — Runner global de tests (agnóstico)
# ============================================================================
# Ejecuta los tests del arnés y consolida resultados en:
#   - tests/evidence/latest.json   (último resultado)
#   - tests/evidence/{TS}/{test}.log (logs por timestamp)
#
# Uso:
#   bash .jcode/tests/run_all.sh            # corre todo
#   bash .jcode/tests/run_all.sh --quick    # solo smoke + diagnostics
#   bash .jcode/tests/run_all.sh --category smoke
#
# Categorías:
#   smoke, diagnostics, audit, measure, validation
#
# Este script es AGNÓSTICO al proyecto. Cada proyecto debe poblar las
# categorías con sus propios tests específicos en las subcarpetas.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVIDENCE_DIR="$SCRIPT_DIR/evidence"
TS=$(date -u +%Y-%m-%dT%H-%M-%S)
SNAPSHOT_DIR="$EVIDENCE_DIR/${TS%T*}"
mkdir -p "$SNAPSHOT_DIR"

QUICK=0
CATEGORY=""
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=1 ;;
    --category) CATEGORY="${2:-}"; shift ;;
  esac
done

RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; NC="\033[0m"
pass() { printf "  ${GREEN}PASS${NC}  %s\n" "$*"; }
fail() { printf "  ${RED}FAIL${NC}  %s\n" "$*"; }
info() { printf "  ${YELLOW}INFO${NC}  %s\n" "$*"; }

# ── Definir tests por categoría ──
declare -A CATEGORIES=(
  [smoke]="smoke_harness_flow.sh smoke_hook_enforcement.sh smoke_r_aa_1.sh smoke_agent_protocol.sh smoke_r_no_fake_swarm.sh smoke_ddlp_tpsp.sh smoke_paper_compliance.sh"
  [diagnostics]="diagnostics.sh"
  [audit]="audit_harness.sh"
  [measure]="measure_harness.sh"
  [validation]=""
)

# ── Selección de categorías ──
if [[ -n "$CATEGORY" ]]; then
  CATS=("$CATEGORY")
elif [[ $QUICK -eq 1 ]]; then
  CATS=("smoke" "diagnostics")
else
  CATS=("smoke" "diagnostics" "audit" "measure")
fi

# ── Run ──
total_pass=0
total_fail=0
total_skip=0
results_json="{"
first=1

for cat in "${CATS[@]}"; do
  echo ""
  echo "=== Categoría: $cat ==="
  tests_str="${CATEGORIES[$cat]:-}"
  if [[ -z "$tests_str" ]]; then
    info "Sin tests definidos para categoría '$cat'"
    results_json+="\"$cat\":{\"status\":\"SKIP\",\"tests\":0},"
    continue
  fi

  cat_pass=0
  cat_fail=0
  cat_skip=0

  for t in $tests_str; do
    test_path="$SCRIPT_DIR/$cat/$t"
    if [[ ! -x "$test_path" ]] && [[ ! -f "$test_path" ]]; then
      info "$t: archivo no existe, skip"
      cat_skip=$((cat_skip + 1))
      continue
    fi

    log_file="$SNAPSHOT_DIR/${t%.sh}.log"
    if bash "$test_path" > "$log_file" 2>&1; then
      pass "$t"
      cat_pass=$((cat_pass + 1))
    else
      fail "$t (log: $log_file)"
      cat_fail=$((cat_fail + 1))
    fi
  done

  echo "  Resultado: ${cat_pass} pass, ${cat_fail} fail, ${cat_skip} skip"
  total_pass=$((total_pass + cat_pass))
  total_fail=$((total_fail + cat_fail))
  total_skip=$((total_skip + cat_skip))

  [[ $first -eq 0 ]] && results_json+=","
  first=0
  status="PASS"
  [[ $cat_fail -gt 0 ]] && status="FAIL"
  [[ $cat_pass -eq 0 && $cat_fail -eq 0 ]] && status="SKIP"
  results_json+="\"$cat\":{\"status\":\"$status\",\"passes\":$cat_pass,\"fails\":$cat_fail,\"skips\":$cat_skip}"
done

# Quitar última coma
results_json="${results_json%,}"
results_json+="}"

# ── Resumen final ──
echo ""
echo "═══════════════════════════════════════"
echo "  TOTAL: $total_pass pass, $total_fail fail, $total_skip skip"
echo "═══════════════════════════════════════"

# ── Latest summary ──
latest="$EVIDENCE_DIR/latest.json"
python3 -c "
import json, sys
result = {
    'last_run': '$TS',
    'categories': json.loads('''$results_json''') if '''$results_json'''.strip().startswith('{') else {},
    'summary': {
        'total_passes': $total_pass,
        'total_fails': $total_fail,
        'total_skips': $total_skip,
    },
}
json.dump(result, open('$latest', 'w'), indent=2)
"

# Exit code: 0 si todo verde, 1 si hay failures
[[ $total_fail -eq 0 ]] && exit 0 || exit 1