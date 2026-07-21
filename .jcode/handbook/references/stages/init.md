# Stage: init — Initialization

> Bootstrap session, state init, integrity check

## Responsibilities

Bootstrap session, state init, integrity check

## Inputs / Outputs

- **Inputs**: harness state, user request
- **Outputs**: stage artifact (loop declaration, build artifact, verification result, handoff)

## Execution flow

See related functions below.

## State

Relevant state registers (see registers.md):
- (auto-detected from state_accesses)

## Internal units

**Functions in this stage**: 1

### `_read_source_dirs_from_config`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 71-82
- **Signature**: `(repo_root: Path) -> list`
- **Purpose**: (heuristic) _read_source_dirs_from_config → stage(s) init, execute. Clasificado por heurística de source analysis.


## Code anchors

Auto-generated. For verification, run `handbook_verify.py`.
