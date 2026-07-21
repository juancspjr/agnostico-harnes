#!/usr/bin/env bash
# =============================================================================
# .jcode/lib/clean-contamination.sh — Limpieza MANUAL de contaminación
# =============================================================================
#
# USO:
#   bash .jcode/lib/clean-contamination.sh <comando> [opciones]
#
# COMANDOS:
#
#   scan                Lista TODA la contaminación (arnés + proyecto)
#                       Sin tocar nada. Solo reporta.
#
#   scan-harness        Lista solo contaminación en archivos del ARNÉS
#                       (excluye tests/state/iterations/scratch/logs)
#                       Sin tocar nada.
#
#   scan-project        Lista solo contaminación en archivos del PROYECTO
#                       (tests/state/iterations/scratch/logs/etc.)
#                       Sin tocar nada.
#
#   list-files          Lista archivos que contienen contaminación (sin detalle)
#                       Útil para pipear a xargs.
#
#   move-to-project     Mueve archivos del arnés contaminados a
#                       .jcode/iterations/archive/contaminated/<fecha>/
#                       NO los borra, los archiva.
#
#   archive-and-reset   Archiva TODO .jcode/ + copia arnés limpio del zip
#                       (necesita --zip <path>)
#                       Recomendado para migración completa.
#
#   reset-state         Borra .jcode/state/ y .jcode/logs/ (recrea vacíos)
#                       Útil si el runtime state está corrupto.
#
#   help                Esta ayuda
#
# OPCIONES:
#   --pattern <patrón>  Solo procesar un patrón específico
#   --zip <path>        Path al zip del arnés limpio (para archive-and-reset)
#   --yes               No pedir confirmación
#   --dry-run           Mostrar qué haría sin tocar nada
#
# EJEMPLOS:
#
#   # 1. Ver toda la contaminación (sin tocar nada)
#   bash .jcode/lib/clean-contamination.sh scan
#
#   # 2. Ver solo contaminación del arnés (lo que importa realmente)
#   bash .jcode/lib/clean-contamination.sh scan-harness
#
#   # 3. Ver solo contaminación del proyecto (tests, etc.)
#   bash .jcode/lib/clean-contamination.sh scan-project
#
#   # 4. Mover archivos contaminados del arnés a archive (NO borrar)
#   bash .jcode/lib/clean-contamination.sh move-to-project
#
#   # 5. Resetear state runtime corrupto
#   bash .jcode/lib/clean-contamination.sh reset-state
#
#   # 6. Migración completa: archivar + copiar arnés limpio del zip
#   bash .jcode/lib/clean-contamination.sh archive-and-reset --zip jcode-harness-clean.zip
#
# =============================================================================
# FILOSOFÍA:
#   - El usuario SIEMPRE decide qué borrar. El script NO borra nada sin --yes.
#   - move-to-project ARCHIVA, no borra.
#   - reset-state solo toca state/ y logs/, nunca código.
#   - archive-and-reset hace backup completo antes de tocar nada.
# =============================================================================

set -uo pipefail

# =============================================================================
# Setup
# =============================================================================
REPO_ROOT="${REPO_ROOT:-$PWD}"
JCODE_DIR="$REPO_ROOT/.jcode"
PATTERNS_FILE="$JCODE_DIR/lib/contamination_patterns.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_section() { echo -e "\n${CYAN}=== $* ===${NC}"; }

# Paths del PROYECTO (no se auditan como contaminación del arnés)
PROJECT_PATHS=(
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
)

# =============================================================================
# Helpers
# =============================================================================
build_exclude_args() {
  local args=()
  for p in "${PROJECT_PATHS[@]}"; do
    args+=( --glob "!$p" )
  done
  args+=( --glob "!contamination_patterns.txt" )
  args+=( --glob "!clean-contamination.sh" )
  # Los globs relativos solo funcionan si cwd está dentro del dir
  echo "${args[@]}"
}

# Ejecuta rg DENTRO del JCODE_DIR para que los --glob relativos funcionen
rg_in_jcode() {
  local pattern="$1"
  shift
  (cd "$JCODE_DIR" && rg -l -i --no-messages "$@" "$pattern" . 2>/dev/null || true)
}

build_project_only_args() {
  # Para scan-project, solo buscar DENTRO de los paths del proyecto
  # Retornamos los paths como argumentos posicionales (no globs)
  local args=()
  for p in "${PROJECT_PATHS[@]}"; do
    # Quitar el /** final para tener el path base
    local base="${p%/\*\*}"
    if [[ -d "$JCODE_DIR/$base" ]]; then
      args+=( "$JCODE_DIR/$base" )
    fi
  done
  # Si solo hay paths de archivo, agregarlos
  for p in "${PROJECT_PATHS[@]}"; do
    if [[ "$p" != *"/\*\*"* ]] && [[ "$p" != *"\*\*"* ]]; then
      if [[ -f "$JCODE_DIR/$p" ]]; then
        args+=( "$JCODE_DIR/$p" )
      fi
    fi
  done
  echo "${args[@]}"
}

