# FAILURE-PATTERNS.md — Hidden Failure Patterns (Anexo normativo)

type: RULE
importance: M
version: 101.3-hidden-failures
date: 2026-07-21
title: Patrones de fallo ocultos y recurrentes de agentes — normas de prevención

## §0 Propósito y rango

Este archivo es un **anexo normativo** de:

- `PRINCIPLES.md`
- `AGENT-PROTOCOL.md`

No define dominio. No define negocio. No define stack.
Define **patrones de fallo ocultos** que los agentes suelen repetir incluso cuando "creen" que hicieron bien el trabajo.

### Cuándo es de carga obligatoria

Este anexo se carga cuando ocurra **cualquiera** de estas condiciones:

- `task_class >= SLICE`
- el mismo `fixed_check` falló 2 veces
- se abrió una remediación
- hay cambio de contrato, schema, migración o consumidor externo
- se está por declarar "listo", "resuelto" o "funciona"
- hubo un bloqueo de guardrail o respuesta anómala del LLM

Si ninguna de estas condiciones aplica, se usa como referencia preventiva.

### Jerarquía

Si este anexo entra en conflicto con `PRINCIPLES.md`, prevalece `PRINCIPLES.md`.
Este archivo solo **operacionaliza** prevención de autoengaño y fallos silenciosos.

---

## §1 Regla madre

### R-HF-0 — EVIDENCE-OR-IT-DID-NOT-HAPPEN

Toda afirmación de progreso requiere evidencia:

- ejecutable
- reproducible
- persistida
- verificable por terceros

Si no hay evidencia, no hay progreso.
Si la evidencia no está persistida, el fix no ocurrió.

Esto extiende y operacionaliza:

- §7 R-VERIFY-BEFORE-CLAIM
- §8 R-INDEPENDENT-TEST
- §9 R-ITERATION-LOG
- §11 R-REGRESSION-BEFORE-MERGE

---

## §2 Hidden Failure Gate (HF Gate)

Ningún loop puede cerrarse y ningún fix puede declararse resuelto si el **HF Gate** no pasa completo.

### Condiciones obligatorias de cierre

- [ ] `fixed_check` ejecutado con `set -euo pipefail` o equivalente
- [ ] `fixed_check` contiene aserciones explícitas sobre el resultado esperado
- [ ] `fixed_check` pasó con exit code 0
- [ ] la salida completa de `fixed_check` quedó persistida en log
- [ ] existe test independiente y pasó con exit code 0
- [ ] el test independiente no usa como oracle exclusivo archivos generados por el fix
- [ ] la regresión obligatoria pasó o existe blocker explícito aprobado
- [ ] existe iteration log completo
- [ ] el diff toca solo el scope declarado
- [ ] no quedaron placeholders silenciosos en el camino crítico
- [ ] si hubo mutación de estado, es idempotente y re-ejecutable
- [ ] si hubo renombrado/movida/eliminación de campos, se hizo cross-check de consumidores
- [ ] el evidence bundle mínimo está completo y persistido

Si falta una sola condición, el estado correcto es:

- `NOT CLOSED`
- o `BLOCKED`
- o `PENDING EVIDENCE`

Nunca "listo".

---

## §3 Catálogo normativo de patrones ocultos

Cada patrón tiene:

- ID
- descripción
- norma obligatoria
- detección
- severidad

### Severidad

- **Alta**: strike inmediato + detener claim de éxito hasta evidencia
- **Media**: corregir + strike si reincide
- **Baja**: warning; si reincide, pasa a Media

---

## §3.1 Patrones de verificación

