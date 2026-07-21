# Evidence Bundle — loop_id: {loop_id}

> Generar al cerrar un loop. Persistir en `.jcode/logs/evidence-{loop_id}.md`.

## Verificación
- fixed_check: `{comando}`
- fixed_check_exit: `{0/1}`
- fixed_check_log: `.jcode/logs/...`

## Test independiente
- independent_test: `{comando}`
- independent_exit: `{0/1}`
- independent_oracle_source: `{fuente primaria (AST, grep, etc.)}`

## Regresión
- regression: `bash .jcode/tests/run_all.sh`
- regression_result: `{X} pass, {Y} fail`

## Scope
- diff_stat: `{X} files changed, {Y} insertions`
- scope_check: `pass/fail`
- out_of_scope_touched: `{archivos fuera de scope, si aplica}`

## Cross-check (si hubo renombrado/movida)
- cross_check: `pass/fail/NA`
- old_name_refs: `0` (debe ser 0)
- new_name_refs: `≥1` (debe ser ≥1 donde corresponda)

## Idempotencia (si hubo mutación de estado)
- idempotency_check: `pass/fail/NA`
- second_run_exit: `{0/1}`

## Placeholders
- placeholder_check: `pass`
- remaining: `{TODO/FIXME/stub encontrados, si aplica}`

## Aprobaciones
- approvals: `{aprobaciones requeridas, si aplica}`

## Veredicto
- verdict: `PASSED/FAILED`
- hf_gate: `passed/blocked`
- fecha: `{YYYY-MM-DD}`