read_patterns() {
  if [[ ! -f "$PATTERNS_FILE" ]]; then
    log_error "patterns file no encontrado: $PATTERNS_FILE"
    return 1
  fi
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    echo "$line"
  done < "$PATTERNS_FILE"
}

# =============================================================================
# scan — toda la contaminación
# =============================================================================
cmd_scan() {
  log_section "SCAN COMPLETO — toda la contaminación en .jcode/"
  local total=0
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    local files=$(rg_in_jcode "$pattern")
    local count=0
    if [[ -n "$files" ]]; then
      count=$(echo "$files" | grep -c . || echo 0)
    fi
    if [[ "$count" -gt 0 ]]; then
      echo -e "  ${RED}❌${NC} '$pattern' en $count archivo(s)"
      total=$((total + count))
    fi
  done < <(read_patterns)
  echo ""
  if [[ $total -eq 0 ]]; then
    log_ok "0 contaminación total"
  else
    log_warn "$total archivo(s) con contaminación (arnés + proyecto)"
    echo ""
    echo "Para ver solo arnés:     bash $0 scan-harness"
    echo "Para ver solo proyecto:  bash $0 scan-project"
  fi
}

# =============================================================================
# scan-harness — solo arnés (excluye proyecto)
# =============================================================================
cmd_scan_harness() {
  log_section "SCAN ARNÉS — excluye tests/state/iterations/scratch/logs"
  local exclude_args=$(build_exclude_args)
  local total=0
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    local files=$(rg_in_jcode "$pattern" $exclude_args)
    local count=0
    if [[ -n "$files" ]]; then
      count=$(echo "$files" | grep -c . || echo 0)
    fi
    if [[ "$count" -gt 0 ]]; then
      echo -e "  ${RED}❌${NC} '$pattern' en $count archivo(s) del arnés:"
      echo "$files" | head -5 | sed "s|^\./|      $JCODE_DIR/|"
      total=$((total + count))
    fi
  done < <(read_patterns)
  echo ""
  if [[ $total -eq 0 ]]; then
    log_ok "✅ 0 contaminación en archivos del arnés"
  else
    log_warn "$total archivo(s) del arnés con contaminación"
    echo ""
    echo "Para moverlos a archive (NO borrar):  bash $0 move-to-project"
  fi
}