| ID | Patrón oculto | Norma obligatoria | Detección | Severidad |
|---|---|---|---|---|
| HF-V1 | **PHANTOM-PASS**: el check pasa pero no verifica realmente la condición objetivo | Todo `fixed_check` debe incluir una aserción explícita del resultado esperado. Si no hay aserción, no es verificación. | Comando sin `grep`, `jq`, `test`, assert o comparación explícita; salida vacía tratada como éxito | Alta |
| HF-V2 | **SELF-ORACLE**: el test independiente valida usando artefactos generados por el propio fix | El test independiente debe recalcular desde ground truth o fuente primaria. No puede depender solo de archivos producidos por el cambio. | El script independiente lee únicamente outputs generados por el fix | Alta |
| HF-V3 | **TEST-MUTATION-TO-PASS**: se debilita el test para que pase en vez de resolver la causa raíz | Si cambia un test o un expected, debe existir nota de causa raíz, actualización de comportamiento o aprobación explícita. Prohibido borrar aserciones solo para cerrar el loop. | Diff elimina aserciones, skipea tests o cambia expected sin justificación persistida | Alta |
| HF-V4 | **PARTIAL-VERIFICATION**: solo se prueba el happy path | Si el comportamiento tiene modos de fallo relevantes, el check debe incluir al menos un caso negativo o borde, o declarar explícitamente que queda fuera de scope. | No existen casos inválidos, de error o borde para una regla crítica | Media |
| HF-V5 | **FLAKY-NORMALIZED**: un resultado intermitente se declara como fix válido | Si el check no es determinístico, debe ejecutarse 5 veces y pasar 5/5. Si no, se declara blocker, no éxito. | Exit code variable, dependencia de timing, `sleep`, condiciones de carrera | Alta |
| HF-V6 | **TRUNCATED-EVIDENCE**: se descarta stdout/stderr y no queda evidencia completa | Toda verificación crítica debe capturar salida completa a log. Prohibido silenciar salida si eso oculta evidencia. | Redirecciones a `/dev/null`, logs vacíos, salida truncada sin nota | Media |

---

## §3.2 Patrones de estado y contexto

| ID | Patrón oculto | Norma obligatoria | Detección | Severidad |
|---|---|---|---|---|
| HF-S1 | **STALE-CONTEXT**: el agente sigue trabajando con contexto viejo o resumido sin revalidar estado | Al iniciar turno, y siempre tras compactación o handoff, se debe releer el estado mínimo y validar `loop_id`, scope y próximo paso. | No hay lectura de `PLAN-VIVO`, `INTERPRETACION` o estado activo antes de actuar | Alta |
| HF-S2 | **STATE-AMNESIA**: decisiones, supuestos o aprobaciones quedan solo en memoria de sesión | Todo supuesto, aprobación, limitación o cambio de alcance debe persistirse en el plano mayor o registro correspondiente. | Claim o supuesto no aparece en `PLAN-VIVO`, `STATE-REGISTERS` o bitácora | Media |
| HF-S3 | **CROSS-CONSUMER-DESYNC**: se cambia un nombre, campo o contrato y no se sincronizan consumidores | Si se renombra, mueve o elimina un elemento observable, debe hacerse cross-check explícito de consumidores: 0 referencias viejas, ≥1 referencia nueva donde corresponda. | Grep de nombre viejo retorna >0 o grep de nombre nuevo retorna 0 en consumidores esperados | Alta |
| HF-S4 | **NON-IDEMPOTENT-STATE**: scripts, migraciones o mutaciones no pueden re-ejecutarse sin romper | Toda mutación de estado debe ser idempotente o declarar explícitamente que no lo es, con plan de rollback y aprobación. | Segunda ejecución falla; creación/borrado sin guardas; ausencia de dry-run/rollback | Alta |
| HF-S5 | **ORDER-DEPENDENT-STATE**: la verificación depende del estado dejado por una corrida previa | Los checks deben partir de estado limpio o documentar el seed requerido. Si son stateful, debe validarse re-ejecución o reset explícito. | El check pasa solo después de otra corrida o depende de residuos previos | Media |

---

## §3.3 Patrones de ejecución y cambio

| ID | Patrón oculto | Norma obligatoria | Detección | Severidad |
|---|---|---|---|---|
| HF-E1 | **SILENT-NO-OP**: no hay cambio real pero se declara avance | Si el diff es vacío o cosmético, se declara `no-op` explícito. No cuenta como progreso. | `git diff` vacío o solo comentarios/whitespace sin cambio funcional | Alta |
| HF-E2 | **SCOPE-CREEP**: el cambio toca más de lo declarado | El diff debe permanecer dentro del scope del loop. Si toca más archivos de los esperados, debe justificarse en `PLAN-VIVO §6` o abrir nuevo loop. | Archivos fuera de `scope` o `out_of_scope` modificados sin justificación | Media/Alta si toca approval boundary |
| HF-E3 | **ERROR-SWALLOW**: se suprimen errores silenciosamente | Prohibido silenciar errores sin rastro. Todo fallback debe ser visible, logueado y declarado. | Catch vacío, `|| true`, supresión de stderr sin logging, fallback silencioso | Alta |
| HF-E4 | **FAKE-PROGRESS**: se declara listo con placeholders, stubs o código no implementado | No puede declararse resuelto un camino crítico con `TODO`, `FIXME`, stubs no visibles o lógica simulada silenciosa. | Grep de placeholders en rutas críticas; stub sin warning explícito | Alta |
| HF-E5 | **ENV-ASSUMPTION**: se asume entorno, servicio o variable disponible sin verificar | Toda dependencia externa requerida por el check debe prevalidarse. Si falta, el check debe fallar de forma clara, no comportarse como si estuviera. | Uso de variables/servicios sin preflight; fallo confuso por entorno ausente | Media |
| HF-E6 | **TOOL-HALLUCINATION**: se invoca un comando, archivo o API que no existe | Antes de usar una herramienta, archivo o endpoint, debe verificarse su existencia. Si no existe, se declara blocker. | Comando no encontrado, ruta inexistente, llamada a método inexistente | Alta |
| HF-E7 | **DESTRUCTIVE-DEFAULT**: operaciones destructivas corren por defecto sin protección | Toda operación destructiva requiere dry-run, guarda explícita o aprobación. El modo seguro es el default. | Borrado/drop/force sin confirmación, sin reversión o sin plan | Alta |
| HF-E8 | **DEPENDENCY-DRIFT**: cambia el manifiesto de dependencias sin evidencia de build/install | Si cambia una dependencia, debe existir evidencia de instalación/build o declararse blocker. | Cambio en manifiesto sin log de build/install asociado | Media |

