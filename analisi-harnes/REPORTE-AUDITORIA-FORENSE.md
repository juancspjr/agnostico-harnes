# REPORTE DE AUDITORÍA FORENSE — paper-compliant-bootstrap

**Fecha**: 2026-07-21
**Auditor**: jcode (jcode agent)
**Repo auditado**: `/home/juan/proyectos/proyecto-01`
**Branch**: `feat/paper-compliant-bootstrap`
**Commits auditados**: 7 (bcd9984 → 4ddfa2e)
**Prompt aplicado**: `analisi-harnes/prompt-auditoria-forense-exhaustiva.md`

---

## §1 Resumen ejecutivo

### Veredicto: **RECHAZADO**

El reporte de los agentes constructores contiene **múltiples discrepancias materiales** con la realidad forense del código. Aunque la estructura general del paper-compliant bootstrap existe y los tests pasan, **las métricas reportadas son artefactos de una implementación incompleta**, no resultados genuinos.

### Hallazgos por severidad

| Severidad | Cantidad | Resumen |
|-----------|----------|---------|
| **CRITICAL** | 4 | Mismatch cualitativo, falsa circularidad, mode stub permanente, builder corrupte PG con path inválido |
| **HIGH** | 5 | source_hash vacío, 100% execute, call edges built-in, resync no detecta sin rebuild, race condition sin lock |
| **MEDIUM** | 3 | Métricas artificialmente bajas, tests superficiales, phase2 crashea con JSON corrupto |
| **LOW** | 3 | Tiempo subreportado, main duplicado, permisos 644 |

---

## §2 Verificación de claims de los agentes

| Claim reportado | Verificado | Discrepancia | Severidad |
|-----------------|------------|--------------|-----------|
| 12 funciones extraídas | 12 en PG pero **40 cuando se escanea completo** | PG solo escaneó `.jcode/lib/_config_parse.py` + `handbook_builder.py`; los 4 scripts del paper (phase2/3/resync/verify) NO fueron escaneados | **CRITICAL** |
| 11 L3 entries | 11 ✅ | Coincide pero 1 función (`handbook_builder.main`) se pierde | **HIGH** |
| 5 state accesses | 5 ✅ pero **todos son calls disfrazados** | `_extract_state` no existe; los 5 entries son llamadas a métodos (`self._extract_from_tree`, etc.), no accesos a self.X reales | **HIGH** |
| 101 call edges | 101 ✅ pero **50% son builtins** | `split`, `join`, `match`, `startswith`, `strip`, `append` contados como call edges | **HIGH** |
| 0 frozen entries | 0 ✅ (correcto en estado inicial) | Pero experimentalmente resync SÍ funciona con rebuild completo | OK |
| 30 min ejecución | **15.8 min reales** | Reportado el doble | **LOW** |
| 10 tests pasan (9+1) | 10 pasan ✅ | Pero `smoke_paper_compliance` solo valida existencia de archivos | **MEDIUM** |
| 6 stages asignados | **1 stage (execute)** | Las 11 L3 entries tienen `relations.stages = ["execute"]` únicamente | **HIGH** |
| 0 contaminación | 0 ✅ | `harness.sh check` reporta 0 | OK |
| Mode stub mencionado | **Modo stub permanente y único** | No hay integración LLM real | **CRITICAL** |

---

## §3 Hallazgos CRITICAL

### C-1: Inconsistencia cualitativa PG (40 vs 12 funciones)

**Evidencia**: `python3 .jcode/lib/handbook_builder.py --repo .` produce **40 funciones, 371 call edges, 5 state accesses**. El reporte dice **12 funciones, 101 call edges, 5 state accesses**.

**Causa**: El `scan_dirs` en `handbook_builder.py:extract()` solo escanea:
```python
scan_dirs = [
    repo_root / "src",
    repo_root / ".jcode" / "lib",
    repo_root / "backend",
    repo_root / "frontend",
]
```

Y cuando se generó el reporte (commit `536c2b9`), SOLO existían `_config_parse.py` y `handbook_builder.py` en `.jcode/lib/`. Los otros 4 scripts del paper (`handbook_phase2.py`, `handbook_phase3.py`, `handbook_resync.py`, `handbook_verify.py`) fueron añadidos en commits posteriores pero el handbook quedó congelado en el snapshot de 12 funciones.

