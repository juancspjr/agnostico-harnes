#!/usr/bin/env python3
# =============================================================================
# .jcode/lib/handbook_resync.py — Resync automático (paper §3.3.3, Appendix B.4)
# =============================================================================
# Implementa Resync_g(H, R, R', ∆, Γ) en 3 pasos:
#   (1) Version alignment: re-parsea R', construye G', compara con G via ∆
#   (2) Scoped update: si S válido, actualiza solo entries afectadas; si no, full rebuild
#   (3) Conservative handling: freeze entries no revalidables, registrar unmapped
# Paper ref: arXiv:2607.13285v1, Appendix B.4
# =============================================================================

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def git_diff_files(repo_root: Path) -> list:
    """Retorna lista de paths modificados vs HEAD~1."""
    try:
        result = subprocess.run(
            ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"],
            cwd=str(repo_root),
            capture_output=True, text=True, check=True
        )
        return [line.strip() for line in result.stdout.split("\n") if line.strip()]
    except subprocess.CalledProcessError:
        return []


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)


def save_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def version_align(repo_root: Path, handbook_dir: Path) -> dict:
    """Paso 1: Version alignment. Compara program graph actual con K_g cache."""
    pg_path = handbook_dir / "program_graph.json"
    k_g_path = handbook_dir / "K_g.json"

    pg = load_json(pg_path)
    k_g = load_json(k_g_path)

    if not pg or not k_g:
        return {"status": "no_op", "reason": "missing_graph_or_K_g"}

    # Hash actual del program graph
    canonical = json.dumps(pg, sort_keys=True, separators=(",", ":"))
    actual_hash = "sha256:" + hashlib.sha256(canonical.encode()).hexdigest()[:16]

    cached_hash = k_g.get("program_graph_hash", "")
    if actual_hash == cached_hash:
        return {"status": "no_op", "reason": "graph_unchanged"}

    # Detectar cambios en functions
    changed_files = git_diff_files(repo_root)
    return {
        "status": "ok",
        "actual_hash": actual_hash,
        "cached_hash": cached_hash,
        "changed_files": changed_files,
    }


def scoped_update(repo_root: Path, handbook_dir: Path, align_result: dict) -> dict:
    """Paso 2: Scoped update. Rebuild solo las partes afectadas."""
    pg_path = handbook_dir / "program_graph.json"
    pg = load_json(pg_path)

    changed_files = align_result.get("changed_files", [])

    # Filtrar funciones afectadas por archivos cambiados
    affected = []
    for func in pg.get("functions", []):
        if func["file"] in changed_files:
            affected.append(func["qualname"])

    return {
        "affected_functions": affected,
        "files_changed": len(changed_files),
    }


def conservative_handling(handbook_dir: Path, scoped_result: dict) -> dict:
    """Paso 3: Conservative handling. Freeze entries no revalidables."""
    cache_b = load_json(handbook_dir / "cache_B.json")
    frozen_path = handbook_dir / "frozen_entries.json"
    frozen = load_json(frozen_path)

    # Buscar L3 entries huérfanas (sin función correspondiente en program_graph)
    pg = load_json(handbook_dir / "program_graph.json")
    live_qualnames = {f["qualname"] for f in pg.get("functions", [])}

    l3_entries = cache_b.get("l3_entries", {})
    for qn in list(l3_entries.keys()):
        if qn not in live_qualnames and qn not in [f.get("qualname") for f in frozen]:
            # Verificar si es removal (file deleted) o solo no detectada
            file_ref = l3_entries[qn].get("file", "")
            if file_ref and not (Path(handbook_dir).parent / file_ref).exists():
                frozen.append({
                    "qualname": qn,
                    "reason": "function_removed",
                    "frozen_at": "now",
                })
            else:
                # Mantener como live pero marcado
                pass

    # Cap de frozen: si > 20% del total de L3, forzar full rebuild
    total_l3 = max(1, len(l3_entries))
    if len(frozen) > total_l3 * 0.2:
        # Full rebuild: limpiar frozen y regenerar desde Phase III
        return {"status": "full_rebuild_required", "frozen": []}

    save_json(frozen_path, frozen)
    return {"frozen_count": len(frozen)}


def rebuild_full(repo_root: Path, handbook_dir: Path):
    """Full rebuild: ejecuta Phase III."""
    import subprocess
    subprocess.run(
        ["python3", str(repo_root / ".jcode/lib/handbook_phase3.py"),
         "--program-graph", str(handbook_dir / "program_graph.json"),
         "--mapping", str(handbook_dir / "behavioral_mapping.json"),
         "--output", str(handbook_dir)],
        cwd=str(repo_root),
        check=True
    )


def resync(repo_root: str = ".", auto: bool = False) -> dict:
    """Ejecuta el resync completo."""
    root = Path(repo_root).resolve()
    handbook_dir = root / ".jcode" / "handbook"

    if not handbook_dir.exists():
        return {"status": "no_handbook", "reason": "handbook_dir_not_found"}

    # Paso 1: Version alignment
    align = version_align(root, handbook_dir)
    if align.get("status") == "no_op":
        return align

    # Paso 2: Scoped update
    scoped = scoped_update(root, handbook_dir, align)

    # Paso 3: Conservative handling
    handling = conservative_handling(handbook_dir, scoped)

    if handling.get("status") == "full_rebuild_required":
        rebuild_full(root, handbook_dir)
        return {"status": "ok", "action": "full_rebuild", "frozen_after": []}

    return {
        "status": "ok",
        "files_changed": scoped.get("files_changed", 0),
        "affected_functions": scoped.get("affected_functions", []),
        "frozen_count": handling.get("frozen_count", 0),
    }


def main():
    parser = argparse.ArgumentParser(description="Handbook Resync (paper Appendix B.4)")
    parser.add_argument("--repo", default=".", help="Repo root path")
    parser.add_argument("--auto", action="store_true",
                        help="Auto mode (called from turnend.sh)")
    args = parser.parse_args()

    result = resync(args.repo, args.auto)
    print(json.dumps(result, indent=2))
    return 0 if result.get("status") in ("ok", "no_op") else 1


if __name__ == "__main__":
    sys.exit(main())