---

## §3.4 Patrones de gobernanza y anti-autoengaño

| ID | Patrón oculto | Norma obligatoria | Detección | Severidad |
|---|---|---|---|---|
| HF-G1 | **LOGLESS-REMEDIATION**: se remedia sin registro documental | Toda iteración de remediación debe dejar log completo. Sin log, no ocurrió. | No existe `.jcode/logs/remediation-{ID}-iter{N}.log` o está vacío | Alta |
| HF-G2 | **FAKE-COMPLIANCE**: se marcan flags de compliance sin evidencia | Todo booleano de compliance debe referenciar evidencia: comando, log, output o artifact. | `srsi_done_this_turn=true`, `ddlp_done=true`, etc. sin evidencia asociada | Alta |
| HF-G3 | **REGRESSION-SKIP**: se mergea sin regresión completa | Antes de merge, la regresión obligatoria debe pasar. Si no pasa, no se mergea; se abre blocker. | Falta `run_all.sh`, `harness.sh check`, o verify blockers | Alta |
| HF-G4 | **APPROVAL-BYPASS**: se cruza un approval boundary sin aprobación explícita | Si el loop declara approval boundary, ningún cambio dentro de esa frontera puede cerrarse sin aprobación registrada. | Cambio de schema/contrato/política sin constancia de aprobación | Alta |
| HF-G5 | **GUARDRAIL-EVASION**: se reformula o cambia de proveedor para evitar un bloqueo | Ante bloqueo de guardrail, se aplica `INCIDENT-PROTOCOLS.md`. Prohibido evadir por reformulación o cambio de proveedor. | Cambio de proveedor o reescritura sospechosa tras bloqueo sin registro en §14 | Alta |
| HF-G6 | **DOC-DRIFT**: cambia comportamiento observable y no se actualizan mapas/registros | Si cambia una feature observable o modelo de datos, debe actualizarse el registro de comportamiento o estado correspondiente. | Cambio observable sin entrada en `BEHAVIOR-INDEX.md` o `STATE-REGISTERS.md` | Media |
| HF-G7 | **CONTEXT-BLOAT**: se lee archivo histórico completo sin necesidad | Prohibido cargar archivos archivados completos. Solo búsqueda puntual con grep/rg. | Lectura integral de `archive/` o históricos sin búsqueda específica | Baja/Media |

---

## §4 Evidence Bundle mínimo

Todo loop que cierre debe persistir un **Evidence Bundle** con, al menos:

- `loop_id`
- `task_class`
- comando `fixed_check`
- exit code de `fixed_check`
- ruta al log con salida completa
- comando del test independiente
- exit code del test independiente
- fuente de ground truth usada por el test independiente
- resultado de regresión
- diff stat
- resultado de scope check
- resultado de cross-check de consumidores si aplica
- resultado de idempotencia si aplica
- approvals si aplica
- verdict final: `PASSED` o `FAILED`

### Plantilla recomendada

```
### Evidence Bundle — loop_id: L-XXX-NNN
- fixed_check: <comando>
- fixed_check_exit: 0
- fixed_check_log: .jcode/logs/...
- independent_test: <comando>
- independent_exit: 0
- independent_oracle_source: <fuente primaria>
- regression: <comando>
- regression_result: pass/fail count
- diff_stat: ...
- scope_check: pass/fail
- cross_check: pass/fail/NA
- idempotency_check: pass/fail/NA
- approvals: ...
- verdict: PASSED/FAILED
```

