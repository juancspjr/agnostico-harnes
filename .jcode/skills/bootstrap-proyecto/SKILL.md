# Skill: bootstrap-proyecto

Cubre los 3 gaps del harness paper-compliant para hacerlo realmente agnóstico y adaptativo a cualquier proyecto.

## Propósito

Habilita al harness para **consumir el proyecto real** en lugar de usar defaults hardcodeados. Trabaja en 3 frentes:

### Gap 1 — Stages adaptativas al dominio
En vez de `init/interpret/plan/execute/verify/handoff` fijas, lee `PDR.md` y `PROJECT.md` para detectar el dominio del proyecto y genera stages específicas. Si el proyecto aún no existe, usa defaults adaptables que se marcan como `_adaptable`.

### Gap 2 — Adapters multi-lenguaje
Framework extensible con Python como referencia. Permite registrar adaptadores para Go, TypeScript, Rust, Java. Auto-detecta el lenguaje del proyecto por extensión de archivos.

### Gap 3 — Auto-inicialización
Cuando se detecta código nuevo en `src/`, auto-genera: 
- `contamination_patterns.txt` con el nombre del proyecto
- `mcp.json` con paths relativos
- Stages desde `PDR.md §5` (flujos críticos)
- Task classes desde `PRINCIPLES.md`

## Uso

```bash
# Escanear proyecto y mostrar diagnóstico
python3 .jcode/skills/bootstrap-proyecto/lib/project_scanner.py

# Generar stages adaptadas al proyecto detectado
python3 .jcode/skills/bootstrap-proyecto/lib/stage_generator.py

# Detectar lenguaje y recomendar adapter
python3 .jcode/skills/bootstrap-proyecto/lib/language_adapter.py

# Inicializar configuración
python3 .jcode/skills/bootstrap-proyecto/lib/config_initializer.py

# Todo en un solo comando
python3 .jcode/skills/bootstrap-proyecto/lib/bootstrap_all.py
```

## Integración

Esta skill se integra con:
- `handbook_phase2.py`: reemplaza `DEFAULT_STAGES` con stages leídas del proyecto
- `handbook_builder.py`: agrega detección de lenguaje para elegir adapter
- `harness.sh`: check adicional de bootstrap

## Tests

```bash
bash .jcode/tests/bootstrap/test_all.sh     # Todos los tests (estrictos)
```

## Criterios de aprobación

- [ ] Gap 1: stages generadas desde PDR.md contienen ≥3 stages del dominio detectado
- [ ] Gap 1: si no hay proyecto, stages son `_adaptable=True`
- [ ] Gap 2: PythonAdapter es referencia; Go/TS/Rust tienen templates funcionales
- [ ] Gap 2: auto-detección de lenguaje desde extensiones funciona
- [ ] Gap 3: auto-init genera contamination_patterns.txt con nombre correcto
- [ ] Gap 3: mcp.json usa paths relativos
- [ ] Gap 3: PDR.md §5 flujos se reflejan en stages
- [ ] Anti-fraude: ningún test hardcodea valores que el agente controla
- [ ] Anti-fraude: cada test recalcula desde ground truth
