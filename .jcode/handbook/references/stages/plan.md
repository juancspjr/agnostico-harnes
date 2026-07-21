# Stage: plan — Planning

> DDLP, TPSP, declare loop

## Responsibilities

DDLP, TPSP, declare loop

## Inputs / Outputs

- **Inputs**: harness state, user request
- **Outputs**: stage artifact (loop declaration, build artifact, verification result, handoff)

## Execution flow

See related functions below.

## State

Relevant state registers (see registers.md):
- (auto-detected from state_accesses)

## Internal units

**Functions in this stage**: 3

### `_classify_with_heuristic`

- **File**: `.jcode/lib/handbook_phase2.py`
- **Line range**: 78-145
- **Signature**: `(func: dict, context: dict) -> list`
- **Purpose**: (heuristic) _classify_with_heuristic → stage(s) handoff, execute, verify, plan, interpret. Clasificado por heurística de source analysis.

### `generate_overview`

- **File**: `.jcode/lib/handbook_phase3.py`
- **Line range**: 47-102
- **Signature**: `(pg: dict, mapping: dict) -> str`
- **Purpose**: (heuristic) generate_overview → stage(s) plan, handoff. Clasificado por heurística de source analysis.

### `generate_stage_page`

- **File**: `.jcode/lib/handbook_phase3.py`
- **Line range**: 190-239
- **Signature**: `(stage_id: str, stage_name: str, stage_desc: str, funcs: list, pg: dict) -> str`
- **Purpose**: (heuristic) generate_stage_page → stage(s) plan, handoff. Clasificado por heurística de source analysis.


## Code anchors

Auto-generated. For verification, run `handbook_verify.py`.