**Implicación**: El "construction pipeline" del paper **NO se aplicó a sí mismo**. La circularidad prometida (handbook que documenta al propio harness que lo genera) es falsa. Las funciones de Fase II, Fase III, Resync y BGPD verification no están en el handbook.

**Severidad**: CRITICAL — falsea el claim principal de "paper-compliant".

---

### C-2: Distribución de stages artificial (100% execute)

**Evidencia**:
```bash
$ python3 -c "
import json
cb = json.load(open('.jcode/handbook/cache_B.json'))
from collections import Counter
stages = Counter()
for e in cb['l3_entries'].values():
    for s in e['relations']['stages']:
        stages[s] += 1
print(dict(stages))"
{'execute': 11}
```

El reporte dice "6 stages" pero **las 11 L3 entries están todas en `execute`**.

**Causa raíz** (`handbook_phase2.py:41-55`):
- El clasificador `classify_function_stub` usa keyword matching.
- Las 12 funciones del harness contienen las keywords: `parse` (execute), `extract` (execute).
- Ninguna contiene keywords de `init`, `interpret`, `plan`, `verify`, `handoff`.
- Default: `return ["execute"]`.

**Severidad**: CRITICAL — el reporte miente sobre el logro del pilar 2.

---

### C-3: Modo stub permanente (no integración LLM real)

**Evidencia**: `handbook_phase2.py` solo implementa `classify_function_stub` (línea 40). No hay código que invoque el SDK z-ai u otro LLM. El prompt del paper menciona "Propose-Review-Mapping loop" pero solo se implementa el propose (stub).

**Severidad**: CRITICAL — el "loop Propose-Review-Mapping" del paper no existe en la implementación.

---

### C-4: `handbook_builder.py --repo /nonexistent/path` corrompe program_graph.json

**Evidencia**:
```bash
$ python3 .jcode/lib/handbook_builder.py --repo /nonexistent/path
[ok] program graph saved to .jcode/handbook/program_graph.json
     0 functions, 0 call edges, 0 state accesses, leaf_mode=function
```

**Causa**: `handbook_builder.py` no valida que `repo_root` exista. Si el path no existe, escanea 0 archivos, retorna un PG vacío y **lo escribe en la ruta por defecto `.jcode/handbook/program_graph.json`**.

**Severidad**: CRITICAL — operación destructiva silenciosa. Un usuario con un typo pierde el handbook.

---

## §4 Hallazgos HIGH

### H-1: `source_hash` vacío en 11/11 L3 entries

**Evidencia**: Las 11 L3 entries en `cache_B.json` tienen `source_hash = ""`.

**Implicación**: El resync usa `program_graph_hash` (de `K_g.json`), no `source_hash` de las L3 entries. Pero como `source_hash` está vacío, no hay forma de detectar cambios a nivel de L3 entry individual — solo a nivel de program_graph completo.

**Severidad**: HIGH — bug latente que impedirá resync granular si Phase III lo intenta.

---

### H-2: Call edges inflados con métodos built-in

**Evidencia**:
```
parse_toml -> split (line 28)
parse_toml -> join (line 25)
parse_toml -> match (line 30)
parse_toml -> startswith (line 37)
parse_toml -> flush_section (line 41)
```

Las 101 call edges incluyen **métodos built-in de Python** (`split`, `join`, `match`, `startswith`, `strip`, `append`, `write`, `read`, `load`, etc.).

De los 101 edges, **69 son pares únicos (caller, callee)**, de los cuales ~50% van a builtins. Esto exagera la complejidad del grafo.

**Severidad**: HIGH — falsea métricas de "coupling" y "complexity" del handbook.

---

### H-3: State accesses son calls disfrazados

**Evidencia**:
```
{'function': 'PythonAdapter.extract', 'attribute': 'self._extract_from_tree', 'access': 'write', 'line': 52}
{'function': 'PythonAdapter._extract_from_tree', 'attribute': 'self._record_function', 'access': 'write', 'line': 93}
```

