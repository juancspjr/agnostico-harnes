#!/usr/bin/env bash
# =============================================================================
# .jcode/lib/config_reader.sh — Lector de TOML agnóstico
# =============================================================================
# Helper que permite a hooks y scripts leer arrays y scalars desde config.toml
# sin depender de un parser TOML externo (usa python3 inline).
# =============================================================================

set -uo pipefail

CONFIG_FILE="${JCODE_CONFIG:-.jcode/config.toml}"
JCODE_DIR="${JCODE_DIR:-$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")")}"

# -----------------------------------------------------------------------------
# _config_parse_python <key_path>
#   Helper privado: parsea TOML con python3 y emite "key=value" lines.
#   key_path: ej "section.field" → retorna líneas con items del array
# -----------------------------------------------------------------------------
_config_parse_python() {
  local key_path="$1"
  python3 "$JCODE_DIR/lib/_config_parse.py" "$CONFIG_FILE" "$key_path" 2>/dev/null
}

# -----------------------------------------------------------------------------
# config_get_array <section.field>
#   Output: un elemento por línea (sin corchetes, comillas ni comas)
# -----------------------------------------------------------------------------
config_get_array() {
  _config_parse_python "$1"
}

# -----------------------------------------------------------------------------
# config_get_string <section.field> [default]
#   Output: el valor escalar (string sin comillas)
# -----------------------------------------------------------------------------
config_get_string() {
  local key="$1"
  local default="${2:-}"
  local val
  val=$(python3 "$JCODE_DIR/lib/_config_parse.py" "$CONFIG_FILE" "$key" 2>/dev/null | head -1)
  if [[ -z "$val" ]]; then
    echo "$default"
  else
    echo "$val"
  fi
}