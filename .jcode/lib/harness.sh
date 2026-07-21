#!/usr/bin/env bash
# =============================================================================
# .jcode/lib/harness.sh — Comando /h$ del arnés (agnóstico)
# =============================================================================
# Bug fixed: detector de contaminación ya NO se excluye a sí mismo.
# Bug fixed: status ya NO lanza run_all.sh (instantáneo).
# Bug fixed: init ya NO lanza run_all.sh --quick (era 3 capas de init).
# =============================================================================

set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"

# Source state_manager
source "$JCODE_DIR/lib/state_manager.sh"

# =============================================================================
# Help
# =============================================================================
cmd_help() {
  cat <<'EOF'
harness.sh — Comando /h$ del arnés jcode

Usage:
  harness.sh init                Inicializa state + integrity check
  harness.sh status              Estado del arnés (instantáneo)
  harness.sh check               Auditoría agnóstica (contaminación + integrity)
  harness.sh focus               Alerta de enfoque (loop actual)
  harness.sh score               Compliance score
  harness.sh breakdown           Score detallado
  harness.sh new-turn            Bumpear turno
  harness.sh closeout            Validar closeout
  harness.sh help                Esta ayuda

Filosofía:
  - Agnóstico: cero paths de proyecto, cero contraseñas
  - Mínimo: solo lo esencial
  - Nativo: usa jcode swarm nativo, NO reimplementa
EOF
}

# =============================================================================
# init — state init + integrity check (sin run_all.sh)
# =============================================================================
cmd_init() {
  state_init
  echo "[harness] state init OK"

  # Integrity check: hooks existen y son ejecutables
  local hooks_dir="$JCODE_DIR/hooks"
  local missing=0
  for h in sessionstart turn_start turnend posttool; do
    if [[ ! -x "$hooks_dir/$h.sh" ]]; then
      echo "[harness] WARN: hook $h.sh falta o no es ejecutable"
      missing=$((missing + 1))
    fi
  done
  if [[ $missing -eq 0 ]]; then
    echo "[harness] 4 hooks OK"
  fi

  # Canonical dirs
  for d in lib hooks skills templates iterations visualizer; do
    if [[ ! -d "$JCODE_DIR/$d" ]]; then
      echo "[harness] WARN: dir $d/ falta"
    fi
  done

  echo "[harness] init complete"
}

# =============================================================================
# status — instantáneo, sin side effects
# =============================================================================
cmd_status() {
  state_init
  local session_id=$(state_get session_id)
  local turn=$(state_get turn)
  local reads=$(state_get reads_this_turn)
  local cumul=$(state_get cumulative_reads)
  local srsi=$(state_get srsi_done_this_turn)
  local ddlp=$(state_get ddlp_done)
  local handoff=$(state_get handoff_written)
  local strikes=$(state_get r_aa_1_strikes)
  local loop=$(state_get current_loop_id)
  local iter=$(state_get current_loop_iter)
  local budget=$(state_get current_loop_budget)
  local score=$(state_compliance_score)

  # Sanitizar vacíos
  [[ -z "$turn" ]] && turn=0
  [[ -z "$reads" ]] && reads=0
  [[ -z "$cumul" ]] && cumul=0
  [[ -z "$strikes" ]] && strikes=0
  [[ -z "$iter" ]] && iter=0
  [[ -z "$budget" ]] && budget=0
  [[ -z "$loop" || "$loop" == "null" ]] && loop="(ninguno)"
  [[ -z "$srsi" ]] && srsi="false"
  [[ -z "$ddlp" ]] && ddlp="false"
  [[ -z "$handoff" ]] && handoff="false"

  echo "=== Harness Status ==="
  echo "Repo root  : $REPO_ROOT"
  echo "JCODE_DIR  : $JCODE_DIR"
  echo "Session ID : $session_id"
  echo "Turn       : $turn"
  echo "Reads turn : $reads"
  echo "Cumulative : $cumul"
  echo "SRSI       : $srsi"
  echo "DDLP       : $ddlp"
  echo "Handoff    : $handoff"
  echo "Strikes    : $strikes"
  echo "Score      : $score/100"
  echo "Loop       : $loop ($iter/$budget)"
  echo "======================"
}

