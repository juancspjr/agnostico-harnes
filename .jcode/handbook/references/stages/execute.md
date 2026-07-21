# Stage: execute — Execution

> Worker, build, edit, commit

## Responsibilities

Worker, build, edit, commit

## Inputs / Outputs

- **Inputs**: harness state, user request
- **Outputs**: stage artifact (loop declaration, build artifact, verification result, handoff)

## Execution flow

See related functions below.

## State

Relevant state registers (see registers.md):
- (auto-detected from state_accesses)

## Internal units

**Functions in this stage**: 16

### `git_diff_files`

- **File**: `.jcode/lib/handbook_resync.py`
- **Line range**: 20-30
- **Signature**: `(repo_root: Path) -> list`
- **Purpose**: (heuristic) git_diff_files → stage(s) execute. Clasificado por heurística de source analysis.

### `load_json`

- **File**: `.jcode/lib/handbook_resync.py`
- **Line range**: 33-37
- **Signature**: `(path: Path) -> dict`
- **Purpose**: (heuristic) load_json → stage(s) execute. Clasificado por heurística de source analysis.

### `save_json`

- **File**: `.jcode/lib/handbook_resync.py`
- **Line range**: 40-43
- **Signature**: `(path: Path, data: dict)`
- **Purpose**: (heuristic) save_json → stage(s) execute. Clasificado por heurística de source analysis.

### `rebuild_full`

- **File**: `.jcode/lib/handbook_resync.py`
- **Line range**: 129-139
- **Signature**: `(repo_root: Path, handbook_dir: Path)`
- **Purpose**: (heuristic) rebuild_full → stage(s) execute. Clasificado por heurística de source analysis.

### `main`

- **File**: `.jcode/lib/_config_parse.py`
- **Line range**: 87-112
- **Signature**: `()`
- **Purpose**: (heuristic) main → stage(s) verify, execute. Clasificado por heurística de source analysis.

### `build_stage_skeleton`

- **File**: `.jcode/lib/handbook_phase2.py`
- **Line range**: 56-58
- **Signature**: `() -> dict`
- **Purpose**: (heuristic) build_stage_skeleton → stage(s) execute. Clasificado por heurística de source analysis.

### `_classify_with_heuristic`

- **File**: `.jcode/lib/handbook_phase2.py`
- **Line range**: 78-145
- **Signature**: `(func: dict, context: dict) -> list`
- **Purpose**: (heuristic) _classify_with_heuristic → stage(s) handoff, execute, verify, plan, interpret. Clasificado por heurística de source analysis.

### `run_phase2`

- **File**: `.jcode/lib/handbook_phase2.py`
- **Line range**: 169-255
- **Signature**: `(program_graph_path: str='.jcode/handbook/program_graph.json', output_path: str='.jcode/handbook/behavioral_mapping.json') -> dict`
- **Purpose**: (heuristic) run_phase2 → stage(s) verify, execute. Clasificado por heurística de source analysis.

### `load_json`

- **File**: `.jcode/lib/handbook_verify.py`
- **Line range**: 17-21
- **Signature**: `(path: Path) -> dict`
- **Purpose**: (heuristic) load_json → stage(s) execute. Clasificado por heurística de source analysis.

### `run_phase3`

- **File**: `.jcode/lib/handbook_phase3.py`
- **Line range**: 272-350
- **Signature**: `(program_graph_path: str='.jcode/handbook/program_graph.json', mapping_path: str='.jcode/handbook/behavioral_mapping.json', handbook_dir: str='.jcode/handbook') -> dict`
- **Purpose**: (heuristic) run_phase3 → stage(s) verify, execute. Clasificado por heurística de source analysis.

### `PythonAdapter.extract`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 112-188
- **Signature**: `(self, repo_root: Path) -> dict`
- **Purpose**: (heuristic) PythonAdapter.extract → stage(s) execute. Clasificado por heurística de source analysis.

### `PythonAdapter._extract_from_tree`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 190-214
- **Signature**: `(self, tree, rel_path, source, functions, call_edges, state_accesses, unresolved_calls_log)`
- **Purpose**: (heuristic) PythonAdapter._extract_from_tree → stage(s) execute. Clasificado por heurística de source analysis.

### `_read_source_dirs`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 51-68
- **Signature**: `(repo_root: Path) -> list`
- **Purpose**: (heuristic) _read_source_dirs → stage(s) execute. Clasificado por heurística de source analysis.

### `_read_source_dirs_from_config`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 71-82
- **Signature**: `(repo_root: Path) -> list`
- **Purpose**: (heuristic) _read_source_dirs_from_config → stage(s) init, execute. Clasificado por heurística de source analysis.

### `build_program_graph`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 308-312
- **Signature**: `(repo_root: str) -> dict`
- **Purpose**: (heuristic) build_program_graph → stage(s) execute. Clasificado por heurística de source analysis.

### `save_program_graph`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 315-324
- **Signature**: `(graph: dict, output_path: str)`
- **Purpose**: (heuristic) save_program_graph → stage(s) execute. Clasificado por heurística de source analysis.


## Code anchors

Auto-generated. For verification, run `handbook_verify.py`.
