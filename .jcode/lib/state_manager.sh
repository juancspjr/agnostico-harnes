#!/usr/bin/env bash
# =============================================================================
# .jcode/lib/state_manager.sh — Compliance state management (agnóstico)
# =============================================================================
# Bug fixed: score ahora suma 100 (antes sumaba 90).
# Bug fixed: eliminada dependencia de fases F1..F11 (era del proyecto anterior).
# Bug fixed: eliminado código duplicado en líneas 339-356.
# =============================================================================

set -uo pipefail

STATE_DIR="${STATE_DIR:-.jcode/state}"
STATE_FILE="$STATE_DIR/compliance.json"

# =============================================================================
# Init
# =============================================================================
state_init() {
  mkdir -p "$STATE_DIR"

  # Si existe pero está corrupto, hacer backup y recrear
  if [[ -f "$STATE_FILE" ]]; then
    if ! python3 -c "import json;json.load(open('$STATE_FILE'))" 2>/dev/null; then
      echo "[state] WARN: compliance.json corrupto, respaldando y recreando" >&2
      mv "$STATE_FILE" "$STATE_FILE.corrupt.$(date +%s).bak"
    fi
  fi

  # Si no existe (o se corrompió), crear fresh
  if [[ ! -f "$STATE_FILE" ]]; then
    cat > "$STATE_FILE" <<'JSON'
{
  "session_id": "",
  "turn": 0,
  "reads_this_turn": 0,
  "cumulative_reads": 0,
  "drill_done_this_turn": false,
  "srsi_done_this_turn": false,
  "ddlp_done": false,
  "handoff_written": false,
  "closeout_passed": false,
  "r_aa_1_strikes": 0,
  "r_3strike_mvp_activations": 0,
  "aa1_violations": [],
  "last_swarm_spawn_turn": 0,
  "last_swarm_role": "",
  "last_swarm_prompt_size": 0,
  "swarm_spawn_count_session": 0,
  "current_loop_id": null,
  "current_loop_budget": 0,
  "current_loop_iter": 0,
  "history": []
}
JSON
  fi

  # Migrar campos legacy si existen (reads_this_turn era list en versión vieja)
  python3 -c "
import json
p='$STATE_FILE'
try:
  d=json.load(open(p))
  changed=False
  for k in ('reads_this_turn','cumulative_reads'):
    v=d.get(k,0)
    if isinstance(v,list):
      d[k]=len(v)
      changed=True
  if changed:
    json.dump(d,open(p,'w'),indent=2)
except Exception as e:
  print(f'[state] WARN: no pude migrar campos legacy: {e}',file=__import__('sys').stderr)
" 2>/dev/null || true
}

# =============================================================================
# JSON helpers (sin jq para máxima portabilidad)
# =============================================================================
state_get() {
  local key="$1"
  python3 -c "
import json
v=json.load(open('$STATE_FILE')).get('$key','')
if v is None: print('')
elif v is True: print('true')
elif v is False: print('false')
elif isinstance(v, list): print(len(v))   # list -> count (para reads_this_turn etc.)
elif isinstance(v, dict): print(len(v))
else: print(v)
"
}

state_set() {
  local key="$1"
  local value="$2"
  # Convert shell true/false to Python True/False
  case "$value" in
    true)  value="True"  ;;
    false) value="False" ;;
  esac
  python3 -c "
import json
p='$STATE_FILE'
d=json.load(open(p))
d['$key']=$value
json.dump(d,open(p,'w'),indent=2)
"
}

state_append() {
  local key="$1"
  local value="$2"
  python3 -c "
import json
p='$STATE_FILE'
d=json.load(open(p))
d.setdefault('$key',[]).append($value)
json.dump(d,open(p,'w'),indent=2)
"
}

# =============================================================================
# Turn management
# =============================================================================
state_new_turn() {
  state_init
  local turn=$(state_get turn)
  turn=$((turn + 1))
  state_set turn "$turn"
  state_set reads_this_turn 0
  state_set drill_done_this_turn false
  state_set srsi_done_this_turn false
  echo "[state] turn=$turn reads=0"
}

state_record_read() {
  local reads=$(state_get reads_this_turn)
  reads=$((reads + 1))
  state_set reads_this_turn "$reads"
  local cumul=$(state_get cumulative_reads)
  cumul=$((cumul + 1))
  state_set cumulative_reads "$cumul"
}

