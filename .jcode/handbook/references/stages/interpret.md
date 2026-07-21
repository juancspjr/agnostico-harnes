# Stage: interpret — Interpretation

> Triage task, decide skills, load MCPs

## Responsibilities

Triage task, decide skills, load MCPs

## Inputs / Outputs

- **Inputs**: harness state, user request
- **Outputs**: stage artifact (loop declaration, build artifact, verification result, handoff)

## Execution flow

See related functions below.

## State

Relevant state registers (see registers.md):
- (auto-detected from state_accesses)

## Internal units

**Functions in this stage**: 2

### `_classify_with_heuristic`

- **File**: `.jcode/lib/handbook_phase2.py`
- **Line range**: 78-145
- **Signature**: `(func: dict, context: dict) -> list`
- **Purpose**: (heuristic) _classify_with_heuristic → stage(s) handoff, execute, verify, plan, interpret. Clasificado por heurística de source analysis.

### `classify_function_heuristic`

- **File**: `.jcode/lib/handbook_phase2.py`
- **Line range**: 148-156
- **Signature**: `(qualname: str, file: str, signature: str, source: str='', callers: list=None, callees: list=None) -> list`
- **Purpose**: (heuristic) classify_function_heuristic → stage(s) interpret. Clasificado por heurística de source analysis.


## Code anchors

Auto-generated. For verification, run `handbook_verify.py`.
