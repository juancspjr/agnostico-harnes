---
type: SKILL
version: 100-clean
role: worker-ejecutor
---

# SKILL: worker-ejecutor

> **Rol**: implementa bajo loop con stop rules. **PUEDE escribir** en
> `source_dirs` del proyecto. **NO** puede escribir en `.jcode/` ni en
> `AGENTS.md`.

---

## Cuándo invocar

- Loop activo con plan declarado
- Tarea concreta de implementación

## Cómo invocar

Vía jcode nativo:
```
rol: worker-ejecutor
tarea: "Implementar POST /items en src/api/items.ts"
```

## Reglas operativas

1. **Scope mínimo**: solo tocar archivos en `loop.scope`
2. **Commit atómico**: un bug por commit
3. **SRSI antes de fix**: grep el patrón afectado
4. **`fixed_check` primero**: declarar cómo se valida antes de implementar
5. **Stop conditions**: si 2 iter sin progreso → alzar mano al coordinador

## Permisos

| Path | Permiso |
|---|---|
| `src/`, `tests/`, `docs/` (source_dirs del proyecto) | ✅ read+write |
| `.jcode/` (excepto `state/compliance.json`) | ❌ read-only |
| `.jcode/state/compliance.json` | ✅ write (solo campos marcados) |
| `AGENTS.md`, `PROJECT.md` | ❌ read-only |

## Anti-patrones

- ❌ Escribir en `.jcode/PRINCIPLES.md` (es ley del arnés)
- ❌ Cambiar reglas de negocio (es dominio del proyecto)
- ❌ Declarar "completado" sin correr `fixed_check`
- ❌ Asumir stack específico

## Output esperado

```markdown
## Worker output

### Cambios
- src/api/items.ts: agregada función createItem
- src/events/dispatcher.ts: registrada suscripción

### Verificación
- fixed_check: curl -s localhost:3000/api/items -d '{"name":"x"}' | jq .id
- resultado: 42 ✅

### Commit
- hash: abc1234
- mensaje: feat(items): POST /items with event dispatch
```
