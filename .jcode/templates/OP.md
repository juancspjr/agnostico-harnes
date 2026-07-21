# OP.md — Plantilla de runbook operativo

> Copiar a `.jcode/iterations/OP/H-OP-{N}-v{NNN}-{YYYY-MM-DD}-{slug}.md`

---

```markdown
---
type: OP
version: 001
date: YYYY-MM-DD
title: <título del runbook>
loop_id: L-{TYPE}-{NNN}
---

# OP — <título>

## Contexto
<por qué existe este runbook>

## Pre-condiciones
- <condición 1>
- <condición 2>

## Pasos

1. <paso 1>
2. <paso 2>
3. <paso 3>

## Post-condiciones
- <condición verificable 1>
- <condición verificable 2>

## Rollback
<cómo revertir si algo falla>

## Handoff
- Próximo loop: <id>
- Artefacto: <commit hash / archivo>
```