# =============================================================================
# Loop management
# =============================================================================
state_set_current_loop() {
  local loop_id="$1"
  local budget="$2"
  state_set current_loop_id "\"$loop_id\""
  state_set current_loop_budget "$budget"
  state_set current_loop_iter 0
}

state_record_loop_iter() {
  local iter=$(state_get current_loop_iter)
  iter=$((iter + 1))
  state_set current_loop_iter "$iter"
}

# =============================================================================
# Strikes & violations
# =============================================================================
state_record_strike() {
  local rule="$1"
  local detail="${2:-}"
  local strikes=$(state_get r_aa_1_strikes)
  strikes=$((strikes + 1))
  state_set r_aa_1_strikes "$strikes"
  state_append aa1_violations "{\"rule\":\"$rule\",\"detail\":\"$detail\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  echo "[state] strike #$strikes rule=$rule detail=$detail"
  if [[ $strikes -ge 3 ]]; then
    echo "[state] R-3STRIKE-MVP triggered — cambiar método"
    local act=$(state_get r_3strike_mvp_activations)
    act=$((act + 1))
    state_set r_3strike_mvp_activations "$act"
  fi
}

state_record_srsi_violation() {
  state_record_strike "srsi_missing" "SRSI no ejecutado antes de fix"
}

# =============================================================================
# Swarm spawn tracking — bumpeo §28.7 (R-FAKE-COORDINATOR detector)
# =============================================================================
# Registra que el coordinator spawneó un swarm worker/arquitecto.
# Llamado desde posttool.sh cuando detecta uso de la tool swarm.
state_record_swarm_spawn() {
  local role="$1"
  local prompt_size="${2:-0}"
  local turn=$(state_get turn)
  state_set last_swarm_spawn_turn "$turn"
  state_set last_swarm_role "\"$role\""
  state_set last_swarm_prompt_size "$prompt_size"
  local count=$(state_get swarm_spawn_count_session)
  count=$((count + 1))
  state_set swarm_spawn_count_session "$count"
}

state_swarm_recent_within_turns() {
  local max_turns="${1:-30}"
  local last_turn=$(state_get last_swarm_spawn_turn)
  local cur_turn=$(state_get turn)
  if [[ -z "$last_turn" ]] || [[ "$last_turn" == "0" ]]; then
    return 1
  fi
  local diff=$((cur_turn - last_turn))
  if [[ $diff -ge 0 ]] && [[ $diff -le $max_turns ]]; then
    return 0
  fi
  return 1
}

# =============================================================================
# Compliance score — BUG FIXED: ahora suma 100
# =============================================================================
# Pesos (deben sumar 100):
#   reads   : 15  (15+ si reads_this_turn >= 3)
#   cumul   : 15  (15+ si cumulative_reads > 0)
#   drill   : 15  (15 si drill_done_this_turn)
#   srsi    : 15  (15 si srsi_done_this_turn)
#   ddlp    : 10  (10 si ddlp_done)
#   r3s     : 10  (10 si r_aa_1_strikes == 0; -5 por strike; -10 si 3+)
#   handoff : 10  (10 si handoff_written)
#   clean   : 10  (10 si aa1_violations está vacío)
# Total máximo = 100
# =============================================================================
state_compliance_score() {
  state_init
  python3 <<'PY'
import json
d = json.load(open('.jcode/state/compliance.json'))

def w(cond, val):
    return val if cond else 0

def num(v, default=0):
    """Sanitiza un valor a número (puede venir como list, str, None, etc.)"""
    if isinstance(v, (int, float)):
        return v
    if isinstance(v, list):
        return len(v) if v else default
    if isinstance(v, str):
        try:
            return int(v) if v else default
        except ValueError:
            return default
    return default

def bool_(v):
    if isinstance(v, bool):
        return v
    if isinstance(v, str):
        return v.lower() in ('true', '1', 'yes')
    if isinstance(v, (int, float)):
        return v != 0
    return False

reads   = w(num(d.get('reads_this_turn', 0)) >= 3, 15)
cumul   = w(num(d.get('cumulative_reads', 0)) > 0, 15)
drill   = w(bool_(d.get('drill_done_this_turn', False)), 15)
srsi    = w(bool_(d.get('srsi_done_this_turn', False)), 15)
ddlp    = w(bool_(d.get('ddlp_done', False)), 10)

strikes = num(d.get('r_aa_1_strikes', 0))
if strikes == 0:
    r3s = 10
elif strikes < 3:
    r3s = 5
else:
    r3s = 0

handoff = w(bool_(d.get('handoff_written', False)), 10)
viol = d.get('aa1_violations', [])
viol_count = len(viol) if isinstance(viol, list) else 0
clean   = w(viol_count == 0, 10)

total = reads + cumul + drill + srsi + ddlp + r3s + handoff + clean
print(total)
PY
}