---

## §5 Checklist operacional por turno

Este checklist es obligatorio cuando aplica carga del anexo.

- [ ] HF1. `fixed_check` tiene aserciones explícitas, no solo "exit 0"
- [ ] HF2. `fixed_check` se ejecutó sin silenciar salida y guardó evidencia
- [ ] HF3. Existe test independiente y pasó
- [ ] HF4. El test independiente no usa self-oracle
- [ ] HF5. Si se modificaron tests, hay causa raíz o aprobación persistida
- [ ] HF6. Si el check es no determinístico, se ejecutó 5/5 o se declaró blocker
- [ ] HF7. Si el diff es vacío, se declaró no-op explícito
- [ ] HF8. El diff permanece dentro del scope declarado
- [ ] HF9. No hay supresión silenciosa de errores
- [ ] HF10. No quedan placeholders en el camino crítico
- [ ] HF11. Si hubo mutación de estado, se probó idempotencia o se declaró excepción
- [ ] HF12. Si hubo renombrado, se hizo cross-check de consumidores
- [ ] HF13. El evidence bundle está completo y persistido
- [ ] HF14. Los flags de compliance referencian evidencia real

---

## §6 Política de strikes por patrón

### Severidad Alta

strike inmediato + detener claim de éxito + abrir remediación o blocker + exigir evidencia completa antes de reanudar.

Aplica a: HF-V1, HF-V2, HF-V3, HF-V5, HF-S1, HF-S3, HF-S4, HF-E1, HF-E3, HF-E4, HF-E6, HF-E7, HF-G1, HF-G2, HF-G3, HF-G4, HF-G5.

### Severidad Media

Primera ocurrencia: corregir + nota en `PLAN-VIVO §6`. Segunda ocurrencia: strike. Tercera: activar `R-3STRIKE-MVP`.

Aplica a: HF-V4, HF-V6, HF-S2, HF-S5, HF-E2, HF-E5, HF-E8, HF-G6.

### Severidad Baja/Media

Warning inicial. Si reincide, strike.

Aplica a: HF-G7.

---

## §7 Detección automática mínima recomendada

### Evidencia y verificación

- ¿el comando de verificación incluye una aserción explícita?
- ¿el exit code es 0?
- ¿hay log persistido?
- ¿el test independiente usa una fuente primaria distinta del output del fix?

### Diff y scope

- listar archivos cambiados
- comparar contra `scope` y `out_of_scope`
- si el diff es vacío, declarar no-op

### Placeholders

Buscar en rutas críticas: `TODO`, `FIXME`, `stub`, `fallback`, `not implemented`.

### Supresión de errores

Detectar: `|| true`, redirección total a null, catch vacío, fallback sin warning.

### Idempotencia

Ejecutar dos veces la mutación. Segunda ejecución debe pasar o estar declarada como no idempotente.

### Cross-check

- grep de nombre viejo → 0 matches
- grep de nombre nuevo → matches esperados

---

## §8 Campos de compliance sugeridos

```json
"hidden_failure_catalog": {
  "hf_gate_passed": false,
  "hf_evidence_bundle_path": "",
  "hf_strikes": {
    "HF-V1": 0, "HF-V2": 0, "HF-V3": 0, "HF-V4": 0, "HF-V5": 0, "HF-V6": 0,
    "HF-S1": 0, "HF-S2": 0, "HF-S3": 0, "HF-S4": 0, "HF-S5": 0,
    "HF-E1": 0, "HF-E2": 0, "HF-E3": 0, "HF-E4": 0, "HF-E5": 0,
    "HF-E6": 0, "HF-E7": 0, "HF-E8": 0,
    "HF-G1": 0, "HF-G2": 0, "HF-G3": 0, "HF-G4": 0, "HF-G5": 0, "HF-G6": 0, "HF-G7": 0
  }
}
```

---

## §9 Sincronización obligatoria si este anexo se vuelve ley

Si este catálogo se incorpora como normativa vigente, actualizar:

- `PRINCIPLES.md` → agregar puntero normativo
- `AGENT-PROTOCOL.md` → lectura condicional + checklist HF
- `LOOPS.md` → exigir `hf_gate` en cierre de loops
- `config.toml` → policy ejecutable
- `README.md` → mapa del harness

---

## Versión

- v101.3-hidden-failures (2026-07-21): versión inicial del catálogo de patrones ocultos de fallo.
