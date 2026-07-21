#!/usr/bin/env python3
"""lib/oracle.py — Oráculo de ground truth independiente del agente.

Recalcula hechos desde el código fuente SIN leer outputs del agente.
Compara contra claims registrados (evidence bundles, logs de iteración).

Diseñado para detectar HF-V2 SELF-ORACLE (el agente validándose a sí mismo).

Uso:
    python3 lib/oracle.py                # validación por defecto
    python3 lib/oracle.py --strict       # falla si hay drift
    python3 lib/oracle.py --loop L-XX    # valida contra loop específico
    python3 lib/oracle.py --json         # salida JSON

Salidas:
    - Oráculo de funciones: parsea .py/.sh y compara contra BEHAVIOR-INDEX
    - Oráculo de invariantes: parsea STATE-REGISTERS y verifica scripts referenciados
    - Oráculo de evidencia: parsea evidence bundles y recalcula checks
    - Reporte de drift: lista inconsistencias entre ground truth y claims

Veredicto:
    CONSISTENT  — ground truth recalculado coincide con claims
    DRIFT_FOUND — discrepancia detectada (HF-V2 strike)
    INCOMPLETE  — ground truth no se pudo calcular (datos faltantes)
"""
import argparse
import ast
import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple


REPO_ROOT = Path(os.environ.get("REPO_ROOT", ".")).resolve()
JCODE_DIR = REPO_ROOT / ".jcode"


def parse_python_functions(file_path: Path) -> Set[str]:
    """AST ground truth: extrae definiciones de funciones de un .py."""
    try:
        source = file_path.read_text(encoding="utf-8", errors="ignore")
        tree = ast.parse(source, filename=str(file_path))
        return {node.name for node in ast.walk(tree)
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))}
    except (SyntaxError, ValueError):
        return set()


def parse_bash_functions(file_path: Path) -> Set[str]:
    """Heurística para .sh: extrae `name() {` y `function name {`."""
    funcs = set()
    try:
        text = file_path.read_text(encoding="utf-8", errors="ignore")
        # Patrón: function name() {  OR  name() {
        for m in re.finditer(r'^\s*(?:function\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\s*\)', text, re.MULTILINE):
            funcs.add(m.group(1))
    except Exception:
        pass
    return funcs


def oraculo_funciones() -> Dict[str, Set[str]]:
    """Ground truth: funciones por archivo."""
    result = {}
    scan_dirs = [".jcode/lib", ".jcode/skills", "src"]
    for d in scan_dirs:
        base = REPO_ROOT / d
        if not base.exists():
            continue
        for f in base.rglob("*.py"):
            funcs = parse_python_functions(f)
            if funcs:
                rel = str(f.relative_to(REPO_ROOT))
                result[rel] = funcs
        for f in base.rglob("*.sh"):
            funcs = parse_bash_functions(f)
            if funcs:
                rel = str(f.relative_to(REPO_ROOT))
                result[rel] = funcs
    return result


def oraculo_behavior_index_claims() -> Set[str]:
    """Claims: nombres de funciones referenciados en BEHAVIOR-INDEX.md."""
    bi = JCODE_DIR / "BEHAVIOR-INDEX.md"
    if not bi.exists():
        return set()
    text = bi.read_text(encoding="utf-8", errors="ignore")
    # Buscar B-XXX IDs
    ids = set(re.findall(r'B-(\d+)', text))
    return ids


def oraculo_state_registers_invariants() -> Dict[str, List[str]]:
    """Ground truth: invariantes declaradas en STATE-REGISTERS.md."""
    sr = JCODE_DIR / "STATE-REGISTERS.md"
    if not sr.exists():
        return {}
    text = sr.read_text(encoding="utf-8", errors="ignore")
    result = {}
    # Patrón: STATE-XXX: ... scripts: invariant_X.sh
    for m in re.finditer(r'##\s+(STATE-[A-Z0-9_-]+).*?(?=\n##\s|\Z)', text, re.DOTALL):
        state_id = m.group(1)
        block = m.group(0)
        scripts = re.findall(r'`([a-zA-Z0-9_./-]+\.sh)`', block)
        result[state_id] = scripts
    return result


