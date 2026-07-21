# Stage: verify — Verification

> fixed_check, smoke tests, screenshot

## Responsibilities

fixed_check, smoke tests, screenshot

## Inputs / Outputs

- **Inputs**: harness state, user request
- **Outputs**: stage artifact (loop declaration, build artifact, verification result, handoff)

## Execution flow

See related functions below.

## State

Relevant state registers (see registers.md):
- (auto-detected from state_accesses)

## Internal units

**Functions in this stage**: 9

### `get_value`

- **File**: `.jcode/lib/_config_parse.py`
- **Line range**: 70-84
- **Signature**: `(toml_data, key_path)`
- **Purpose**: (heuristic) get_value → stage(s) verify. Clasificado por heurística de source analysis.

### `main`

- **File**: `.jcode/lib/_config_parse.py`
- **Line range**: 87-112
- **Signature**: `()`
- **Purpose**: (heuristic) main → stage(s) verify, execute. Clasificado por heurística de source analysis.

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

### `verify_site`

- **File**: `.jcode/lib/handbook_verify.py`
- **Line range**: 36-82
- **Signature**: `(repo_root: Path, entry: dict) -> dict`
- **Purpose**: (heuristic) verify_site → stage(s) verify. Clasificado por heurística de source analysis.

### `verify_handbook`

- **File**: `.jcode/lib/handbook_verify.py`
- **Line range**: 85-146
- **Signature**: `(repo_root: str='.', request: str='', stages: list=None) -> dict`
- **Purpose**: (heuristic) verify_handbook → stage(s) verify. Clasificado por heurística de source analysis.

### `run_phase3`

- **File**: `.jcode/lib/handbook_phase3.py`
- **Line range**: 272-350
- **Signature**: `(program_graph_path: str='.jcode/handbook/program_graph.json', mapping_path: str='.jcode/handbook/behavioral_mapping.json', handbook_dir: str='.jcode/handbook') -> dict`
- **Purpose**: (heuristic) run_phase3 → stage(s) verify, execute. Clasificado por heurística de source analysis.

### `_validate_repo_root`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 92-106
- **Signature**: `(repo_root: Path)`
- **Purpose**: (heuristic) _validate_repo_root → stage(s) verify. Clasificado por heurística de source analysis.

### `main`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 327-340
- **Signature**: `()`
- **Purpose**: (heuristic) main → stage(s) verify. Clasificado por heurística de source analysis.


## Code anchors

Auto-generated. For verification, run `handbook_verify.py`.
