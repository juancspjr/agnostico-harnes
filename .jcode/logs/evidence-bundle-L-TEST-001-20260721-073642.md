# Evidence Bundle
- loop_id: L-TEST-001
- timestamp: 2026-07-21T07:36:42Z
- fixed_check: N/A
- independent_test: .jcode/tests/audit/verify_blocker_C1_independiente.sh
- iteration_log: .jcode/logs/remediation-H05-iter1.log
- regression_tail:
```
    ═══════════════════════════════════════
      TOTAL: 10 pass, 0 fail, 0 skip
    ═══════════════════════════════════════
```
- diff_stat:
```
     .gitignore                                         |  67 ++++++++++
     .jcode/AGENT-PROTOCOL.md                           |   1 +
     .jcode/PRINCIPLES.md                               |  16 +++
     .jcode/config.toml                                 |  18 +++
     .jcode/handbook/K_g.json                           |   4 +-
     .jcode/handbook/behavioral_mapping.json            |  82 ++++++------
     .jcode/handbook/cache_B.json                       |  70 +++++------
     .jcode/handbook/frozen_entries.json                |   8 +-
     .jcode/handbook/program_graph.json                 | 138 +++++++++++++--------
     .jcode/handbook/references/index.md                |   2 +-
     .jcode/handbook/references/overview.md             |   4 +-
     .jcode/handbook/references/registers.md            |   2 +-
     .jcode/handbook/references/stages/execute.md       |  18 +--
     .jcode/handbook/references/stages/handoff.md       |   6 +-
     .jcode/handbook/references/stages/init.md          |   2 +-
     .jcode/handbook/references/stages/interpret.md     |   2 +-
     .jcode/handbook/references/stages/plan.md          |   6 +-
     .jcode/handbook/references/stages/verify.md        |   8 +-
     .../tests/evidence/2026-07-21/measure_harness.log  |  10 +-
     .../evidence/2026-07-21/smoke_paper_compliance.log |   2 +-
     .jcode/tests/evidence/latest.json                  |   2 +-
     requirements.txt                                   |  29 +++++
     22 files changed, 332 insertions(+), 165 deletions(-)
```
- files_changed: 22
- verdict: PENDING — revisar outputs arriba
