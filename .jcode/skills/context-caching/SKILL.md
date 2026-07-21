---
name: context-caching
description: How to cache repeated snapshots, file reads, and command outputs across LLM turns to stay within token budgets during long validation loops. Applies to browser snapshots, file reads, grep results, and any repeated expensive operation.
when_to_use:
  - "I'm repeatedly fetching the same page snapshot"
  - "I'm re-reading the same file across multiple turns"
  - "I need to validate a UI change without re-fetching the whole page"
  - "I want to chain multiple actions without bloating context"
token_savings: "30-60% across typical multi-turn agent loops"
---

# Skill: Context Caching

LLM-based agents have a fundamental token-economics problem: every repeated fetch costs context. This skill describes the patterns the arnés uses to cache expensive operations across turns.

## The problem

In a typical sprint, an agent might:

```
Turn 1: cdp_navigate /<ruta>/<id>  → 3.8k tokens (full page)
Turn 2: cdp_click "Edit"
Turn 3: cdp_snapshot                    → 3.8k tokens (page re-rendered)
Turn 4: cdp_click "Save"
Turn 5: cdp_snapshot                    → 3.8k tokens
```

That's 11.4k tokens just for browser context in 5 turns, even though each snapshot is mostly identical except for a few element refs.

## Pattern 1 — Diff snapshots instead of re-fetching

After each interaction, instead of `cdp_snapshot` (full), do:

```bash
cdp_evaluate "() => document.body.innerText.length"
```

If the result changed significantly, re-snapshot. If not, reuse previous snapshot with a note: "state unchanged since turn N".

## Pattern 2 — Pin specific elements with refs

Once you have a snapshot, pin refs in your working memory:

```
Refs (stable for current snapshot):
  e15: button "Confirmar entrega"
  e42: input "amount"
  e87: tab "Trabajo"
```

Re-snapshot only when DOM structure changes (rare during a single form interaction).

## Pattern 3 — Hash and reuse

For files: compute SHA before re-reading:

```bash
sha=$(sha256sum file.ts | cut -d' ' -f1)
# only read if hash differs from last turn
```

## Pattern 4 — Layered caching (3 tiers)

| Tier | What | TTL | Tool |
|------|------|-----|------|
| L1 | Single turn | this turn only | working memory |
| L2 | Session | until browser closes | `cdp_snapshot` output |
| L3 | Disk | until file changes | `sha256sum` + git status |

When you can answer from L1 (e.g., "is the button visible?" from a pinned ref), don't go to L2. When L2 is stale, refresh it. When L3 changes, invalidate L2.

## Pattern 5 — Chunked validation

For long flows, do **incremental validation**:

```
1. Navigate + snapshot          → full cost (3.8k)
2. Action 1 (small delta)      → cost 0
3. Validate via cdp_evaluate   → cost ~50
4. Action 2 (small delta)      → cost 0
5. Validate via cdp_evaluate   → cost ~50
```

Total: ~4k instead of 4 × 3.8k = 15k.

## Usage rules

1. **Always pin refs after first snapshot** — never re-snapshot to find an element.
2. **Use `cdp_evaluate` for assertions** (`document.querySelectorAll('.btn-save').length > 0`).
3. **Cache file contents by hash** — if you read a file 5 times across 5 turns, only read once.
4. **Run `start-cdp-chrome.sh` once per session** — don't restart between turns.
5. **Combine with grep-agent** (file search tool): grep is cheaper than read for known patterns.

## Counter-patterns to avoid

- ❌ `cdp_snapshot` after every click → wastes 3k+ tokens per turn
- ❌ Re-reading the same 500-line file across turns → use working memory
- ❌ `cat file | jq` repeatedly → parse once, store parsed object
- ❌ Re-running `go build ./...` → only on actual code changes

## See also

- `cdp-browser-mcp/SKILL.md` — primary cost source this skill caches
- `playwright-cli/SKILL.md` — CLI alternative for one-off reads
- `.jcode/docs/CONTEXT-CACHING.md` — full implementation guide