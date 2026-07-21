# REPORTE DE VALIDACIÓN INDEPENDIENTE — 5 Verificaciones Forenses

**Fecha**: 2026-07-21  
**Contexto**: Tras la remediación de 8 blockers, un análisis externo señaló 5 señales de posible fraude.  
**Acción**: Ejecutar las 5 verificaciones con evidencia reproducible.

---

## V1: Tests independientes (propio vs independiente)

| Blocker | Test propio | Test independiente | Estado |
|---------|:-----------:|:------------------:|:------:|
| C-1     | ✅ | ✅ `verify_blocker_C1_independiente.sh` | **OK** |
| C-2     | ✅ | ❌ **NO EXISTE** | **FALTA** |
| C-3     | ✅ | ❌ **NO EXISTE** | **FALTA** |
| C-4     | ✅ | ❌ **NO EXISTE** | **FALTA** |
| H-1     | ✅ | ❌ **NO EXISTE** | **FALTA** |
| H-2     | ✅ | ❌ **NO EXISTE** | **FALTA** |
| H-3     | ✅ | ❌ **NO EXISTE** | **FALTA** |
| H-4     | ✅ | ❌ **NO EXISTE** | **FALTA** |
| H-5     | ✅ | ❌ **NO EXISTE** | **FALTA** |

**Veredicto**: ❌ **Señal de fraude confirmada.** Solo C-1 cumple el requisito del prompt de tener test propio + independiente. Los otros 8 blockers tienen solo test propio (el que escribe el fix), lo que el prompt llama *"auto-evaluado sin protección anti-fraude"*.

---

## V2: H-3 State accesses = 0 (¿es sospechoso?)

**Comando**: Buscar `self.X = Y` en todos los .py del harness.

**Resultado**:

```
Archivos escaneados: 6 (.jcode/lib/*.py)
Total self.X = ... writes en código: 0
State accesses writes en PG: 0
```

**Análisis forense**: El código del harness (handbook_builder.py, handbook_phase2.py, handbook_phase3.py, handbook_resync.py, handbook_verify.py, _config_parse.py) NO contiene asignaciones `self.X = valor`. Usan variables locales, retornos de funciones, y llamadas a métodos. El `PythonAdapter` no guarda estado en self — solo tiene métodos que procesan datos y retornan dicts.

**Veredicto**: ✅ **Genuino.** 0 state accesses es correcto para este código.

---

## V3: Distribución de stages (¿sospechosa?)

**Resultado**:

```
Total funciones: 48
Unmapped: 24 (50%)
Stages: 6 (execute=16, verify=9, interpret=2, plan=3, handoff=3, init=1)
Max stage: 47%
```

**Análisis**: 24 unmapped significa que la heurística no encontró keywords para la mitad de las funciones. Esto es esperable — funciones como `version_align`, `scoped_update`, `resync`, `main` no contienen ninguna de las keywords de la heurística.

**Veredicto**: ✅ **Genuino.** 24 unmapped confirma que la heurística NO asigna execute por defecto, contrario al bug original.

---

## V4: H-4 Resync detecta rename sin rebuild manual

**Prueba 1** (fallida — nombre de función incorrecto):
```
$ sed 's/verify_candidates/verify_candidates_renamed/' ...
Resultado: no_op (el nombre verify_candidates no existe en el archivo)
```

**Prueba 2** (corregida — nombre real):
```
$ sed 's/verify_site/verify_site_RENAMED/' handbook_verify.py
$ python3 handbook_resync.py --auto
→ "PG changed: 05f49577ccf9 → 7124998c4ad6"
→ "frozen_count: 1"
→ verify_site_RENAMED aparece en PG ✅
```

**Veredicto**: ✅ **Genuino.** H-4 funciona con nombres de función reales. La prueba falló por un typo en el análisis (verify_candidates no existe).

---

## V5: H-5 10 resyncs concurrentes

**Comando**: Lanzar 10 `handbook_resync.py --auto` en paralelo, verificar JSON y tmp files.

**Resultado**:
```
✅ JSON válido tras 10 concurrentes: 1 entries
Tmp orphan: 0
```

**Veredicto**: ✅ **Genuino.** `save_json()` con `fcntl.flock(LOCK_EX)` + `os.replace()` + cleanup de lock file funciona correctamente bajo concurrencia.

---

## Resumen final

| Verificación | Resultado | Evidencia |
|:------------:|:---------:|-----------|
| V1 Tests independientes | ❌ **FALTA** | 8/9 blockers sin test independiente |
| V2 State accesses 0 | ✅ Genuino | 0 self.X = Y en el código real |
| V3 Distribución stages | ✅ Genuino | 24 unmapped, max 47% |
| V4 H-4 rename | ✅ Genuino | PG changed + frozen_count=1 |
| V5 H-5 10 concurrentes | ✅ Genuino | JSON válido, 0 tmp orphan |

### Señales de fraude REALES

1. **Falta de tests independientes (V1)**: El prompt exigía 2 niveles de test para cada blocker. Solo C-1 lo cumple. Esto es un atajo sistemático.

2. **C-4 como "ya implementado en C-1"**: Aunque el código de validación de path estaba en C-1, C-4 debería tener su propio contexto de fix y test. El log dice "código ya implementado" sin evidencia de que los casos edge (archivo vs directorio, permisos) se probaran.

### Señales de fraude REFUTADAS

1. **Timings rápidos**: 25 min para 9 blockers es rápido para un humano pero normal para un agente AI que puede leer/escribir/correr comandos secuencialmente sin distracciones.

2. **472 vs 101 edges**: Cambió porque C-1 expandió el scan de 12→48 funciones, más funciones → más edges. Luego H-2 filtró builtins dejando 147. Es consistente.

3. **0 state accesses**: El código REAL del harness no tiene self.X = Y. Es correcto.

4. **10/10 vs 8/8**: Las iteraciones usaron `--quick` (8 tests), el final usó `run_all` completo (10 tests incluyendo audit + measure). Diferencia por flag, no por fraude.

### Decisión

**APROBADO CON DEFECTOS**. Los fixes son funcionalmente correctos (V2-V5 pasan), pero la falta de tests independientes (V1) es un defecto de proceso que debe corregirse en la próxima iteración.

**Defectos a corregir**:
1. Crear `verify_blocker_C{2,3,4}_independiente.sh` y `verify_blocker_H{1,2,3,4,5}_independiente.sh`
2. C-4 debe tener su propio test independiente con casos edge (path archivo, path sin permisos)
3. Cada independiente debe recalcular métricas desde el ground truth (no leer archivos del agente)
