---
name: cdp-browser-mcp
description: MCP server for browser automation via Chrome DevTools Protocol (echo-lumen). Uses Chrome's native Accessibility API instead of injected JS. 4x fewer tokens than @playwright/mcp. Returns the FULL PAGE in a single compact snapshot. Project override disables `@playwright/mcp`, `semble`, and `repomix` so cdp-browser is the active browser MCP.
when_to_use:
  - "I need to drive the browser inside an MCP session"
  - "I need to verify a UI change in the harness"
  - "I need persistent browser state across multiple agent actions"
  - "I need accessibility tree (refs) for click/type sequences"
token_efficiency: "~3,800 tokens for full-page snapshot vs ~17,400 for @playwright/mcp (4.6x better)"
overrides:
  - "Declared in .jcode/mcp.json with shared:false"
  - "playwright / semble / repomix disabled locally to avoid silent autoconnect"
---

# Skill: cdp-browser-mcp

The token-efficient replacement for `@playwright/mcp` and `chrome-devtools-mcp`. Built on top of `browser-autopilot` which reads Chrome's native Accessibility tree via CDP and compresses it into a compact indexed format.

## Why this skill exists

Agents validating UI changes with the triple-evidence pattern (§30) need to balance coverage with token cost. Default MCP servers are expensive:

| Server | Full page tokens | Notes |
|--------|------------------|------|
| `chrome-devtools-mcp` | ~10,900 | Verbose AX tree format |
| **cdp-browser-mcp** | **~3,800** | Compact indexed, 4x cheaper |
| `@playwright/mcp` | ~17,400 | YAML ariaSnapshot, verbose; disabled locally |

Jcode v0.51.1 merges MCP configurations by server name. Project overrides in
`.jcode/mcp.json` disable the global copies of `playwright`, `semble`, and
`repomix`, leaving `filesystem`, `sequential-thinking`, and `cdp-browser` as
the only auto-connected servers.

## Setup (one-time)

### 1. Install the server

```bash
git clone --depth 1 https://github.com/echo-lumen/cdp-browser-mcp.git \
  /home/juan/.local/tools/cdp-browser-mcp
cd /home/juan/.local/tools/cdp-browser-mcp
pnpm install
```

### 2. Start Chrome with CDP enabled

The harness bundles a launcher script:

```bash
bash bin/start-cdp-chrome.sh
# Expected: [start-cdp-chrome] OK: CDP up at http://127.0.0.1:9224
```

Or manually:

```bash
google-chrome --headless=new --disable-gpu --no-sandbox \
  --remote-debugging-port=9224 \
  --user-data-dir=/tmp/chrome-cdp-profile \
  "about:blank" </dev/null &
```

### 3. Register in MCP config

Already done in `.jcode/mcp.json` under server name `cdp-browser`. Note the
absolute Chrome DevTools URL and the `shared:false` flag that keeps the server
session-owned:

```json
{
  "cdp-browser": {
    "command": "node",
    "args": ["/home/juan/.local/tools/cdp-browser-mcp/server.mjs"],
    "env": { "CDP_URL": "http://127.0.0.1:9224" },
    "shared": false
  }
}
```

## Core tools

| Tool | Purpose | Token cost |
|------|---------|------------|
| `cdp_navigate` | Open URL, return full-page indexed snapshot | ~3.8k |
| `cdp_snapshot` | Re-snapshot current page (after state change) | ~3.8k |
| `cdp_click` | Click element by ref from snapshot | minimal |
| `cdp_type` | Type into element by ref | minimal |
| `cdp_evaluate` | Run JS in page context | varies |
| `cdp_screenshot` | Capture PNG (use sparingly, prefer snapshot) | heavy |

## Standard flow

```text
1. cdp_navigate <url>
   → returns full page with indexed refs [ref=e1] ... [ref=eN]

2. inspect refs, identify target element

3. cdp_click <ref>     (or cdp_type <ref> "text")

4. cdp_snapshot         (re-snapshot to see updated state)

5. repeat 3-4 as needed
```

## Token-saving practices

1. **Snapshot only when state changed** — don't re-snapshot after every click if nothing visible changed.
2. **Use `find` over full snapshot** if available — search refs by text/role.
3. **Reuse the same browser tab** — don't `cdp_navigate` to same URL twice.
4. **Cache snapshots across turns** — see `context-caching/SKILL.md` for LLM-side caching.
5. **Never use `cdp_screenshot` for verification** — `cdp_snapshot` returns ARIA, which is text-searchable.

## Project integration

- ✅ `.jcode/mcp.json` registers `cdp-browser` server.
- ✅ `bin/start-cdp-chrome.sh` ensures CDP is up before each agent loop.
- ⏳ Hooks (`.jcode/hooks/pre-loop.sh`) should run `start-cdp-chrome.sh` automatically.
- ✅ `.jcode/tests/smoke/smoke_vision_strategy.sh` validates the config after
  each change. Run it before claiming the vision stack works.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `cdp_navigate` returns "ECONNREFUSED 127.0.0.1:9224" | Run `bash bin/start-cdp-chrome.sh` |
| Page loads but snapshot is empty | Tab is on `about:blank`; navigate to actual URL |
| Browser is sluggish | Kill old Chrome: `bash bin/stop-cdp-chrome.sh` then restart |
| Snapshot returns huge payload | Page has heavy DOM; consider `find` over full snapshot |
| Refs not stable across snapshots | Page re-rendered; re-snapshot and remap refs |

## See also

- `playwright-cli/SKILL.md` — terminal CLI counterpart
- `context-caching/SKILL.md` — cache repeated snapshots across LLM turns
- `.jcode/docs/VISION-STRATEGY.md` — token-budget strategy across vision tools
