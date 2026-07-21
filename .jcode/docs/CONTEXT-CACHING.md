# CONTEXT-CACHING — Estrategia de cache para el arnés (agnóstica)

> **Documento canónico del arnés**. Complementa
> `.jcode/skills/context-caching/SKILL.md` con implementación detallada.

---

## §1 El problema

En un sprint típico, un agente hace:

```
Turn 1: cdp_navigate /admin/<recurso>/123  → 3.8k tokens (full page)
Turn 2: cdp_click "Edit"
Turn 3: cdp_snapshot                    → 3.8k tokens (page re-rendered)
Turn 4: cdp_click "Save"
Turn 5: cdp_snapshot                    → 3.8k tokens
```

Eso son **11.4k tokens solo para contexto del browser** en 5 turnos,
incluso cuando cada snapshot es casi idéntico excepto por unos refs.

---

## §2 Patrón 1 — Diff snapshots en vez de re-fetchear

Después de cada interacción, en vez de `cdp_snapshot` (full), hacer:

```bash
cdp_evaluate "() => document.body.innerText.length"
```

Si el resultado cambió significativamente → re-snapshot.
Si no → reusar snapshot anterior con nota: "estado sin cambios desde turn N".

---

## §3 Patrón 2 — Pinear refs específicos

Una vez que tenés un snapshot, pinear refs en working memory:

```
Refs (estables para el snapshot actual):
  e15: button "Confirmar entrega"
  e42: input "amount"
  e87: tab "Trabajo"
```

Re-snapshotear solo cuando la estructura DOM cambia (raro durante
una interacción simple de formulario).

---

## §4 Patrón 3 — Hash y reuso

Para archivos: calcular SHA antes de re-leer:

```bash
sha=$(sha256sum file.ts | cut -d' ' -f1)
# leer solo si el hash difiere del último turno
```

---

## §5 Patrón 4 — Cache en 3 capas

| Capa | Qué | TTL | Herramienta |
|------|-----|-----|-------------|
| L1 | Single turn | Solo este turn | working memory |
| L2 | Session | Hasta cerrar browser | `cdp_snapshot` output |
| L3 | Disk | Hasta que cambie el archivo | `sha256sum` + git status |

Cuando podés responder desde L1 (ej "está visible el botón?" desde
un ref pineado), no ir a L2. Cuando L2 está stale, refrescarlo.
Cuando L3 cambia, invalidar L2.

---

## §6 Patrón 5 — Validación chunked

Para flujos largos, hacer **validación incremental**:

```
1. Navigate + snapshot          → full cost (3.8k)
2. Action 1 (small delta)      → cost 0
3. Validate via cdp_evaluate   → cost ~50
4. Action 2 (small delta)      → cost 0
5. Validate via cdp_evaluate   → cost ~50
```

Total: ~4k en vez de 4 × 3.8k = 15k.

---

## §7 Reglas operativas

1. **Siempre pinear refs después del primer snapshot** — nunca
   re-snapshotear para encontrar un elemento.
2. **Usar `cdp_evaluate` para aserciones** (`document.querySelectorAll('.btn-save').length > 0`).
3. **Cachear contenido de archivos por hash** — si leíste un archivo 5
   veces en 5 turnos, leerlo solo una vez.
4. **Levantar Chrome CDP una vez por sesión** — no reiniciar entre turnos.
5. **Combinar con grep/agentgrep** — grep es más barato que read para
   patterns conocidos.

---

## §8 Anti-patrones (PROHIBIDO)

- ❌ `cdp_snapshot` después de cada click → waste 3k+ tokens per turn
- ❌ Re-leer el mismo archivo de 500 líneas entre turnos → usar
  working memory
- ❌ `cat file | jq` repetidamente → parsear una vez, guardar objeto
- ❌ Re-correr `build` → solo en cambios reales de código
- ❌ Usar `cdp_screenshot` para verificación visual → el snapshot
  ARIA es text-searchable y 10x más compacto

---

## §9 Métricas de ahorro

| Patrón | Ahorro típico |
|---|---|
| Diff snapshots | 50-70% en flujos de 5+ turnos |
| Pin refs | 30-50% en formularios |
| Hash files | 40-60% en sesiones de lectura |
| Chunked validation | 60-75% en flujos largos |

> Stack target: 30-60% ahorro total en sesiones multi-turno.

---

## §10 Referencias

- `.jcode/skills/context-caching/SKILL.md` — Skill formal del arnés
- `.jcode/skills/cdp-browser-mcp/SKILL.md` — Skill de browser MCP
- `.jcode/skills/playwright-cli/SKILL.md` — Skill de CLI
- `.jcode/docs/VISION-STRATEGY.md` — Estrategia general de visión

---

## Versión

- **v001-agnostic** (2026-07-21): Versión agnóstica del documento de
  context-caching. Aplica a cualquier proyecto que use el arnés.