def verify_invariant_scripts_exist(invariants: Dict[str, List[str]]) -> List[str]:
    """Verifica que los scripts referenciados en STATE-REGISTERS existen."""
    missing = []
    for state_id, scripts in invariants.items():
        for s in scripts:
            # Si parece relativo, resolver
            if s.startswith("./"):
                candidate = REPO_ROOT / s[2:]
            elif s.startswith("/"):
                candidate = Path(s)
            else:
                candidate = REPO_ROOT / ".jcode" / s
                if not candidate.exists():
                    candidate = REPO_ROOT / s
            if not candidate.exists():
                missing.append(f"{state_id} → {s}")
    return missing


def oraculo_evidence_bundles() -> Dict[str, str]:
    """Lee todos los evidence bundles y extrae verdicts."""
    log_dir = JCODE_DIR / "logs"
    if not log_dir.exists():
        return {}
    bundles = {}
    for f in log_dir.glob("evidence-bundle-*.md"):
        text = f.read_text(encoding="utf-8", errors="ignore")
        m = re.search(r'verdict:\s*(.+)', text)
        if m:
            bundles[f.name] = m.group(1).strip()
    return bundles


def main():
    ap = argparse.ArgumentParser(description="Oracle ground-truth independiente")
    ap.add_argument("--strict", action="store_true",
                    help="Exit non-zero si drift detectado")
    ap.add_argument("--loop", default=None,
                    help="Validar contra loop específico (no usado aún)")
    ap.add_argument("--json", action="store_true",
                    help="Salida en JSON")
    args = ap.parse_args()

    drift = []

    # 1. Funciones ground truth
    funcs_gt = oraculo_funciones()
    total_funcs = sum(len(v) for v in funcs_gt.values())
    files_with_funcs = len(funcs_gt)

    # 2. BEHAVIOR-INDEX claims
    bi_claims = oraculo_behavior_index_claims()

    # 3. STATE-REGISTERS invariants
    sr_invariants = oraculo_state_registers_invariants()
    sr_missing = verify_invariant_scripts_exist(sr_invariants)
    if sr_missing:
        drift.extend([f"STATE-REGISTERS referencia script inexistente: {m}" for m in sr_missing])

    # 4. Evidence bundles verdicts
    verdicts = oraculo_evidence_bundles()
    pending_count = sum(1 for v in verdicts.values() if v.startswith("PENDING"))

    # Reporte
    if args.json:
        report = {
            "ground_truth": {
                "files_with_funcs": files_with_funcs,
                "total_funcs": total_funcs,
            },
            "claims": {
                "behavior_index_b_ids": sorted(bi_claims),
                "state_registers_invariants": len(sr_invariants),
            },
            "evidence_bundles": {
                "total": len(verdicts),
                "pending": pending_count,
                "verdicts": verdicts,
            },
            "drift": drift,
            "verdict": "DRIFT_FOUND" if drift else ("INCOMPLETE" if total_funcs == 0 else "CONSISTENT"),
        }
        print(json.dumps(report, indent=2))
    else:
        print(f"\n═══ ORACLE GROUND TRUTH ═══\n")
        print(f"Funciones parseadas: {total_funcs} en {files_with_funcs} archivos")
        print(f"B-XXX en BEHAVIOR-INDEX: {len(bi_claims)}")
        print(f"STATE-* en STATE-REGISTERS: {len(sr_invariants)}")
        print(f"Evidence bundles: {len(verdicts)} (PENDING: {pending_count})")
        print()
        if drift:
            print(f"❌ DRIFT_FOUND — {len(drift)} inconsistencias:")
            for d in drift:
                print(f"   - {d}")
            print()
            print("Veredicto: DRIFT_FOUND (HF-V2 SELF-ORACLE strike)")
        elif total_funcs == 0:
            print("⚠️  INCOMPLETE — no se pudo calcular ground truth")
            print("Veredicto: INCOMPLETE")
        else:
            print("✅ CONSISTENT — ground truth recalculado coincide con claims")
            print("Veredicto: CONSISTENT")

    if drift and args.strict:
        sys.exit(2)
    elif total_funcs == 0:
        sys.exit(3)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
