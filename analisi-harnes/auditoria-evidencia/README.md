# Evidencia de auditoría forense

Este directorio contiene scripts y outputs reproducibles de la auditoría forense del paper-compliant bootstrap del harness.

## Archivos

- `audit_metrics.py` — Recálculo independiente de métricas del handbook. Compara PG, BM, CB y detecta inconsistencias.
- `audit_security.py` — Tests de seguridad que ejecutan PoC de los hallazgos CRITICAL y HIGH.
- `audit_metrics_output.txt` — Output del primer script (estado del handbook).
- `audit_security_output.txt` — Output del segundo script (6 hallazgos confirmados).

## Uso rápido

```bash
python3 analisi-harnes/auditoria-evidencia/audit_metrics.py
python3 analisi-harnes/auditoria-evidencia/audit_security.py
```

## Resumen de hallazgos confirmados

| ID | Severidad | Test | Estado |
|----|-----------|------|--------|
| C-1 | CRITICAL | Circularidad rota (2/6 archivos escaneados) | ❌ FAIL |
| C-2 | CRITICAL | Modo stub permanente, sin LLM | ❌ FAIL |
| C-4 | CRITICAL | Builder corrompe PG con path inválido | ❌ FAIL |
| H-1 | HIGH | source_hash vacío en 11/11 L3 | ❌ FAIL |
| H-4 | HIGH | Resync sin Phase I no detecta cambios | ❌ FAIL |
| H-5 | HIGH | Sin locks en save_json() | ❌ FAIL |

## Reproducibilidad

Todos los tests son idempotentes: hacen backup/restore de los archivos modificados. Pueden ejecutarse contra el repo sin contaminarlo.
