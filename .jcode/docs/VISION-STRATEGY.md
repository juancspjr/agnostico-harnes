# VISION-STRATEGY — Estrategia de visión del arnés (agnóstica)

> **Documento canónico del arnés**. Define cuándo usar cada herramienta
> de visión para optimizar el trade-off cobertura/tokens.
>
> **Aplicable a cualquier proyecto** que use el arnés v100-clean.

---

## §1 Stack de visión del arnés v100-clean

| # | Herramienta | Cuándo | Costo (tokens) | Server/CLI |
|---|-------------|--------|----------------|------------|
| 1 | **`@playwright/cli`** | One-off desde terminal con sesión nombrada | Bajo (stdout only) | `playwright-cli -s=<name> ...` |
| 2 | **`cdp-browser-mcp`** | Multi-step flow dentro del arnés con sesión persistente | ~3.8k full-page | `cdp_navigate`, `cdp_click <ref>` |
| 3 | **`@playwright/test`** | E2E suite en CI, smoke tests formales | bajo en CI, alto en dev | `pnpm test:e2e` |

---

## §2 Regla de oro

> **Cuando el arnés necesita validar UI multi-step dentro del mismo
> loop**, usar `cdp-browser-mcp` (4x menos tokens que
> `@playwright/mcp`). Para verificación one-off desde terminal, la
> CLI agente es `playwright-cli` del paquete `@playwright/cli`. Para
> tests E2E formales en CI, `@playwright/test`.

---

## §3 Por qué no `@playwright/mcp`

`@playwright/mcp` produce un YAML `ariaSnapshot` que es **3-5x más
verboso** que el formato compact indexed de `cdp-browser-mcp`. Para
un agente que hace 10+ snapshots por turno, la diferencia es de
**~15k tokens por loop**.

`cdp-browser-mcp` usa la **Accessibility API nativa de Chrome** vía
CDP, sin inyectar JS. Esto le da snapshots más compactos y
representativos del estado real.

---

## §4 Setup único (one-time por máquina)

```bash
# 1. Instalar la CLI global
pnpm add -g @playwright/cli@latest

# 2. Instalar Chromium (solo si no lo tenés)
playwright-cli install-browser chromium

# 3. Levantar Chrome con CDP habilitado
bash bin/start-cdp-chrome.sh
# Espera: "[start-cdp-chrome] OK: CDP up at http://127.0.0.1:9224"

# 4. Verificar
curl http://127.0.0.1:9224/json/version
```

---

## §5 Anti-patrones (PROHIBIDO)

- ❌ Usar `@playwright/mcp` para flujos multi-step dentro del arnés.
  Es 3-5x más caro y no justifica la diferencia.
- ❌ Usar `chrome-devtools-mcp` para snapshots frecuentes. Su AX tree
  verbose también es costoso.
- ❌ Re-snapshot después de cada click si nada visible cambió.
  Usar `cdp_evaluate` para verificar estado pequeño.
- ❌ Usar `cdp_screenshot` para verificación. El snapshot ARIA es
  text-searchable y ~10x más compacto que un PNG.
- ❌ Dejar Chrome CDP huérfano. Cerrar con `bash bin/stop-cdp-chrome.sh`
  al terminar.

---

## §6 Stack awareness

El arnés v100-clean viene con `cdp-browser` ya configurado en
`.jcode/mcp.json`. Los servidores `playwright`, `semble` y `repomix`
vienen con `disabled: true` para evitar auto-conexión silenciosa.

Si querés habilitarlos manualmente, edita `.jcode/mcp.json`:

```json
{
  "playwright": {
    ...
    "disabled": false
  }
}
```

---

## §7 Métricas de costo

| Acción | Tokens | Notas |
|---|---|---|
| `cdp_navigate` (página completa) | ~3.8k | Snap inicial |
| `cdp_snapshot` | ~3.8k | Re-snap tras cambio grande |
| `cdp_evaluate` (1 línea) | ~50 | Verificar estado pequeño |
| `cdp_click` | ~10 | Click por ref |
| `cdp_type` | ~20 | Escribir por ref |
| `cdp_screenshot` PNG | ~50k+ | Solo evidencia, no verificación |
| `@playwright/mcp` navigate | ~17.4k | 4.6x más caro |
| `chrome-devtools-mcp` navigate | ~10.9k | 2.9x más caro |

---

## §8 Verificación reproducible

Después de cualquier edición a `.jcode/mcp.json`, correr:

```bash
bash .jcode/tests/smoke/smoke_vision_strategy.sh
```

Esperado: `12 PASS, 0 FAIL` (o la versión actualizada del smoke).

---

## §9 Context caching (complemento)

Para optimizar más allá de la elección de herramienta, ver
`.jcode/skills/context-caching/SKILL.md` — describe cómo cachear
snapshots entre turnos del agente para no repetir fetches.

---

## Versión

- **v001-agnostic** (2026-07-21): Versión agnóstica de la estrategia
  de visión. Aplica a cualquier proyecto que use el arnés v100-clean.