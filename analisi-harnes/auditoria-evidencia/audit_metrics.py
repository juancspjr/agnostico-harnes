"""
audit_metrics.py — Recálculo independiente de métricas del handbook.
Ejecuta para validar/contrastar claims de los agentes constructores.

Uso:
  python3 analisi-harnes/auditoria-evidencia/audit_metrics.py
"""

import json
import os
import sys
from collections import Counter

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    print(f"=== Auditoría forense de métricas ({REPO}) ===\n")

    pg_path = os.path.join(REPO, ".jcode/handbook/program_graph.json")
    cb_path = os.path.join(REPO, ".jcode/handbook/cache_B.json")
    bm_path = os.path.join(REPO, ".jcode/handbook/behavioral_mapping.json")
    fr_path = os.path.join(REPO, ".jcode/handbook/frozen_entries.json")

    if not os.path.exists(pg_path):
        print(f"❌ {pg_path} no existe")
        return 1

    pg = json.load(open(pg_path))
    cb = json.load(open(cb_path))
    bm = json.load(open(bm_path))
    frozen = json.load(open(fr_path))

    funcs = pg["functions"]
    edges = pg["call_edges"]
    state = pg["state_accesses"]

    print("📊 Conteos directos:")
    print(f"  PG functions:           {len(funcs)}")
    print(f"  PG call_edges:          {len(edges)}")
    print(f"  PG state_accesses:      {len(state)}")
    print(f"  BM function_assignments: {len(bm['function_assignments'])}")
    print(f"  CB l3_entries:          {len(cb.get('l3_entries', {}))}")
    print(f"  Frozen entries:         {len(frozen)}")

    # Source hash check
    empty_hash = sum(1 for e in cb["l3_entries"].values() if not e.get("source_hash"))
    print(f"\n🔍 L3 entries con source_hash vacío: {empty_hash}/{len(cb['l3_entries'])}")

    # Stage distribution
    stages = Counter()
    for qn, e in cb["l3_entries"].items():
        for s in e.get("relations", {}).get("stages", []):
            stages[s] += 1
    print(f"\n🎯 Distribución de stages en L3:")
    for s, c in sorted(stages.items(), key=lambda x: -x[1]):
        print(f"  {s}: {c}")
    if len(stages) == 1:
        print(f"  ⚠️  Solo 1 stage asignado (esperado 2-6 en handbook real)")

    # Function files
    files = set(f["file"] for f in funcs)
    print(f"\n📂 Files en PG: {len(files)}")
    for f in sorted(files):
        print(f"  - {f}")

    # Circularity check
    lib_files = [".jcode/lib/_config_parse.py", ".jcode/lib/handbook_builder.py",
                 ".jcode/lib/handbook_phase2.py", ".jcode/lib/handbook_phase3.py",
                 ".jcode/lib/handbook_resync.py", ".jcode/lib/handbook_verify.py"]
    missing = [f for f in lib_files if f not in files]
    if missing:
        print(f"\n❌ Archivos del harness NO escaneados (circularidad rota):")
        for f in missing:
            print(f"  - {f}")

    # Call edges to builtins
    builtin_edges = sum(1 for e in edges
                       if e["callee"] in ("split", "join", "match", "startswith",
                                          "strip", "append", "write", "read",
                                          "load", "dump", "format", "lower",
                                          "upper", "replace", "print"))
    print(f"\n🔗 Call edges a builtins: {builtin_edges}/{len(edges)} ({builtin_edges*100//max(1,len(edges))}%)")

    # State accesses as calls disguised
    # Heurística: atributo contiene 'self.X' donde X empieza con _
    call_disguised = sum(1 for s in state
                        if "." in s["attribute"]
                        and s["attribute"].split(".")[1].startswith("_"))
    print(f"\n📦 State accesses tipo self._meth (probable call disfrazado): {call_disguised}/{len(state)}")

    # More thorough: look for known method-style attributes
    method_patterns = ["_extract_", "_record_", "_get_", "_is_", "_compute_", "_build_"]
    suspected_calls = sum(1 for s in state
                         if any(p in s["attribute"] for p in method_patterns))
    print(f"   (de los cuales con patrón de método): {suspected_calls}/{len(state)}")

    # Mismatch check
    print(f"\n⚖️  Mismatch analysis:")
    pg_qn = {f["qualname"] for f in funcs}
    bm_qn = {f["qualname"] for f in bm["function_assignments"]}
    cb_qn = set(cb["l3_entries"].keys())

    if pg_qn != bm_qn:
        print(f"  PG vs BM mismatch:")
        print(f"    PG \\ BM: {pg_qn - bm_qn}")
        print(f"    BM \\ PG: {bm_qn - pg_qn}")
    else:
        print(f"  PG == BM (sets iguales)")
    if bm_qn != cb_qn:
        print(f"  BM vs CB mismatch:")
        print(f"    BM \\ CB: {bm_qn - cb_qn}")
        print(f"    CB \\ BM: {cb_qn - bm_qn}")
    else:
        print(f"  BM == CB (sets iguales)")

    print("\n=== Fin auditoría ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
