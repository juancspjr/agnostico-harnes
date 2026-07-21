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


# Flag: LLM disponible (intentar import)
LLM_AVAILABLE = False
LLM_CLIENT = None
try:
    pass  # No z-ai SDK — will use heuristic
except ImportError:
    pass

# C-3: Visibilidad del modo stub
_STUB_MODE_WARNING_ISSUED = False

def _issue_stub_mode_warning():
    """Emite warning visible sobre el modo stub (no LLM)."""
    global _STUB_MODE_WARNING_ISSUED
    if not _STUB_MODE_WARNING_ISSUED:
        _STUB_MODE_WARNING_ISSUED = True
        import warnings
        warnings.warn(
            "Phase II en modo HEURÍSTICO (no LLM). "
            "Las clasificaciones son heurísticas, no basadas en LLM real. "
            "Para activar LLM: instalar z-ai-web-dev-sdk.",
            RuntimeWarning, stacklevel=2
        )
        print("[warn] Phase II: modo HEURÍSTICO (no LLM). "
              "Instala z-ai-web-dev-sdk para clasificación real.",
              file=sys.stderr)


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


def _read_source(func: dict) -> str:
    """Lee el source de una función desde el archivo."""
    file_path = func.get("file", "")
    line_range = func.get("line_range", [0, 0])
    if not file_path or not line_range or len(line_range) < 2:
        return ""
    p = Path(file_path)
    if not p.exists():
        return ""
    try:
        lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
        start, end = line_range
        return "\n".join(lines[max(0, start-1):end])
    except Exception:
        return ""


def _classify_with_heuristic(func: dict, context: dict) -> list:
    """Heurística avanzada: analiza source code, callers y callees.

    No asigna execute por defecto. Si no hay match, retorna [] (unmapped).
    """
    qualname = func.get("qualname", "").lower()
    file = func.get("file", "").lower()
    source = _read_source(func).lower()
    callers = [c.lower() for c in context.get("callers", [])]
    callees = [c.lower() for c in context.get("callees", [])]

    assignments = []

    # 1. init: bootstrap, session, init methods
    if any(k in qualname for k in ["__init__", "init", "setup", "bootstrap",
                                     "session_start", "config"]):
        assignments.append("init")
    elif any(k in source for k in ["__init__", "session"]):
        if any(k in qualname for k in ["init", "setup", "config"]):
            assignments.append("init")

    # 2. interpret: skill selection, triage, grep, search, classify
    if any(k in qualname for k in ["triage", "skill_", "interpret", "classify",
                                     "lookup", "select", "route"]):
        assignments.append("interpret")
    elif any(k in callees for k in ["grep", "search", "lookup", "find",
                                     "select_knowledge"]):
        assignments.append("interpret")

    # 3. plan: DDLP, TPSP, loop declarations
    if any(k in qualname for k in ["plan", "loop", "declare", "task_class",
                                     "ddlp", "tpsp", "set_current"]):
        assignments.append("plan")
    elif any(k in source for k in ["loop", "ddlp", "tpsp", "declare_plan"]):
        if "plan" not in assignments:
            assignments.append("plan")

    # 4. execute: file operations, build, edit, commit
    if any(k in qualname for k in ["execute", "build", "edit", "commit",
                                     "worker", "save", "write", "create_file",
                                     "apply_patch", "extract"]):
        assignments.append("execute")
    elif any(k in source for k in [".write(", "open(", "subprocess.run",
                                     "subprocess.call", "os.system"]):
        assignments.append("execute")

    # 5. verify: check, test, audit, validate
    if any(k in qualname for k in ["verify", "check", "test", "audit",
                                     "validate", "fixed_check", "smoke"]):
        assignments.append("verify")
    elif any(k in source for k in ["assert ", "exit(", "returncode",
                                     "smoke_", "audit_"]):
        assignments.append("verify")

    # 6. handoff: closeout, summary, handoff, update plan
    if any(k in qualname for k in ["handoff", "closeout", "summary",
                                     "report", "update_plan"]):
        assignments.append("handoff")
    elif any(k in source for k in ["handoff", "closeout", "update_plan_vivo"]):
        assignments.append("handoff")

    # 7. cross-cutting: funciones pequeñas llamadas desde muchos lugares
    if len(callers) >= 3 and len(source.splitlines()) <= 10:
        # No unassign existing, but note cross-cutting
        pass

    # Si no hay assignments, retornar [] (unmapped)
    return list(set(assignments))


def classify_function_heuristic(qualname: str, file: str, signature: str,
                                  source: str = "", callers: list = None,
                                  callees: list = None) -> list:
    """Wrapper para _classify_with_heuristic con interfaz legacy."""
    callers = callers or []
    callees = callees or []
    func = {"qualname": qualname, "file": file, "signature": signature}
    context = {"callers": callers, "callees": callees}
    return _classify_with_heuristic(func, context)


def generate_purpose(qualname: str, signature: str, stage_ids: list,
                     unmapped_reason: str = "") -> str:
    """Genera descripción purpose con información del stage."""
    if not stage_ids:
        return f"(unmapped: {unmapped_reason or 'no heuristic match'}) {qualname}"
    stage_str = ", ".join(stage_ids)
    return (f"(heuristic) {qualname} → stage(s) {stage_str}. "
            f"Clasificado por heurística de source analysis.")


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

    # C-3: emitir warning de modo stub
    _issue_stub_mode_warning()

    # Build caller/callee context from call_edges
    call_edges = pg.get("call_edges", [])
    callers_map = {}
    callees_map = {}
    for e in call_edges:
        caller = e["caller"]
        callee = e["callee"]
        if caller not in callers_map:
            callers_map[caller] = set()
        if callee not in callees_map:
            callees_map[callee] = set()
        callers_map[callee] = callers_map.get(callee, set())
        callees_map[caller] = callees_map.get(caller, set())
        callers_map[callee].add(caller)
        callees_map[caller].add(callee)

    for func in pg["functions"]:
        qualname = func["qualname"]
        file = func["file"]
        signature = func["signature"]

        context = {
            "callers": list(callers_map.get(qualname, [])),
            "callees": list(callees_map.get(qualname, [])),
        }

        stage_ids = _classify_with_heuristic(func, context)
        unmapped_reason = ""
        if not stage_ids:
            unmapped_reason = "no heuristic match"
            unmapped.append(qualname)

        purpose = generate_purpose(qualname, signature, stage_ids, unmapped_reason)

        function_assignments.append({
            "qualname": qualname,
            "purpose": purpose,
            "granularity": pg.get("leaf_mode", "function"),
            "stage_assignments": stage_ids,
            "regions": None,
            "file": file,
            "line_range": func["line_range"],
        })

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

    stage_dist = {}
    for fa in function_assignments:
        for s in fa["stage_assignments"]:
            stage_dist[s] = stage_dist.get(s, 0) + 1

    print(f"[ok] Phase II: {len(function_assignments)} functions assigned "
          f"to {len(stage_dist)} stages")
    print(f"     Stages: {stage_dist}")
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