# =============================================================================
# scan-project — solo proyecto
# =============================================================================
cmd_scan_project() {
  log_section "SCAN PROYECTO — solo tests/state/iterations/scratch/logs"

  # Construir lista de paths del proyecto que existen
  local project_paths=()
  for p in "${PROJECT_PATHS[@]}"; do
    local base="${p%/\*\*}"
    if [[ -d "$JCODE_DIR/$base" ]]; then
      project_paths+=( "$base" )
    elif [[ -f "$JCODE_DIR/$base" ]]; then
      project_paths+=( "$base" )
    fi
  done

  if [[ ${#project_paths[@]} -eq 0 ]]; then
    log_info "No se encontraron paths del proyecto para escanear"
    return
  fi

  local total=0
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    # Buscar DENTRO de los paths del proyecto (sin excludes)
    local files=""
    for pp in "${project_paths[@]}"; do
      local found=$(cd "$JCODE_DIR" && rg -l -i --no-messages -e "$pattern" "./$pp" 2>/dev/null || true)
      if [[ -n "$found" ]]; then
        files="${files}${found}"$'\n'
      fi
    done
    local count=0
    if [[ -n "$files" ]]; then
      count=$(echo "$files" | grep -c . || echo 0)
    fi
    if [[ "$count" -gt 0 ]]; then
      echo -e "  ${YELLOW}ℹ️${NC}  '$pattern' en $count archivo(s) del proyecto (esperado)"
      total=$((total + count))
    fi
  done < <(read_patterns)
  echo ""
  if [[ $total -eq 0 ]]; then
    log_ok "0 contaminación en archivos del proyecto"
  else
    log_info "$total archivo(s) del proyecto contienen strings del dominio"
    log_info "Esto es ESPERADO — los tests/state/iterations SABEN del proyecto"
    log_info "El arnés no los audita. No necesitas limpiarlos."
  fi
}

# =============================================================================
# list-files — solo lista, para pipear
# =============================================================================
cmd_list_files() {
  local exclude_args=$(build_exclude_args)
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    rg_in_jcode "$pattern" $exclude_args
  done < <(read_patterns) | sed "s|^\./|$JCODE_DIR/|" | sort -u
}

# =============================================================================
# move-to-project — archiva archivos contaminados del arnés
# =============================================================================
cmd_move_to_project() {
  local dry_run="${DRY_RUN:-false}"
  local ask="${ASK:-true}"

  log_section "MOVER archivos contaminados del arnés a archive"

  if [[ "$ask" == "true" ]] && [[ "$dry_run" == "false" ]]; then
    echo "Esto moverá archivos del arnés con contaminación a:"
    echo "  .jcode/iterations/archive/contaminated/$(date +%Y-%m-%d)/"
    echo ""
    echo "NO se borrarán. Se archivan para referencia."
    echo ""
    read -p "¿Continuar? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY] ]]; then
      log_info "Cancelado."
      exit 0
    fi
  fi

  local archive_dir="$JCODE_DIR/iterations/archive/contaminated/$(date +%Y-%m-%d)"
  if [[ "$dry_run" == "false" ]]; then
    mkdir -p "$archive_dir"
  fi

  local exclude_args=$(build_exclude_args)
  local moved=0
  declare -A seen

  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    local files=$(rg_in_jcode "$pattern" $exclude_args)
    if [[ -z "$files" ]]; then continue; fi
    while IFS= read -r f_rel; do
      # f_rel viene con prefijo "./"
      local f="$JCODE_DIR/${f_rel#./}"
      # Skip duplicates
      [[ -n "${seen[$f]:-}" ]] && continue
      seen[$f]=1
      # Relative path
      local rel="${f#$JCODE_DIR/}"
      local dest="$archive_dir/$rel"
      if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${CYAN}[DRY]${NC} MOVER: $rel → iterations/archive/contaminated/$(date +%Y-%m-%d)/$rel"
      else
        mkdir -p "$(dirname "$dest")"
        mv "$f" "$dest"
        echo -e "  ${GREEN}✓${NC} MOVIDO: $rel → archive"
      fi
      moved=$((moved + 1))
    done <<< "$files"
  done < <(read_patterns)

  echo ""
  if [[ $moved -eq 0 ]]; then
    log_ok "0 archivos para mover. Arnés limpio."
  else
    log_ok "$moved archivo(s) movidos a $archive_dir"
    echo ""
    echo "Para restaurar alguno:"
    echo "  mv $archive_dir/<archivo> .jcode/<ruta-original>"
  fi
}

# =============================================================================
# reset-state — borra state y logs corruptos
# =============================================================================
cmd_reset_state() {
  local dry_run="${DRY_RUN:-false}"
  local ask="${ASK:-true}"

  log_section "RESET state runtime y logs"

  if [[ "$ask" == "true" ]] && [[ "$dry_run" == "false" ]]; then
    echo "Esto eliminará:"
    echo "  .jcode/state/compliance.json (estado runtime)"
    echo "  .jcode/state/*.json (otros estados)"
    echo "  .jcode/logs/*.log (todos los logs)"
    echo ""
    echo "Se recrearán vacíos al siguiente init."
    echo ""
    read -p "¿Continuar? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY] ]]; then
      log_info "Cancelado."
      exit 0
    fi
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo -e "  ${CYAN}[DRY]${NC} BORRAR: .jcode/state/*.json"
    echo -e "  ${CYAN}[DRY]${NC} BORRAR: .jcode/logs/*.log"
    return
  fi

  # Backup first
  local backup="$JCODE_DIR/state.backup.$(date +%s)"
  if [[ -d "$JCODE_DIR/state" ]]; then
    cp -r "$JCODE_DIR/state" "$backup"
    log_info "Backup en $backup"
  fi

  rm -rf "$JCODE_DIR/state" "$JCODE_DIR/logs"
  mkdir -p "$JCODE_DIR/state" "$JCODE_DIR/logs"

  # Reinit
  if [[ -f "$JCODE_DIR/lib/state_manager.sh" ]]; then
    source "$JCODE_DIR/lib/state_manager.sh"
    state_init
  fi

  log_ok "state/ y logs/ reseteados"
}

# =============================================================================
# archive-and-reset — migración completa
# =============================================================================
cmd_archive_and_reset() {
  local zip_path="${ZIP_PATH:-}"
  local dry_run="${DRY_RUN:-false}"
  local ask="${ASK:-true}"

  if [[ -z "$zip_path" ]]; then
    log_error "Falta --zip <path>"
    exit 1
  fi

  if [[ ! -f "$zip_path" ]]; then
    log_error "Zip no encontrado: $zip_path"
    exit 1
  fi

  log_section "ARCHIVE AND RESET — migración completa"

  if [[ "$ask" == "true" ]] && [[ "$dry_run" == "false" ]]; then
    echo "Esto hará:"
    echo "  1. Backup completo de .jcode/ a .jcode.backup-$(date +%Y-%m-%d)/"
    echo "  2. Borra .jcode/ actual"
    echo "  3. Descomprime zip limpio en .jcode/"
    echo "  4. Restaura iterations/PLAN-VIVO.md, INDEX.md, state/, logs/, tests/, scratch/, docs/ desde backup"
    echo "  5. Verifica con harness.sh check"
    echo ""
    echo "Zip: $zip_path"
    echo ""
    read -p "¿Continuar? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY] ]]; then
      log_info "Cancelado."
      exit 0
    fi
  fi

  local backup="$REPO_ROOT/.jcode.backup-$(date +%Y-%m-%d)"

  if [[ "$dry_run" == "true" ]]; then
    echo -e "  ${CYAN}[DRY]${NC} 1. Backup .jcode/ → $backup"
    echo -e "  ${CYAN}[DRY]${NC} 2. rm -rf .jcode/"
    echo -e "  ${CYAN}[DRY]${NC} 3. unzip $zip_path → .jcode/"
    echo -e "  ${CYAN}[DRY]${NC} 4. Restaurar iterations/, state/, logs/, tests/, scratch/, docs/ desde backup"
    echo -e "  ${CYAN}[DRY]${NC} 5. bash .jcode/lib/harness.sh check"
    return
  fi

  # 1. Backup
  log_info "1. Backup .jcode/ → $backup"
  if [[ -d "$backup" ]]; then
    rm -rf "$backup"
  fi
  cp -r "$JCODE_DIR" "$backup"
  log_ok "Backup completo en $backup"

  # 2. Borrar
  log_info "2. Borrando .jcode/ actual"
  rm -rf "$JCODE_DIR"

  # 3. Descomprimir zip
  log_info "3. Descomprimiendo zip limpio"
  mkdir -p "$JCODE_DIR"
  unzip -q "$zip_path" -d /tmp/harness-extract-$$
  if [[ -d "/tmp/harness-extract-$$/.jcode" ]]; then
    cp -r /tmp/harness-extract-$$/.jcode/* "$JCODE_DIR/"
  else
    # El zip podría tener estructura plana
    cp -r /tmp/harness-extract-$$/* "$JCODE_DIR/" 2>/dev/null || true
  fi
  rm -rf /tmp/harness-extract-$$

  # 4. Restaurar paths del proyecto desde backup
  log_info "4. Restaurando paths del proyecto desde backup"
  for p in iterations tests scratch docs; do
    if [[ -d "$backup/$p" ]]; then
      mkdir -p "$JCODE_DIR/$p"
      cp -rn "$backup/$p/." "$JCODE_DIR/$p/" 2>/dev/null || true
      log_ok "Restaurado: $p/"
    fi
  done
  for p in state logs; do
    # NO restaurar state/ y logs/ — se recrean fresh
    mkdir -p "$JCODE_DIR/$p"
  done

  # 5. Hacer ejecutables
  chmod +x "$JCODE_DIR"/hooks/*.sh 2>/dev/null || true
  chmod +x "$JCODE_DIR"/lib/*.sh 2>/dev/null || true

  # 6. Verificar
  log_info "5. Verificando arnés limpio"
  if [[ -f "$JCODE_DIR/lib/harness.sh" ]]; then
    bash "$JCODE_DIR/lib/harness.sh" init
    echo ""
    bash "$JCODE_DIR/lib/harness.sh" check
  fi

  echo ""
  log_ok "Migración completa"
  echo ""
  echo "Backup en: $backup"
  echo "Para restaurar si algo falla:"
  echo "  rm -rf .jcode && mv $backup .jcode"
}

# =============================================================================
# CLI dispatch
# =============================================================================
CMD="${1:-help}"
shift || true

# Parse options
DRY_RUN=false
ASK=true
ZIP_PATH=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --yes) ASK=false; shift ;;
    --zip) ZIP_PATH="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

case "$CMD" in
  scan)              cmd_scan ;;
  scan-harness)      cmd_scan_harness ;;
  scan-project)      cmd_scan_project ;;
  list-files)        cmd_list_files ;;
  move-to-project)   cmd_move_to_project ;;
  reset-state)       cmd_reset_state ;;
  archive-and-reset) cmd_archive_and_reset ;;
  help|--help|-h)
    head -65 "$0" | tail -63
    ;;
  *)
    echo "Unknown command: $CMD"
    echo "Use: bash $0 help"
    exit 1
    ;;
esac