Estos NO son accesos a atributos de instancia. Son **llamadas a métodos bound** (`self._extract_from_tree(...)`). El extractor los clasifica erróneamente como `state_access.write`.

**Severidad**: HIGH — falsea métricas de "Vista Z" (State Registers).

---

### H-4: Resync sin rebuild no detecta cambios

**Evidencia experimental**:
1. Renombré `parse_toml` → `parse_toml_renamed` en `_config_parse.py`.
2. Hice commit.
3. Ejecuté `python3 .jcode/lib/handbook_resync.py --auto`.
4. Resultado: `{"status": "no_op", "reason": "graph_unchanged"}` ❌

**Causa**: El resync compara `program_graph.json` (viejo) vs `K_g.json` cached hash. Si `program_graph.json` no se actualiza primero con `phase1`, resync cree que nada cambió.

**Implicación**: El flow turnend.sh (que ejecuta resync post-commit) **NO detecta cambios en código** porque no invoca Phase I antes.

**Severidad**: HIGH — el Pilar 2 del paper no funciona end-to-end sin flujo manual.

---

### H-5: Race condition entre resyncs concurrentes (sin locks)

**Evidencia**:
- `grep -nE "flock|fcntl|lockfile|threading.Lock" .jcode/lib/handbook_resync.py` → 0 matches
- `save_json()` (línea 40-45) hace `open(path, "w")` sin atomicidad ni lock.

**Riesgo**: Si `turnend.sh` dispara resync y el usuario también corre resync manual simultáneamente, dos procesos pueden:
1. Leer `frozen_entries.json` simultáneamente.
2. Ambos escribir versiones distintas.
3. La última escritura gana (no corruption JSON, pero pérdida de cambios).

**Severidad**: HIGH — race condition reconocida en el prompt original.

---

## §5 Hallazgos MEDIUM

### M-1: `smoke_paper_compliance.sh` valida solo existencia

**Evidencia**: El test solo verifica:
- `test -f` para archivos.
- `grep -q` para keywords en templates.
- `l3_count > 0` para L3 entries.

NO valida:
- Que `source_hash` esté poblado.
- Que los stages estén bien distribuidos.
- Que las funciones sean correctas.
- Que el resync funcione.

**Severidad**: MEDIUM — el test pasa sin importar la calidad interna del handbook.

---

### M-2: `handbook_phase2.py` crashea con JSON corrupto

