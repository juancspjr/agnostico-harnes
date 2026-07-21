---
type: SKILL
version: 100-clean
role: guardrails
---

# SKILL: guardrails

> **Rol**: audita portables vs dominio. Verifica que el arnés `.jcode/`
> sea agnóstico y que el proyecto no contamine al arnés.

---

## Cuándo invocar

- Antes de sincronizar arnés entre repos
- Post-refactor del arnés
- Sospecha de contaminación

## Cómo invocar

Vía jcode nativo:
```
rol: guardrails
tarea: "Auditar .jcode/ en busca de contaminación de proyecto"
```

## Patrones prohibidos en `.jcode/`

El arnés NO debe contener:

1. **Paths absolutos**: `/home/...`, `/Users/...`, `/run/user/...`
2. **Nombres de proyecto específicos**: cualquier string que parezca nombre de dominio concreto
3. **Contraseñas, usuarios, emails**: `admin@`, `password`, `secret`
4. **Tablas DB específicas**: nombres de tablas concretas del dominio (ej `<tabla_dominio>`)
5. **Migraciones específicas**: archivos `<NNN>_<verbo>_<entidad>.sql` concretos
6. **Endpoints específicos**: rutas como `/api/<recurso>/...` del dominio
7. **Stack lock-in**: rutas como `*/backend/internal/*.go`, `*/frontend/src/*` (asume un stack)
8. **Referencias a otros runtimes**: `.claude/`, `subagent_type=oracle`

## Comando canónico

```bash
bash .jcode/lib/harness.sh check
```

Este comando corre el detector de contaminación. Debe retornar **0
contaminación detectada**.

## Output esperado

```markdown
## Guardrails audit

### Contaminación
- ✅ 0 archivos con strings de proyecto
- ✅ 0 paths absolutos
- ✅ 0 contraseñas/usuarios

### Integrity
- ✅ 4 hooks presentes y ejecutables
- ✅ 3 libs presentes
- ✅ 6 skills presentes
- ✅ mcp.json válido (sin claves duplicadas)
- ✅ config.toml parseable

### Veredicto
APROBADO — arnés agnóstico.
```

## Anti-patrones

- ❌ Aprobar con cualquier contaminación detectada
- ❌ No verificar duplicados en JSON
- ❌ Aprobar si `harness.sh check` retorna ≠ 0
- ❌ Ignorar warnings de paths absolutos

## Si se detecta contaminación

1. **NO sincronizar** el arnés a otros repos
2. Reportar el archivo y línea específicos
3. Mover el contenido al proyecto (`AGENTS.md`, `PROJECT.md`, o `docs/`)
4. Re-correr `harness.sh check` hasta obtener 0