# =============================================================================
# check — auditoría agnóstica
# =============================================================================
# EXCLUDE_PATHS: paths RELATIVOS a .jcode/ que NO se auditan.
# Son paths del PROYECTO (no del arnés): tests, evidence, scratch, state,
# logs, iterations/archive. Estos pueden contener nombres del dominio (esperado).
# porque SON del proyecto, no contaminación del arnés.
# =============================================================================
cmd_check() {
  echo "=== Harness Audit ==="

  # Paths a EXCLUIR de la auditoría (relativos a .jcode/)
  # Usamos patrones glob que matcheen en cualquier profundidad
  local EXCLUDE_PATHS=(
    "tests/**"
    "scratch/**"
    "state/**"
    "logs/**"
    "docs/**"
    "iterations/archive/**"
    "iterations/PLAN-VIVO.md"
    "iterations/PLAN-VIVO.template.md"
    "iterations/INDEX.md"
    "iterations/STATE/**"
    "iterations/ARCH/**"
    "iterations/REM/**"
    "iterations/REV/**"
    "iterations/PLAN/**"
    "iterations/OP/**"
    "iterations/SPRINT-F-LOOP.md"
    "visualizer/server/node_modules/**"
    "visualizer/server/package-lock.json"
  )

  # Construir argumentos --glob para rg (excluir paths del proyecto)
  local rg_exclude_args=()
  for p in "${EXCLUDE_PATHS[@]}"; do
    rg_exclude_args+=( --glob "!$p" )
  done
  rg_exclude_args+=( --glob "!contamination_patterns.txt" )
  rg_exclude_args+=( --glob "!clean-contamination.sh" )

  # 1. Contaminación de proyecto — SOLO en archivos del arnés puro
  echo "[1] Contaminación de proyecto en archivos del ARNÉS (excluye tests/state/iterations/scratch/logs)..."
  local contamination=0
  local patterns_file="$JCODE_DIR/lib/contamination_patterns.txt"

  if [[ ! -f "$patterns_file" ]]; then
    echo "    ⚠️  patterns file no encontrado: $patterns_file"
  else
    # Hacer cd al JCODE_DIR para que los --glob relativos funcionen
    while IFS= read -r pattern; do
      [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
      local files=$(cd "$JCODE_DIR" && rg -l -i --no-messages "${rg_exclude_args[@]}" "$pattern" . 2>/dev/null || true)
      local count=0
      if [[ -n "$files" ]]; then
        # Quitar el prefijo "./" y contar
        count=$(echo "$files" | grep -c . || echo 0)
      fi
      if [[ "$count" -gt 0 ]]; then
        echo "    ❌ '$pattern' encontrado en $count archivo(s) del arnés:"
        echo "$files" | head -5 | sed "s|^\./|      $JCODE_DIR/|"
        contamination=$((contamination + count))
      fi
    done < "$patterns_file"
  fi

  if [[ $contamination -eq 0 ]]; then
    echo "    ✅ 0 contaminación en archivos del arnés"
  else
    echo "    ❌ $contamination archivo(s) del arnés con contaminación (ver arriba)"
    echo "    ℹ️  Los archivos en tests/ scratch/ state/ logs/ iterations/ NO se auditan"
    echo "    ℹ️  Para limpiarlos ver: bash .jcode/lib/clean-contamination.sh --help"
  fi

  # 2. Integrity
  echo "[2] Integrity..."
  local issues=0
  for f in PRINCIPLES.md AGENT-PROTOCOL.md LOOPS.md README.md config.toml mcp.json; do
    if [[ ! -f "$JCODE_DIR/$f" ]]; then
      echo "    ❌ Falta $f"
      issues=$((issues + 1))
    fi
  done
  for d in hooks lib skills templates iterations; do
    if [[ ! -d "$JCODE_DIR/$d" ]]; then
      echo "    ❌ Falta dir $d/"
      issues=$((issues + 1))
    fi
  done
  if [[ $issues -eq 0 ]]; then
    echo "    ✅ Estructura completa"
  fi

  # 3. JSON válido
  echo "[3] JSON validity..."
  if python3 -c "import json;json.load(open('$JCODE_DIR/mcp.json'))" 2>/dev/null; then
    echo "    ✅ mcp.json válido"
  else
    echo "    ❌ mcp.json inválido"
  fi
  if [[ -f "$JCODE_DIR/state/compliance.json" ]]; then
    if python3 -c "import json;json.load(open('$JCODE_DIR/state/compliance.json'))" 2>/dev/null; then
      echo "    ✅ compliance.json válido"
    else
      echo "    ❌ compliance.json inválido"
    fi
  fi

  # 4. Duplicados en JSON
  echo "[4] JSON duplicate keys..."
  local dups=$(python3 -c "
import json, sys
with open('$JCODE_DIR/mcp.json') as f:
    txt = f.read()
# Crude check: parse con object_pairs_hook para detectar duplicados
dups = []
class Check:
    def __init__(self): self.seen=set()
    def __call__(self, pairs):
        keys=set()
        for k,v in pairs:
            if k in keys: dups.append(k)
            keys.add(k)
        return dict(pairs)
json.loads(txt, object_pairs_hook=Check())
print(len(dups))
" 2>/dev/null || echo 0)
  if [[ "$dups" -eq 0 ]]; then
    echo "    ✅ 0 claves duplicadas en mcp.json"
  else
    echo "    ❌ $dups claves duplicadas en mcp.json"
  fi

  echo "=== Audit complete ==="
}

# =============================================================================
# focus — alerta de enfoque
# =============================================================================
cmd_focus() {
  state_init
  local loop=$(state_get current_loop_id)
  local iter=$(state_get current_loop_iter)
  local budget=$(state_get current_loop_budget)
  local strikes=$(state_get r_aa_1_strikes)

  # Sanitizar
  [[ -z "$iter" ]] && iter=0
  [[ -z "$budget" ]] && budget=0
  [[ -z "$strikes" ]] && strikes=0

  echo "=== FOCUS ==="
  if [[ -z "$loop" ]] || [[ "$loop" == "null" ]]; then
    echo "⚠️  No hay loop activo. Declarar uno antes de trabajar."
    echo "   Formato: L-{TYPE}-{NNN} (ver LOOPS.md)"
    echo "============="
    return 1
  fi
  echo "Loop    : $loop"
  echo "Iter    : $iter/$budget"
  if [[ $budget -gt 0 ]] && [[ $iter -ge $budget ]]; then
    echo "🚨 BUDGET AGOTADO — declarar cierre o pedir extensión"
  fi
  if [[ $strikes -ge 2 ]]; then
    echo "🚨 $strikes strikes — activar R-3STRIKE-MVP (cambiar método)"
  fi
  local score=$(state_compliance_score)
  if [[ $score -lt 80 ]]; then
    echo "⚠️  Score $score/100 — debajo de 80"
  fi
  echo "============="
}

# =============================================================================
# CLI dispatch
# =============================================================================
case "${1:-help}" in
  init)      cmd_init ;;
  status)    cmd_status ;;
  check)     cmd_check ;;
  focus)     cmd_focus ;;
  score)     state_compliance_score ;;
  breakdown) state_compliance_breakdown ;;
  new-turn)  state_new_turn ;;
  closeout)  state_closeout ;;
  help|*)    cmd_help ;;
esac
