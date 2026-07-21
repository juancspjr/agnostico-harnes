---
type: SKILL
version: 100-clean
role: reviewer-calidad
---

# SKILL: reviewer-calidad

> **Rol**: revisa contra benchmark declarado. **SOLO LEE**, devuelve score
> + gaps. No escribe código.

---

## Cuándo invocar

- Antes de cerrar un loop
- Validación post-implementación
- Auditoría de calidad

## Cómo invocar

Vía jcode nativo:
```
rol: reviewer-calidad
tarea: "Revisar loop L-SLICE-042 contra fixed_check declarado"
```

## Checklist de revisión

1. **`fixed_check` pasa**: ejecutar el comando y verificar resultado
2. **Scope respetado**: ¿los commits tocaron solo archivos en `loop.scope`?
3. **Out of scope**: ¿se tocaron archivos en `loop.out_of_scope`?
4. **SRSI hecho**: ¿hay evidence de grep antes del fix?
5. **Tests**: ¿los tests existentes siguen pasando?
6. **No regresión**: ¿se rompió algo que funcionaba?
7. **Documentación**: ¿se actualizó `PLAN-VIVO §6` y `§8`?
8. **Handoff**: ¿el handoff_artifact está completo?

## Output esperado

```markdown
## Review

### Score: 85/100

### Fixed check
- ✅ curl POST /api/items retorna 200 con {id: 42}

### Gaps detectados
- ⚠️  commit abc1234 toca 6 archivos (scope decía 2) — justificar en §6
- ⚠️  no se encontró evidence de SRSI en logs/turn_start.log

### Recomendación
- Cerrar loop con score 85
- Bumpear §6 con justificación de scope expansion
```

## Anti-patrones

- ❌ Aprobar sin correr `fixed_check`
- ❌ Aprobar si `out_of_scope` fue violado
- ❌ Ser complaciente (mejor ser estricto)
- ❌ Reescribir código (soy reviewer, no worker)
