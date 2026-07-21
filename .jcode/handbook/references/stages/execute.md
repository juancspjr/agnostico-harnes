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

**Functions in this stage**: 12

### `parse_toml`

- **File**: `.jcode/lib/_config_parse.py`
- **Line range**: 15-42
- **Signature**: `(content)`
- **Purpose**: Función parse_toml participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `parse_section_body`

- **File**: `.jcode/lib/_config_parse.py`
- **Line range**: 45-67
- **Signature**: `(body)`
- **Purpose**: Función parse_section_body participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `get_value`

- **File**: `.jcode/lib/_config_parse.py`
- **Line range**: 70-84
- **Signature**: `(toml_data, key_path)`
- **Purpose**: Función get_value participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `main`

- **File**: `.jcode/lib/_config_parse.py`
- **Line range**: 87-112
- **Signature**: `()`
- **Purpose**: Función main participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `PythonAdapter.extract`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 21-71
- **Signature**: `(self, repo_root: Path) -> dict`
- **Purpose**: Función PythonAdapter.extract participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `PythonAdapter._extract_from_tree`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 73-97
- **Signature**: `(self, tree, rel_path, source, functions, call_edges, state_accesses, unresolved_calls_log)`
- **Purpose**: Función PythonAdapter._extract_from_tree participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `PythonAdapter._record_function`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 99-157
- **Signature**: `(self, func_node, rel_path, source, functions, call_edges, state_accesses, unresolved_calls_log, qualname_prefix='')`
- **Purpose**: Función PythonAdapter._record_function participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `PythonAdapter._get_call_name`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 159-165
- **Signature**: `(self, func_node)`
- **Purpose**: Función PythonAdapter._get_call_name participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `PythonAdapter._is_assign_target`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 167-171
- **Signature**: `(self, attr_node)`
- **Purpose**: Función PythonAdapter._is_assign_target participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `build_program_graph`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 174-178
- **Signature**: `(repo_root: str) -> dict`
- **Purpose**: Función build_program_graph participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `save_program_graph`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 181-190
- **Signature**: `(graph: dict, output_path: str)`
- **Purpose**: Función save_program_graph participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.

### `main`

- **File**: `.jcode/lib/handbook_builder.py`
- **Line range**: 193-202
- **Signature**: `()`
- **Purpose**: Función main participa en stage(s) execute. Implementa la lógica operacional del harness para la fase execute.


## Code anchors

Auto-generated. For verification, run `handbook_verify.py`.
