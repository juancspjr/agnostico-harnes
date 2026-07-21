---
name: orient
description: >
  Triage y auto-orientación del agente. Invocar al iniciar sesión, al recibir una nueva solicitud, o si el agente se siente perdido.
  Ejecuta un Triage objetivo, aplica el protocolo BGPD si es necesario, y garantiza trazabilidad.
---

# SKILL: ORIENT (Adaptive Triage)

> **Trigger**: El usuario ejecuta `/orient`, dice "orient", o el agente va a iniciar un loop.

## FASE 1: TRIAJE OBJETIVO (Obligatorio al recibir la tarea)

El agente DEBE clasificar la tarea usando este **árbol de decisión** SIN
excepciones. No usar "criterio propio", seguir el orden de preguntas:

### Árbol de decisión (4 preguntas en cascada)

```text
P1. ¿La tarea muta un campo de estado listado en
    `.jcode/STATE-REGISTERS.md` (o el mapa de estados del proyecto)?
    ├─ SÍ → SLICE/REMEDIATION (Flujo Riguroso, Fase 2-B)
    └─ NO → P2

P2. ¿La tarea cambia UI/UX (HTML/CSS/React/Astro) o crea
    endpoints nuevos?
    ├─ SÍ → SLICE/REMEDIATION (Flujo Riguroso, Fase 2-B)
    └─ NO → P3

P3. ¿La tarea toca > 2 archivos, o se estima > 30 min?
    ├─ SÍ → SLICE/REMEDIATION (Flujo Riguroso, Fase 2-B)
    └─ NO → P4

P4. ¿Todas las anteriores son NO?
    └─ MICROFIX (Flujo Ligero, Fase 2-A)
```

### Matriz resumen (mismo árbol, vista tabular)

| Clasificación | Trigger (cualquiera) | Flujo |
|---|---|---|
| `SLICE/REMEDIATION` | Muta estados, cambia UI, o crea endpoints | Fase 2-B (BGPD + Swarm) |
| `SLICE/REMEDIATION` | Toca > 2 archivos | Fase 2-B |
| `SLICE/REMEDIATION` | Tiempo estimado > 30 min | Fase 2-B |
| `MICROFIX` | Ninguno de los anteriores | Fase 2-A (SRSI + fix directo) |

### Reglas de promoción MICROFIX → SLICE

Si durante la ejecución del MICROFIX se descubre que:
- Aparecen sitios acoplados no anticipados (más de 1 grep adicional).
- El cambio toca un estado de BD que no estaba en el scope inicial.

**Entonces**: PROMOVER a SLICE. No continuar como MICROFIX. Esto evita
el anti-patrón "empezar ligero y terminar incompleto".

### Reglas deprecación en favor del árbol

> **Nota**: la matriz anterior de 2 filas sigue siendo válida como
> atajo mental, pero el **árbol de 4 preguntas es la fuente de verdad**.
> Cualquier discrepancia se resuelve a favor del árbol.

## FASE 2: EJECUCIÓN SEGÚN FLUJO

### 2-A. Flujo Ligero (MICROFIX)

1. **SRSI**: Hacer `grep` del patrón a cambiar. Confirmar match.
2. **Fix**: Aplicar cambio atómico.
3. **Verificación mínima**: leer el archivo modificado completo para
   confirmar coherencia (1 lectura de control).
4. **Registro Mínimo**: Appendear 1 línea en `PLAN-VIVO §6` con
   formato: `- [MICROFIX] <archivo> : <qué cambió> (commit: <hash>)`.
5. **Compliance**: Setear `srsi_done_this_turn=true` en `compliance.json`.

### 2-B. Flujo Riguroso (SLICE/REMEDIATION)

1. **BGPD (Progressive Disclosure)**:
   - **L1**: Leer `.jcode/BEHAVIOR-INDEX.md`. Identificar comportamiento B-XXX.
   - **L2**: Identificar archivos y reglas (R-N) involucradas.
   - **Z**: Leer `.jcode/STATE-REGISTERS.md` para los estados. Alistar sitios acoplados.
   - **L3**: Hacer `grep`/`rg` en los archivos para confirmar existencia.
2. **Swarm Check**: Revisar `AGENT-PROTOCOL.md §4.10`. ¿Requiere
   spawnear sub-agente? (Si toca backend+frontend, spawnear workers).
3. **Declaración**: Declarar al usuario el Comportamiento, Scope,
   Estados y Loop (L-SLICE-NNN).
4. **Fix y Verificación**: Aplicar cambios. Correr `fixed_check`. Triple
   Evidencia §30.
5. **Registro Completo**: Actualizar `PLAN-VIVO §6` (detallado) y `§8`
   (handoff).

## FASE 3: REGLA DE TRAZABILIDAD ABSOLUTA

- **PROHIBIDO** cerrar un turno sin haber escrito en `PLAN-VIVO §6` o
  `§8`, sin importar qué tan pequeña haya sido la tarea.
