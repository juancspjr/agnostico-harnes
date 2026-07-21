---
name: jcode-handbook
description: >-
  Structural map of the harness, derived from its code. Use it when
  planning a change to find EVERY code site the change must touch —
  it maps the code stage-by-stage and lists every state register
  together with all of its read/write locations.
---

# Harness Handbook: navigation guide

## Reference files
- `.jcode/handbook/references/overview.md` — system orientation. Read first.
- `.jcode/handbook/references/index.md` — stages + state registers map.
- `.jcode/handbook/references/registers.md` — for each register: ALL writers/readers.
- `.jcode/handbook/references/stages/<id>.md` — one stage + cards per leaf.

## How to use it (during planning, before you write your plan)
1. Read `references/overview.md` first.
2. Read `references/index.md` to identify stages + registers your change involves.
3. For EVERY state register your change touches, read `references/registers.md`.
4. Open `references/stages/<id>.md` for detail.
5. Verify each site against real code:
   ```bash
   python3 .jcode/lib/handbook_verify.py \
     --request "<change request>" \
     --stages <stage_ids>
   ```
6. Your plan must account for every verified site.

## Maintenance
Auto-regenerated after every commit by `handbook_resync.py` (from `turnend.sh`).
If stale entries detected: `python3 .jcode/lib/handbook_resync.py --auto`