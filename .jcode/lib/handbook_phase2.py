#!/usr/bin/env python3
# =============================================================================
# .jcode/lib/handbook_phase2.py — Phase II: Behavioral Organization (paper §3.2)
# =============================================================================
# Loop Propose-Review-Mapping:
#   1. Construye stage skeleton S0 desde PRINCIPLES.md (task_class)
#   2. Clasifica cada función en un stage usando LLM (o stub si no hay SDK)
#   3. Genera behavioral_mapping.json con assignments
# Paper ref: arXiv:2607.13285v1, Phase II
# =============================================================================

import json
import sys
from pathlib import Path

# Stage skeleton S0 basado en PRINCIPLES.md PARTE II + execution stages típicos
DEFAULT_STAGES = [
    {"id": "init", "name": "Initialization", "description": "Bootstrap session, state init, integrity check"},
    {"id": "interpret", "name": "Interpretation", "description": "Triage task, decide skills, load MCPs"},
    {"id": "plan", "name": "Planning", "description": "DDLP, TPSP, declare loop"},
    {"id": "execute", "name": "Execution", "description": "Worker, build, edit, commit"},
    {"id": "verify", "name": "Verification", "description": "fixed_check, smoke tests, screenshot"},
    {"id": "handoff", "name": "Handoff", "description": "Closeout, update PLAN-VIVO §8, handoff next agent"},
]


def build_stage_skeleton() -> dict:
    """Construye el stage skeleton S0 desde PRINCIPLES.md o default."""
    return {"stages": DEFAULT_STAGES}


def classify_function_stub(qualname: str, file: str, signature: str) -> list:
    """Clasificador stub: asigna por heurística simple.

    Modo sin LLM: usa keywords en qualname/filename para asignar stages.
    """
    q_lower = qualname.lower()
    f_lower = file.lower()

    # Heurística simple por keywords
    if any(k in q_lower for k in ["init", "session_start", "bootstrap"]):
        return ["init"]
    if any(k in q_lower for k in ["interpret", "triage", "skill_", "classify"]):
        return ["interpret"]
    if any(k in q_lower for k in ["plan", "loop", "task_class", "ddlp"]):
        return ["plan"]
    if any(k in q_lower for k in ["execute", "build", "worker", "extract", "parse"]):
        return ["execute"]
    if any(k in q_lower for k in ["verify", "check", "test", "audit", "scan"]):
        return ["verify"]
    if any(k in q_lower for k in ["handoff", "closeout", "summary"]):
        return ["handoff"]

    # Default: execute (mayoría de funciones de harnés)
    return ["execute"]


def generate_purpose_stub(qualname: str, signature: str, stage_ids: list) -> str:
    """Genera una descripción purpose de 60-150 chars en modo stub."""
    stage_str = ", ".join(stage_ids)
    return (f"Función {qualname} participa en stage(s) {stage_str}. "
            f"Implementa la lógica operacional del harness para la fase "
            f"{stage_ids[0] if stage_ids else 'execute'}.")


def run_phase2(program_graph_path: str = ".jcode/handbook/program_graph.json",
               output_path: str = ".jcode/handbook/behavioral_mapping.json") -> dict:
    """Ejecuta Phase II: Behavioral Organization."""
    pg_path = Path(program_graph_path)
    if not pg_path.exists():
        print(f"[error] {program_graph_path} no existe. Ejecuta Phase I primero.", file=sys.stderr)
        sys.exit(1)

    with open(pg_path) as f:
        pg = json.load(f)

    stage_skeleton = build_stage_skeleton()
    function_assignments = []
    unmapped = []

    for func in pg["functions"]:
        qualname = func["qualname"]
        file = func["file"]
        signature = func["signature"]
        stage_ids = classify_function_stub(qualname, file, signature)
        purpose = generate_purpose_stub(qualname, signature, stage_ids)

        function_assignments.append({
            "qualname": qualname,
            "purpose": purpose,
            "granularity": pg.get("leaf_mode", "function"),
            "stage_assignments": stage_ids,
            "regions": None,
            "file": file,
            "line_range": func["line_range"],
        })

        if not stage_ids:
            unmapped.append(qualname)

    mapping = {
        "schema_version": 1,
        "leaf_mode": pg.get("leaf_mode", "function"),
        "stage_skeleton": stage_skeleton,
        "function_assignments": function_assignments,
        "coverage_record": {
            "unmapped_functions": unmapped,
        },
    }

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        json.dump(mapping, f, indent=2)

    print(f"[ok] Phase II: {len(function_assignments)} functions assigned to {len(stage_skeleton['stages'])} stages")
    print(f"     Unmapped: {len(unmapped)}")
    print(f"     Saved to {output_path}")
    return mapping


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Handbook Phase II: Behavioral Organization")
    parser.add_argument("--program-graph", default=".jcode/handbook/program_graph.json")
    parser.add_argument("--output", default=".jcode/handbook/behavioral_mapping.json")
    args = parser.parse_args()
    run_phase2(args.program_graph, args.output)


if __name__ == "__main__":
    main()