- Una tarea `MICROFIX` no exime de la trazabilidad. Si no se documenta,
  no se hizo (R-AA-1).

## FASE 4: RECUPERACIÓN POST-COMPRESIÓN DE CONTEXTO

**Solo activar cuando el agente detecte señales explícitas de resumen**
(`"Previously..."`, `"Resumen de la conversación anterior"`, `"Earlier
turns were summarized"`, o cuando el system prompt indique truncación).

### Procedimiento de re-anclaje

1. **Detección**: leer el system prompt o el último mensaje del usuario
   buscando marcadores de compresión (`summary`, `resumen`, `truncated`,
   `compacted`, `tokens exceeded`).
2. **Re-fetch selectivo** (no recargar todo):
   - `.jcode/BEHAVIOR-INDEX.md` y `.jcode/STATE-REGISTERS.md` (mapas).
   - `AGENTS.md §1-§3` (reglas R-N vigentes).
   - `.jcode/iterations/PLAN-VIVO.md §8` (últimas 5 entradas para
     recuperar contexto del loop activo).
3. **Re-declaración interna**: antes de proseguir, el agente debe
   escribir internamente:
   > "Re-anclaje post-compresión: B-XXX activo, estado Z-YYY, R-N
   > vigentes: [lista]. Continúo desde: [punto exacto]."
4. **Continuidad sin interrupciones**: NO pedirle al usuario que repita
   la tarea. NO re-declarar el sprint completo. Solo continuar.

### Anti-patrones Fase 4

- ❌ Detectar compresión cuando NO existe (asumir que hubo resumen sin
  marcador).
- ❌ Re-cargar TODO el proyecto (desperdicio de tokens — usar fetches
  selectivos).
- ❌ Pedirle al usuario que repita el contexto que YA estaba en el turno
  anterior (rompe la ilusión de continuidad).
- ❌ Omitir el re-anclaje y continuar "como si nada" (causa alucinaciones
  sobre decisiones que ya se tomaron).

### Cuándo NO aplicar

> **Observación**: esta sección documenta los casos donde el
> procedimiento de re-anclaje sería contraproducente. Cada caso debe
> poder identificarse sin ambigüedad — si duda, **es mejor re-anclar
> que omitir** (costo asimétrico: omitir causa bugs, re-anclar causa
> 4-6 fetches extra).

| # | Caso | Razón de NO aplicar | Acción alternativa |
|---|---|---|---|
| 1 | NO hay marcadores de compresión en el system prompt ni en el contexto reciente. | No hay compresión real que recuperar. | Proceder normalmente con Fase 1. |
| 2 | El resumen provino de un `clear` o reinicio de sesión **solicitado por el usuario** (no es compresión automática). | El usuario quiere un nuevo inicio deliberado; re-anclar arrastra información que él descartó. | Tratar como tarea nueva: ejecutar Fase 1 desde cero. |
| 3 | La compresión ocurrió en un sub-agente (`swarm_spawn_mode`) y el contexto perdido es del CHILD, no del COORDINATOR. | El coordinator no tiene visibilidad del child context; re-fetch selectivo del coordinator es inútil. | Pedir al child un "context dump" o un `report` formal con su estado. |
| 4 | El usuario pidió explícitamente "olvida lo anterior" o "asume que no sabes nada". | Es un override humano deliberado; respetarlo. | Confirmar disponibilidad de re-fetch selectivo si el usuario lo pide después, pero no hacerlo proactivamente. |

### Anti-patrón general

- ❌ Usar Flujo Riguroso para un MICROFIX (desperdicio de tokens y tiempo).
- ❌ Usar Flujo Ligero para un SLICE (omite acoplamiento y causa bugs).
- ❌ Omitir la Fase 3 (rompe trazabilidad).
- ❌ Clasificar como MICROFIX "para ser eficiente" cuando el árbol de
  decisión indica SLICE (sesgo de optimización prematura).
- ❌ Omitir el paso "Verificación mínima" de Fase 2-A (1 lectura de
  control basta para evitar fixes tontos).
- ❌ Promover MICROFIX a SLICE y seguir tratando el trabajo como ligero
  (la promoción invalida el plan original).
- ❌ Confundir "NO hay marcadores de compresión" con "tarea fuera del
  sprint activo" — son cosas distintas: la primera NO activa Fase 4, la
  segunda SÍ puede requerir re-anclaje.

## INTEGRACIÓN DE FASES (matriz de decisión final)

```text
¿Recibí tarea nueva?
├─ NO → ¿Detecté marcadores de compresión? → SÍ → ejecutar Fase 4.
│                                        └─ NO → idle (esperar).
└─ SÍ → ejecutar Fase 1 (árbol de decisión).
        ├─ MICROFIX → ejecutar Fase 2-A + Fase 3.
        └─ SLICE   → ejecutar Fase 2-B + Fase 3.
```

Toda tarea (sin importar tamaño) que complete su flujo debe haber
dejado **al menos 1 línea** en `PLAN-VIVO §6`.
