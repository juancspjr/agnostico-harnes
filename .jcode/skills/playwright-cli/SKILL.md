---
name: playwright-cli
description: Token-efficient terminal browser automation via the `playwright-cli` executable from @playwright/cli. Pair it with cdp-browser-mcp for multi-step flows inside Jcode.
when_to_use:
  - "I need to verify a single page renders correctly"
  - "I need to capture a screenshot for evidence"
  - "I need to interact with the page outside an MCP session"
  - "I need a named terminal browser session outside MCP"
prereqs:
  - "pnpm install -g @playwright/cli"
  - "The playwright-cli launcher is available on PATH"
token_efficiency: "CLI commands produce compact output (refs, ARIA). Pair with cdp-browser-mcp for ARIA snapshots inside MCP sessions."
---

# Skill: Playwright CLI

The official Microsoft Playwright CLI, distributed as `@playwright/cli` on npm, is purpose-built for AI coding agents (early 2026). It provides token-efficient browser control through concise commands.

## Why this skill exists

For project automation we have **two complementary tools**:

| Tool | When to use | Token cost |
|------|------------|------------|
| `playwright-cli` (`@playwright/cli`) | terminal snapshots, screenshots, click/type | Minimal stdout |
| `cdp-browser-mcp` (MCP) | multi-step flows inside the harness with persistent session | ~3.8k tokens for full-page snapshot |

This skill covers the CLI. The MCP counterpart lives in `cdp-browser-mcp/SKILL.md`.

## Setup (one-time)

```bash
# Install CLI globally
export PNPM_HOME="/home/juan/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
pnpm add -g @playwright/cli@latest

# Install Chromium for the agent CLI if needed
playwright-cli install-browser chromium
```

Verify:
```bash
playwright-cli --version
# Expected in the verified environment: 0.1.17 or newer
```

On this machine, `/home/juan/.local/bin/playwright` is a separate Python CLI.
It is not evidence that `@playwright/cli` is available. The stable agent path is
`/home/juan/.local/bin/playwright-cli`, implemented as a wrapper around
`/home/juan/.local/share/pnpm/playwright-cli`. Do not use a symlink because the
pnpm launcher resolves modules relative to `$0`.

## Core patterns

### Pattern 1 — Screenshot for evidence

```bash
session=evidence
playwright-cli -s="$session" open http://localhost:8082/<ruta-del-proyecto>/<id>
playwright-cli -s="$session" screenshot \
  --filename docs/screenshots/e2e/<name>.png --full-page
playwright-cli -s="$session" close
```

### Pattern 2 — Navigate + snapshot for inspection

```bash
session=inspect
playwright-cli -s="$session" open http://localhost:8082/admin
# Outputs: refs like [ref=e15] for every interactive element
# Then:
playwright-cli -s="$session" snapshot
playwright-cli -s="$session" click e15
playwright-cli -s="$session" fill e42 "search query"
```

### Pattern 3 — Codegen uses the separate base CLI

```bash
playwright codegen http://localhost:8082/login
# Opens browser + inspector; your actions are recorded as Playwright code
```

### Pattern 4 — Headless terminal smoke

```bash
session=health
playwright-cli -s="$session" open http://localhost:8081/health
playwright-cli -s="$session" snapshot
playwright-cli -s="$session" close
```

## Snapshot-and-act pattern (most token-efficient)

```bash
# 1. Open and snapshot to get refs
playwright-cli -s=solicitud open http://localhost:8082/solicitud
playwright-cli -s=solicitud snapshot

# 2. Use refs in subsequent calls
playwright-cli -s=solicitud click <ref-from-step-1>
playwright-cli -s=solicitud fill <ref-from-step-1> "iPhone 13 pantalla rota"
playwright-cli -s=solicitud press Tab
```

Output is compact, includes refs for every interactive element.

## Token efficiency tips

1. **Always use `snapshot` first** instead of `screenshot` — ARIA tree is ~10x smaller than PNG.
2. **Pass `--full-page`** only when you need it; viewport screenshots are ~3x smaller.
3. **Avoid `codegen` output in agent context**. Pipe it to a file and reference the path.
4. **For multi-page flows**, prefer the MCP server (`cdp-browser-mcp`) which keeps a persistent browser session and avoids repeated context loading.

## Integration with project pipeline

| Stage | Tool |
|-------|------|
| Dev: spot-check UI | `playwright-cli -s=<name> open` then `screenshot` |
| Dev: interact with form | `playwright-cli snapshot` then `click/fill` |
| E2E test (CI) | Playwright Test runner (`@playwright/test`, not CLI) |
| Agent verification (in-loop) | `cdp-browser-mcp` MCP tools |
| Final QA evidence (§30 triple) | `playwright-cli screenshot --filename ...` |

## Common pitfalls

- ❌ Don't pass user data via CLI args — leaks into shell history.
- ❌ Do not treat `playwright --version` as the agent CLI version.
- ❌ Do not commit `.playwright-cli/` session artifacts.
- ✅ Use named sessions and close them after terminal verification.

## See also

- `cdp-browser-mcp/SKILL.md` — MCP counterpart for in-harness flows
- `context-caching/SKILL.md` — how to cache repeated snapshots across turns
- `/opt/google/chrome/chrome` — system Chrome binary (used by both tools via different paths)
