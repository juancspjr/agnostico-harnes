#!/usr/bin/env bash
# evidence_bundle.sh — Arma el evidence bundle desde logs existentes.
# Implementa FAILURE-PATTERNS.md §4 sin que el agente lo haga a mano.
# Uso: bash .jcode/lib/evidence_bundle.sh [loop_id]
set -euo pipefail

LOOP_ID="${1:-unknown}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OUT=".jcode/logs/evidence-bundle-${LOOP_ID}-$(date -u +%Y%m%d-%H%M%S).md"

FIXED_CHECK="$(grep -A1 'fixed_check' .jcode/iterations/PLAN-VIVO.md 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//' || echo 'N/A')"

REGRESSION_OUTPUT="$(bash .jcode/tests/run_all.sh 2>&1 | tail -3 || echo 'regression failed')"

DIFF_STAT="$(git diff --stat HEAD~1 2>/dev/null || echo 'no previous commit')"

FILES_CHANGED="$(git diff --name-only HEAD~1 2>/dev/null | wc -l | tr -d ' ')"

INDEP_TEST="$(ls .jcode/tests/audit/verify_*_independiente.sh 2>/dev/null | head -1 || echo 'MISSING')"

ITER_LOG="$(ls .jcode/logs/remediation-*-iter*.log 2>/dev/null | tail -1 || echo 'MISSING')"

if [[ "$INDEP_TEST" == "MISSING" || "$ITER_LOG" == "MISSING" ]]; then
  VERDICT="INCOMPLETE — falta test independiente o iteration log"
else
  # Capa C: validar que BEHAVIOR-INDEX.md tiene Tests críticos
  # registrados para los loops del B-XXX actual.
  # Match estricto: 'Tests críticos' como entry de campo (con/sin markdown bold)
  if grep -qE "^\s*-?\s*\*\*?Tests críticos\*\*?\s*:" .jcode/BEHAVIOR-INDEX.md 2>/dev/null; then
    BEHAVIOR_REGISTERED="true"
  else
    BEHAVIOR_REGISTERED="false"
  fi
  if [[ "$BEHAVIOR_REGISTERED" == "false" ]]; then
    VERDICT="INCOMPLETE — BEHAVIOR-INDEX sin Tests críticos (orient F12 abortaría)"
  else
    VERDICT="PENDING — revisar outputs arriba"
  fi
fi

{
  echo "# Evidence Bundle"
  echo "- loop_id: ${LOOP_ID}"
  echo "- timestamp: ${TS}"
  echo "- fixed_check: ${FIXED_CHECK}"
  echo "- independent_test: ${INDEP_TEST}"
  echo "- iteration_log: ${ITER_LOG}"
  echo "- regression_tail:"
  echo '```'
  echo "$REGRESSION_OUTPUT" | sed 's/^/    /'
  echo '```'
  echo "- diff_stat:"
  echo '```'
  echo "$DIFF_STAT" | sed 's/^/    /'
  echo '```'
  echo "- files_changed: ${FILES_CHANGED}"
  echo "- verdict: ${VERDICT}"
} > "$OUT"

echo "[evidence_bundle] escrito: $OUT" >&2
echo "[evidence_bundle] verdict: $VERDICT" >&2