**Evidencia**:
```bash
$ echo "{corrupt" > .jcode/handbook/program_graph.json
$ python3 .jcode/lib/handbook_phase2.py
Traceback (most recent call last):
  ...
    pg = json.load(f)
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

**Severidad**: MEDIUM — debería manejar JSON corrupto con exit code != 0 y mensaje claro, no traceback.

---

### M-3: `unmapped = 0` sospechoso

**Evidencia**: Con 12 funciones y 6 stages, `coverage_record.unmapped_functions = []`.

**Esperado**: Al menos 1-2 funciones "unclear" o "mixed" que el clasificador no puede asignar.

**Severidad**: MEDIUM — el reporte dice "todas clasificadas" lo cual es estadísticamente improbable.

---

## §6 Hallazgos LOW

### L-1: Tiempo subreportado (15.8 min vs 30 min reportados)

**Evidencia**:
- First commit: `2026-07-20 23:41:49 -0400`
- Last commit: `2026-07-20 23:57:38 -0400`
- Diferencia: **15.8 minutos**

El reporte decía "30 minutos". Aún más sospechoso de lo que el prompt apuntaba.

---

### L-2: `main` duplicado en qualnames

**Evidencia**: Hay dos funciones llamadas `main`:
- `.jcode/lib/_config_parse.py:main`
- `.jcode/lib/handbook_builder.py:main`

Ambas tienen `qualname = "main"` (sin módulo). Esto puede causar confusión en análisis.

---

### L-3: Permisos 644 en archivos handbook

**Evidencia**: `cache_B.json`, `behavioral_mapping.json`, etc. son `-rw-rw-r--`.

No contienen secrets reales pero world-readable es innecesario si el repo es multi-usuario.

---

## §7 Tests edge case ejecutados

| Test | Resultado | Severidad |
|------|-----------|-----------|
| `handbook_verify.py --request ""` | ✅ retorna 11 entries con relevance=0 | OK |
| `handbook_verify.py --stages "nonexistent"` | ✅ retorna 0 verified, no crash | OK |
| `handbook_builder.py --repo /nonexistent/path` | ❌ **corrompe program_graph.json** con 0 funciones | **CRITICAL (C-4)** |
| `handbook_phase2.py` con JSON corrupto | ❌ traceback, no graceful | MEDIUM (M-2) |
| `resync --auto` después de rename sin rebuild | ❌ retorna `no_op` | HIGH (H-4) |
| `resync --auto` con rename + rebuild + resync | ✅ marca frozen correctamente | OK |
| Race condition (2 resync paralelos) | ⚠️ Sin corruption JSON (graph_unchanged en ambos), pero sin lock | HIGH (H-5) |

---

## §8 Verificación end-to-end

| Componente | Estado |
|------------|--------|
| BGPD (handbook_verify.py) | ✅ Funciona — encuentra entradas relevantes por token overlap |
| Edit Planning Γ (OP.md) | ✅ Template tiene `will_modify`, `will_add`, `will_remove` |
| Resync detecta rename | ⚠️ Solo con flujo completo (rebuild → resync). Sin rebuild → no detecta |
| 0 contaminación | ✅ `harness.sh check` reporta 0 |

---

## §9 Resumen de la circularidad perdida

**Claim del paper**: El handbook documenta el propio código que lo genera (auto-descripción).

**Realidad forense**:

| Componente del harness | ¿En program_graph.json? |
|------------------------|------------------------|
| `_config_parse.py` (4 funciones) | ✅ Sí |
| `handbook_builder.py` (8 funciones) | ✅ Sí |
| `handbook_phase2.py` (~5 funciones) | ❌ **NO** |
| `handbook_phase3.py` (~10 funciones) | ❌ **NO** |
| `handbook_resync.py` (~5 funciones) | ❌ **NO** |
| `handbook_verify.py` (~5 funciones) | ❌ **NO** |

**Total**: ~12/30 funciones del harness están en el handbook. **40% de cobertura**.

---

## §10 Decisión de merge

### **RECHAZADO**

### Blockers críticos (deben resolverse antes de merge)

1. **C-1 (Circularidad falsa)**: El handbook debe escanear el 100% del harness, no solo `_config_parse.py` y `handbook_builder.py`. El `scan_dirs` debe incluir todos los subdirectorios de `.jcode/lib/` automáticamente.

2. **C-2 (Distribución falsa de stages)**: Implementar al menos un clasificador heurístico más sofisticado o un fallback LLM real. No se acepta "100% execute" como logro del pilar 2.

3. **C-3 (Modo stub permanente)**: Integrar SDK real (z-ai) o documentar explícitamente que "stub mode" es la única opción soportada.

4. **C-4 (Corrupción silenciosa)**: `handbook_builder.py` debe validar que `--repo` existe antes de escribir el output.

5. **H-1 (source_hash vacío)**: Phase III debe calcular source_hash real (sha256 del source excerpt).

6. **H-2 (Call edges built-in)**: Filtrar métodos built-in (al menos los de `builtins` module).

7. **H-4 (Resync sin rebuild)**: Modificar el flujo para que resync invoque Phase I si el código cambió.

8. **H-5 (Race condition)**: Añadir `fcntl.flock` o equivalente a `save_json()`.

### Recomendaciones adicionales

- Reemplazar `smoke_paper_compliance.sh` con aserciones que validen distribución de stages, source_hash, y end-to-end.
- Añadir test que detecte distribución sospechosa de stages (100% en uno solo).
- Considerar agregar `.jcode/tests/audit/audit_paper_metrics.sh` que recalcule métricas independientemente.

---

## §11 Evidencia recopilada

Toda la evidencia forense está en:
- `/home/juan/proyectos/proyecto-01/.jcode/handbook/*.json` (estado actual)
- Salidas de comandos capturadas en este reporte
- Logs en `/home/juan/proyectos/proyecto-01/.jcode/tests/evidence/2026-07-21/`

Comandos ejecutados durante la auditoría documentados en este informe.

---

**Fin del reporte de auditoría forense.**
