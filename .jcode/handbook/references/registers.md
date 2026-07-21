# State Registers (Vista Z)

> Auto-generated on 2026-07-21T03:53:18.069310+00:00
> Maps each state register to all writers and readers.

## `self._extract_from_tree`

**Writers:**
- `PythonAdapter.extract` (.jcode/lib/handbook_builder.py:52)

**Readers:**

## `self._get_call_name`

**Writers:**
- `PythonAdapter._record_function` (.jcode/lib/handbook_builder.py:137)

**Readers:**

## `self._is_assign_target`

**Writers:**
- `PythonAdapter._record_function` (.jcode/lib/handbook_builder.py:150)

**Readers:**

## `self._record_function`

**Writers:**
- `PythonAdapter._extract_from_tree` (.jcode/lib/handbook_builder.py:93)
- `PythonAdapter._extract_from_tree` (.jcode/lib/handbook_builder.py:83)

**Readers:**


## Maintenance

- **R-SYNC-1**: Cuando agregues un campo de estado nuevo, agrega entrada en este archivo en el mismo commit.
- **R-SYNC-2**: Si un campo tiene más de 5 writers, probablemente debería descomponerse en derived fields.
