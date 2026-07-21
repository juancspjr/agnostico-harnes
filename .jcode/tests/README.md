---
type: TESTS-INDEX
importance: C
version: 001-template
date: 2026-07-21
title: Centro de Tests + Evidencia (plantilla agnóstica)
---

# Centro de Tests + Evidencia — `.jcode/tests/`

> **Regla del arnés**: TODO script de testing vive aquí. `bin/` solo
> contiene tooling del proyecto.
>
> **Evidencia centralizada**: cada test escribe su output en
> `tests/evidence/{test_name}-{YYYY-MM-DD-HHMM}.log` + actualiza
> `tests/evidence/latest.json` con el último resultado.

---

## Estructura

```
.jcode/tests/
├── README.md                          # Este archivo
├── run_all.sh                         # Runner global
│
├── smoke/                             # Tests rápidos (smoke + R-AA-1)
│   ├── smoke_harness_flow.sh
│   ├── smoke_hook_enforcement.sh
│   ├── smoke_r_aa_1.sh
│   ├── smoke_agent_protocol.sh
│   ├── smoke_r_no_fake_swarm.sh
│   ├── smoke_ddlp_tpsp.sh
│   └── evidence/
│
├── diagnostics/                       # Diagnósticos profundos
│   ├── diagnostics.sh
│   └── evidence/
│
├── audit/                             # Auditoría + autojudge
│   ├── audit_harness.sh
│   └── evidence/
│
├── measure/                           # Métricas / observabilidad
│   ├── measure_harness.sh
│   └── evidence/
│
├── integration/                       # Tests de flujos end-to-end del proyecto
│   ├── <test_flujo_X>.sh
│   └── evidence/
│
├── validation/                        # Validaciones específicas
│   └── evidence/
│
└── evidence/                          # 🗂️ EVIDENCIA CENTRALIZADA
    ├── README.md
    ├── latest.json
    └── YYYY-MM-DD/                    # Snapshots históricos por fecha
```

---

## Cómo correr todos los tests

### Runner global

```bash
bash .jcode/tests/run_all.sh            # corre todo
bash .jcode/tests/run_all.sh --quick    # solo smoke + diagnostics
bash .jcode/tests/run_all.sh --category smoke
```

Salida:
- Resumen verde/rojo por categoría
- `tests/evidence/latest.json` con resultado completo
- `tests/evidence/YYYY-MM-DD-HHMM/{test}.log` por test corrido

### Por categoría

```bash
# Solo smoke
for f in .jcode/tests/smoke/*.sh; do bash "$f"; done

# Solo diagnostics
bash .jcode/tests/diagnostics/diagnostics.sh
```

---

## Smoke tests provistos (del arnés v100-clean)

| Test | Qué verifica |
|------|--------------|
| `smoke_harness_flow.sh` | Arnés wirado + vigente |
| `smoke_hook_enforcement.sh` | Hooks bash funcionales |
| `smoke_r_aa_1.sh` | R-AA-1 anti-autoengaño |
| `smoke_agent_protocol.sh` | AGENT-PROTOCOL.md respetado |
| `smoke_r_no_fake_swarm.sh` | R-NO-FAKE-SWARM respetado |
| `smoke_ddlp_tpsp.sh` | DDLP + TPSP respetados |

> Los smoke tests son **del arnés** (no del proyecto). Son agnósticos
> y deben pasar en cualquier proyecto que use el arnés v100-clean.

---

## Cómo agregar tests del proyecto

> Cada proyecto debe agregar sus tests específicos en las subcarpetas.

### Tests unitarios del backend

```bash
# Crear carpeta si no existe
mkdir -p .jcode/tests/integration/

# Crear test
cat > .jcode/tests/integration/test_<feature>.sh <<'EOF'
#!/usr/bin/env bash
# Test del proyecto: <feature>
set -e
# ... tu test aquí
EOF
chmod +x .jcode/tests/integration/test_<feature>.sh
```

### Tests E2E del frontend

```bash
# Crear carpeta si no existe
mkdir -p .jcode/tests/e2e/

# Crear test Playwright
cat > .jcode/tests/e2e/<feature>.spec.ts <<'EOF'
import { test, expect } from '@playwright/test';
// ... tu test aquí
EOF
```

### Actualizar run_all.sh

> Si agregas una categoría nueva, actualizar `run_all.sh` con el array
> `CATEGORIES`.

---

## Formato de evidencia

Cada test escribe:

1. **Log completo**: `tests/evidence/{test_name}-{YYYY-MM-DD-HHMM}.log`
   - Contiene stdout/stderr del test
   - Inmutable (nunca se sobreescribe)

2. **Latest summary**: `tests/evidence/latest.json`
   - Se sobreescribe en cada run
   - Estructura:
   ```json
   {
     "last_run": "2026-07-21T01:00:00Z",
     "categories": {
       "smoke": {"status": "PASS", "passes": 6, "fails": 0, "skips": 0},
       "diagnostics": {"status": "PASS", "passes": 5, "fails": 0}
     },
     "summary": {"total_passes": 11, "total_fails": 0}
   }
   ```

---

## Convenciones

- **Naming**: `test_<category>_<subcategory>.sh` (ej. `smoke_harness_flow.sh`)
- **Exit codes**: `0` = pass, `1` = fail, `2` = bloqueado/needs review
- **Output**: usar `pass`/`fail`/`info`/`warn`
- **No side effects en smoke**: solo lectura + verificación
- **Tests de integración pueden side-effect**: usar DB de test, mocks, fixtures

---

## Versión

- **v001-template** (2026-07-21): Plantilla agnóstica del centro de
  tests. Cada proyecto debe poblar las subcarpetas con sus tests
  específicos.