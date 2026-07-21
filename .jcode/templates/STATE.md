# STATE.md — Plantilla de snapshot de estado

> Copiar a `.jcode/iterations/STATE/H-STATE-{N}-v{NNN}-{YYYY-MM-DD}-{slug}.md`

---

```markdown
---
type: STATE
version: 001
date: YYYY-MM-DD
title: <título del snapshot>
loop_id: L-{TYPE}-{NNN}
---

# STATE — <título>

## Estado actual
- Loop activo: <id>
- Iteración: <N>/<budget>
- Score: <N>/100
- Strikes: <N>

## Loops activos
- L-XXX-001 — <descripción> — started <ts>
- L-XXX-002 — <descripción> — started <ts>

## Loops cerrados (últimos 5)
- L-XXX-000 — <descripción> — closed <ts> — success
- ...

## Bloqueos pendientes
- <descripción del bloqueo> — <dependencia externa>

## Handoff
- Próximo turno: <descripción>
- Artefacto: <commit hash / archivo>
```
