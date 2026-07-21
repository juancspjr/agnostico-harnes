#!/usr/bin/env python3
"""
bootstrap_all.py — Orquestador completo de bootstrap-proyecto.

Ejecuta scanner, stage_generator, language_adapter y config_initializer
en secuencia. Reporta diagnóstico completo.

Uso:
  python3 bootstrap_all.py [--repo PATH] [--apply] [--json]
"""

import json
import sys
from pathlib import Path


def run_all(repo_root: str = ".", apply: bool = False) -> dict:
    """Ejecuta todos los módulos de bootstrap-proyecto."""
    root = Path(repo_root).resolve()
    lib_dir = root / ".jcode/skills/bootstrap-proyecto/lib"
    sys.path.insert(0, str(lib_dir))

    results = {}

    # 1. Scanner
    from project_scanner import scan
    results["scanner"] = scan(repo_root)

    # 2. Stage generator
    from stage_generator import generate, apply as apply_stages
    results["stages"] = generate(repo_root)
    if apply:
        apply_stages(repo_root)
        results["stages"]["_applied"] = True

    # 3. Language adapter
    from language_adapter import detect as detect_language, generate_adapter_skeleton
    results["language"] = detect_language(repo_root)
    if not results["language"]["has_adapter"] and results["scanner"]["languages"]:
        lang = results["scanner"]["languages"][0]
        skeleton = generate_adapter_skeleton(lang)
        if skeleton:
            target = root / ".jcode/skills/bootstrap-proyecto/adapters" / f"{lang}_adapter.py"
            # We don't auto-create since these need manual implementation
            results["language"]["_skeleton_available"] = True
            results["language"]["_skeleton_path"] = str(target)

    # 4. Config initializer
    from config_initializer import init_all
    results["config"] = init_all(repo_root, dry_run=not apply)

    return results


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Bootstrap All — orquestador completo")
    parser.add_argument("--repo", default=".", help="Repo root path")
    parser.add_argument("--apply", action="store_true", help="Apply changes (not dry-run)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    results = run_all(args.repo, args.apply)

    if args.json:
        print(json.dumps(results, indent=2, default=str))
    else:
        s = results["scanner"]
        st = results["stages"]
        l = results["language"]
        c = results["config"]

        print("=" * 60)
        print(f"BOOTSTRAP-PROYECTO — Diagnóstico completo")
        print(f"Proyecto: {s['project_name']}")
        print("=" * 60)
        print(f"\n📋 Estado: {s['state']} | Lenguaje: {s['languages'] or 'N/A'} | Dominio: {s['domains'] or 'N/A'}")
        print(f"📁 Archivos src: {s['src_file_count']} | Flujos críticos: {len(s['critical_flows'])}")
        print(f"\n🎯 Stages ({len(st['stages'])}): {'adaptables' if st.get('_adaptable') else 'del proyecto'}")
        for stg in st['stages']:
            print(f"   - {stg['id']}: {stg['name']}")
        print(f"\n🔧 Lenguaje detectado: {l['detected_language']}")
        print(f"   Adapter disponible: {'✅' if l['has_adapter'] else '❌'}")
        print(f"\n⚙️  Config:")
        for name, res in c.get("results", {}).items():
            status = "✅" if res.get("status") == "ok" else "⏭️" if "skip" in res.get("status", "") else "❌"
            print(f"   {status} {name}")

        if results["stages"].get("_note"):
            print(f"\n📝 {results['stages']['_note']}")

    return results


if __name__ == "__main__":
    main()