state_compliance_breakdown() {
  state_init
  python3 <<'PY'
import json
d = json.load(open('.jcode/state/compliance.json'))

def w(cond, val):
    return val if cond else 0

def num(v, default=0):
    if isinstance(v, (int, float)):
        return v
    if isinstance(v, list):
        return len(v) if v else default
    if isinstance(v, str):
        try:
            return int(v) if v else default
        except ValueError:
            return default
    return default

def bool_(v):
    if isinstance(v, bool):
        return v
    if isinstance(v, str):
        return v.lower() in ('true', '1', 'yes')
    if isinstance(v, (int, float)):
        return v != 0
    return False

reads_n = num(d.get('reads_this_turn', 0))
cumul_n = num(d.get('cumulative_reads', 0))
strikes = num(d.get('r_aa_1_strikes', 0))
viol = d.get('aa1_violations', [])
viol_count = len(viol) if isinstance(viol, list) else 0

reads   = w(reads_n >= 3, 15)
cumul   = w(cumul_n > 0, 15)
drill   = w(bool_(d.get('drill_done_this_turn', False)), 15)
srsi    = w(bool_(d.get('srsi_done_this_turn', False)), 15)
ddlp    = w(bool_(d.get('ddlp_done', False)), 10)
r3s     = 10 if strikes == 0 else (5 if strikes < 3 else 0)
handoff = w(bool_(d.get('handoff_written', False)), 10)
clean   = w(viol_count == 0, 10)

total = reads + cumul + drill + srsi + ddlp + r3s + handoff + clean
print(f"reads   : {reads}/15  (raw={reads_n})")
print(f"cumul   : {cumul}/15  (raw={cumul_n})")
print(f"drill   : {drill}/15")
print(f"srsi    : {srsi}/15")
print(f"ddlp    : {ddlp}/10")
print(f"r3s     : {r3s}/10  (strikes={strikes})")
print(f"handoff : {handoff}/10")
print(f"clean   : {clean}/10  (violations={viol_count})")
print(f"--------")
print(f"TOTAL   : {total}/100")
PY
}

# =============================================================================
# Closeout
# =============================================================================
state_closeout() {
  state_init
  local score=$(state_compliance_score)
  if [[ $score -ge 80 ]]; then
    state_set closeout_passed true
    echo "[state] closeout PASSED score=$score"
    return 0
  else
    state_set closeout_passed false
    echo "[state] closeout FAILED score=$score (need >=80)"
    return 1
  fi
}

# =============================================================================
# CLI dispatch — solo cuando se invoca directamente (no cuando se sourcea)
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-help}" in
    init)        state_init ;;
    new-turn)    state_new_turn ;;
    record-read) state_record_read ;;
    set-loop)    state_set_current_loop "$2" "$3" ;;
    loop-iter)   state_record_loop_iter ;;
    strike)      state_record_strike "$2" "$3" ;;
    srsi-viol)   state_record_srsi_violation ;;
    score)       state_compliance_score ;;
    breakdown)   state_compliance_breakdown ;;
    closeout)    state_closeout ;;
    get)         state_get "$2" ;;
    set)         state_set "$2" "$3" ;;
    help|*)
      cat <<'EOF'
state_manager.sh — Compliance state

Usage:
  state_manager.sh init                  Init compliance.json
  state_manager.sh new-turn              Bumpear turno
  state_manager.sh record-read           +1 read
  state_manager.sh set-loop ID BUDGET    Set loop actual
  state_manager.sh loop-iter             +1 iteración loop
  state_manager.sh strike RULE [DETAIL]  Bumpear strike
  state_manager.sh srsi-viol             Strike por SRSI missing
  state_manager.sh score                 Imprime score (0-100)
  state_manager.sh breakdown             Detalle por componente
  state_manager.sh closeout              Validar closeout (>=80 = pass)
  state_manager.sh get KEY               Leer campo
  state_manager.sh set KEY VALUE         Setear campo
EOF
      ;;
  esac
fi
