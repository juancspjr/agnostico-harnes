#!/usr/bin/env python3
"""
config_initializer.py — Auto-inicialización del proyecto.

Cuando se detecta código nuevo en src/, auto-genera:
- contamination_patterns.txt con el nombre del proyecto
- mcp.json con paths relativos
- Stages desde PDR.md §5 (flujos críticos)
- Task classes desde PRINCIPLES.md

Uso:
  python3 config_initializer.py [--repo PATH] [--dry-run]
  python3 config_initializer.py [--repo PATH] [--force]
"""

import json
import os
import re
import sys
from pathlib import Path


def detect_project_name(repo_root) -> str:
    """Detecta nombre del proyecto desde PDR.md, PROJECT.md o directorio."""
    if isinstance(repo_root, str):
        repo_root = Path(repo_root)
    # Intentar desde PROJECT.md
    pm = repo_root / "PROJECT.md"
    if pm.exists():
        content = pm.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        if m:
            return m.group(1).strip()

    # Desde PDR.md
    pdr = repo_root / "PDR.md"
    if pdr.exists():
        content = pdr.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        if m:
            return m.group(1).strip()

    # Default: nombre del directorio
    return repo_root.name


def init_contamination_patterns(repo_root, project_name: str, dry_run: bool = False) -> dict:
    """Genera contamination_patterns.txt con nombre del proyecto."""
    if isinstance(repo_root, str):
        repo_root = Path(repo_root)
    patterns_path = repo_root / ".jcode" / "lib" / "contamination_patterns.txt"
    if not patterns_path.exists():
        return {"status": "skipped", "reason": "contamination_patterns.txt not found"}

    content = patterns_path.read_text(encoding="utf-8", errors="replace")

    # Buscar si ya tiene contenido real (no solo placeholders)
    lines = [l.strip() for l in content.split("\n") if l.strip() and not l.startswith("#")]
    has_real_patterns = any(l != project_name for l in lines)

    if has_real_patterns and not dry_run:
        return {"status": "skipped", "reason": "already has real patterns"}

    new_content = f"# Patrones de contaminación del proyecto: {project_name}\n"
    new_content += f"# Generado automáticamente por bootstrap-proyecto\n"
    new_content += f"# Cada línea es un patrón (keyword o regex) que NO debe aparecer en .jcode/\n\n"
    new_content += f"{project_name}\n"
    new_content += f"{project_name.lower()}\n"
    new_content += f"{project_name.replace('-', '_')}\n"

    if not dry_run:
        patterns_path.write_text(new_content)
        return {"status": "ok", "patterns_added": 3, "path": str(patterns_path)}
    return {"status": "dry_run", "would_add": 3}


def init_mcp_json(repo_root, dry_run: bool = False) -> dict:
    """Configura mcp.json con paths relativos."""
    if isinstance(repo_root, str):
        repo_root = Path(repo_root)
    mcp_path = repo_root / ".jcode" / "mcp.json"
    if not mcp_path.exists():
        return {"status": "skipped", "reason": "mcp.json not found"}

    try:
        config = json.loads(mcp_path.read_text())
    except json.JSONDecodeError:
        return {"status": "error", "reason": "invalid JSON"}

    # Verificar si ya usa paths relativos
    mcp_servers = config.get("mcpServers", {})
    if not mcp_servers:
        mcp_servers = config.get("mcpServers", {})

    modified = False
    for server_name, server_config in mcp_servers.items():
        if isinstance(server_config, dict):
            # Convertir paths absolutos a relativos
            for key in ["args", "command"]:
                if isinstance(server_config.get(key), list):
                    new_args = []
                    for arg in server_config[key]:
                        if isinstance(arg, str) and arg.startswith("/"):
                            # Intentar hacer relativo
                            try:
                                rel = os.path.relpath(arg, str(repo_root))
                                if rel != arg:
                                    new_args.append(rel)
                                    modified = True
                                else:
                                    new_args.append(arg)
                            except ValueError:
                                new_args.append(arg)
                        else:
                            new_args.append(arg)
                    if modified:
                        server_config[key] = new_args

    if modified and not dry_run:
        mcp_path.write_text(json.dumps(config, indent=2) + "\n")
        return {"status": "ok", "modified": True, "path": str(mcp_path)}

    return {"status": "ok", "modified": modified}


def init_stages_from_pdr(repo_root, dry_run: bool = False) -> dict:
    """Lee PDR.md §5 para generar/actualizar stages."""
    if isinstance(repo_root, str):
        repo_root = Path(repo_root)
    sys.path.insert(0, str(repo_root / ".jcode/skills/bootstrap-proyecto/lib"))
    if dry_run:
        from stage_generator import generate
        skeleton = generate(str(repo_root))
    else:
        from stage_generator import apply as apply_stages
        skeleton = apply_stages(str(repo_root))

    return {
        "status": "ok",
        "stages": len(skeleton["stages"]),
        "source": skeleton["source"],
        "adaptable": skeleton.get("_adaptable", False),
    }


def init_all(repo_root: str = ".", dry_run: bool = False) -> dict:
    """Ejecuta todas las inicializaciones."""
    root = Path(repo_root).resolve()
    project_name = detect_project_name(root)

    results = {}

    results["contamination"] = init_contamination_patterns(root, project_name, dry_run)
    results["mcp_json"] = init_mcp_json(root, dry_run)
    results["stages"] = init_stages_from_pdr(root, dry_run)

    return {
        "project_name": project_name,
        "dry_run": dry_run,
        "results": results,
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Config Initializer — auto-inicialización del proyecto")
    parser.add_argument("--repo", default=".", help="Repo root path")
    parser.add_argument("--dry-run", action="store_true", help="Simulate only")
    parser.add_argument("--force", action="store_true", help="Force overwrite")
    args = parser.parse_args()

    result = init_all(args.repo, args.dry_run)

    print(f"=== Config Initializer: {result['project_name']} ===")
    for name, res in result["results"].items():
        status = "✅" if res["status"] == "ok" else "⏭️" if "skip" in res["status"] else "❌"
        print(f"  {status} {name}: {res.get('reason', res['status'])}")

    if args.dry_run:
        print("\n[DRY RUN] No se realizaron cambios.")

    print(json.dumps(result, indent=2))
    return result


if __name__ == "__main__":
    main()
