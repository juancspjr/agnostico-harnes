# ÁRBOL DE CONEXIONES — Orient vs Harness Completo

**Fecha**: 2026-07-21
**Objetivo**: Auditar exhaustivamente si la skill orient cubre TODOS los mecanismos del harness.

---

## §1 Inventario de componentes del harness

### Leyes (5 documentos canónicos)
1. `PRINCIPLES.md` — 14 principios canónicos
2. `AGENT-PROTOCOL.md` — 30+ checklist items + R7-R12 + HF1-HF12
3. `LOOPS.md` — formato de loops + hf_gate field
4. `FAILURE-PATTERNS.md` — 20 patrones + HF Gate
5. `quality-preamble.md` — 6 patrones frontera

### Librerías (13 archivos)
1. `handbook_builder.py` — Phase I (AST + scan dinámico)
2. `handbook_phase2.py` — Phase II (stages + bootstrap integration)
3. `handbook_phase3.py` — Phase III (síntesis + source_hash)
4. `handbook_resync.py` — Resync con Phase I auto + fcntl
5. `handbook_verify.py` — BGPD Source Verification
6. `_config_parse.py` — Parser TOML
7. `config_reader.sh` — Lee config.toml desde bash
8. `state_manager.sh` — Compliance scoring + state
9. `harness.sh` — Comando /h$ principal
10. `evidence_bundle.sh` — Frontier Quality (F3)
11. `jcode-hook-dispatcher.sh` — Dispatcher único
12. `clean-contamination.sh` — Limpieza
13. `git_age.sh` — Edad de commits

### Hooks (5 archivos)
1. `sessionstart.sh` — State init + integrity
2. `turn_start.sh` — Nuevo turno + reminder
3. `turnend.sh` — Compliance + HF Gate F2/F3/F4/F5 + resync
4. `posttool.sh` — Tracking reads + F12 (reasoning trace)
5. `post-loop.sh` — Cierre de loops

### Handbook (5 JSON + references/)
- `program_graph.json` (G)
- `behavioral_mapping.json` (S)
- `cache_B.json` (B con source_hash)
- `K_g.json` (cache hash)
- `frozen_entries.json` (entries congeladas)
- `references/` (L1-L2-Z navegable)

### Skills (10 skills)
1. `orient` — Triage + checkpoints
2. `bootstrap-proyecto` — Stages adaptativas + multi-lenguaje
3. `arquitecto-proyecto` — Diseño/arquitectura
4. `worker-ejecutor` — Implementación
5. `reviewer-calidad` — Revisión
6. `guardrails` — Verificación de reglas
7. `handbook` — Uso del handbook
8. `cdp-browser-mcp` — Browser MCP
9. `playwright-cli` — Testing browser
10. `context-caching` — Caché de contexto

### Tests (37 scripts)
- 7 smoke
- 1 diagnostics
- 1 audit
- 1 measure
- 1 run_all
- 18 audit/verify_*.sh (9 propios + 9 independientes)
- 2 audit/verify_hidden_failure_gate*.sh (1 propio + 1 independiente)
- 2 audit/verify_frontier_quality*.sh (1 propio + 1 independiente)
- 2 audit/verify_orient_checkpoints*.sh (1 propio + 1 independiente)
- 4 bootstrap/

---

## §2 Mecanismos del harness que Orient debe cubrir

Identifiqué 25 mecanismos. Verifico si Orient los cubre.

| # | Mecanismo | Componente del harness | ¿Orient lo cubre? |
|---|-----------|------------------------|:-----------------:|
| **LEYES** | | | |
| 1 | R-3STRIKE-MVP | `PRINCIPLES.md §1` | ❌ No |
| 2 | R-DOS-PLANOS | `PRINCIPLES.md §2` | ⚠️ Parcial (menciona PLAN-VIVO) |
| 3 | SRSI | `PRINCIPLES.md §3` | ✅ Fase 2-A paso 1 |
| 4 | DDLP | `PRINCIPLES.md §4` | ❌ No (no menciona leer §3/§4) |
| 5 | TPSP | `PRINCIPLES.md §5` | ❌ No |
| 6 | R-NO-FAKE-SWARM | `PRINCIPLES.md §6` | ❌ No |
| 7 | R-VERIFY-BEFORE-CLAIM | `PRINCIPLES.md §7` | ✅ F1 (HF Gate) + F4 |
| 8 | R-INDEPENDENT-TEST | `PRINCIPLES.md §8` | ✅ P5 (test independiente) |
| 9 | R-ITERATION-LOG | `PRINCIPLES.md §9` | ✅ Fase 2-C |
| 10 | R-NO-SILENT-STUB | `PRINCIPLES.md §10` | ❌ No |
| 11 | R-REGRESSION-BEFORE-MERGE | `PRINCIPLES.md §11` | ⚠️ Parcial (regresión en cierre) |
| 12 | R-CONTAMINATION-ZERO | `PRINCIPLES.md §12` | ❌ No |
| 13 | R-HIDDEN-FAILURE-CATALOG | `PRINCIPLES.md §13` | ✅ F1 + referencia |
| 14 | R-FRONTIER-QUALITY | `PRINCIPLES.md §14` | ✅ F2/F3/F4/F5 |
| **PAPER-COMPLIANT** | | | |
| 15 | Phase I: AST extraction | `handbook_builder.py` | ❌ No |
| 16 | Phase II: stages adaptativas | `handbook_phase2.py` | ⚠️ Parcial (F0 invoca bootstrap) |
| 17 | Phase III: synthesis | `handbook_phase3.py` | ❌ No |
| 18 | Resync automático | `handbook_resync.py` | ❌ No |
| 19 | Behavior-Implementation Alignment | §3.1 paper | ❌ No |
| 20 | Freeze mechanism | `frozen_entries.json` + resync | ⚠️ Parcial (resync en F0) |
| 21 | Program Graph (G) | `program_graph.json` | ❌ No |
| 22 | Edit Planning estructurado | `templates/OP.md` (Γ declarations) | ❌ No |
| 23 | Leaf mode (function/file) | `handbook_builder.py:174` | ❌ No |
| **FRONTIER QUALITY** | | | |
| 24 | Effort routing | `turnend.sh` | ✅ F2 |
| 25 | Self-critique | `turnend.sh` | ✅ F4 |
| 26 | Evidence bundle | `evidence_bundle.sh` | ✅ F3 |
| 27 | Reviewer spawn | `turnend.sh` | ✅ F5 |
| 28 | Reasoning trace | `posttool.sh` | ❌ No |
| **HF GATE** | | | |
| 29 | HF-V1 a HF-V6 | `FAILURE-PATTERNS.md §3.1` | ❌ No (F1 lo valida pero Orient no lo invoca explícitamente) |
| 30 | HF-S1 a HF-S5 | `FAILURE-PATTERNS.md §3.2` | ❌ No |
| 31 | HF-E1 a HF-E8 | `FAILURE-PATTERNS.md §3.3` | ❌ No |
| 32 | HF-G1 a HF-G7 | `FAILURE-PATTERNS.md §3.4` | ❌ No |
| **OTROS** | | | |
| 33 | Bootstrap adaptativo | `bootstrap-proyecto` | ✅ F0 |
| 34 | Re-anclaje post-compresión | `orient Fase 4` | ✅ Sí |
| 35 | Trazabilidad en PLAN-VIVO | `PLAN-VIVO.md` | ✅ Fase 3 |
| 36 | compliance scoring | `state_manager.sh` | ⚠️ Parcial (Fase 3) |
| 37 | AGENT-PROTOCOL §4.7 triggers | swarm spawn rules | ⚠️ Parcial (Fase 2-B Swarm Check) |
| 38 | config.toml policy blocks | `config.toml` | ⚠️ Parcial (F2) |

---

## §3 Cobertura por categorías

| Categoría | Cubiertos | Total | % |
|-----------|:---------:|:-----:|:-:|
| Leyes PRINCIPLES | 5/14 | 14 | 36% |
| Paper-compliant | 0/9 | 9 | 0% |
| Frontier Quality | 4/5 | 5 | 80% |
| HF Gate validation | 1/4 | 4 | 25% |
| Otros | 3/5 | 5 | 60% |
| **Total** | **13/37** | **37** | **35%** |

---

## §4 Gaps específicos que F0-F5 NO cubren

### Gap A: Falta invocación explícita de HF Gate checks (HF-V1 a HF-G7)

Orient solo invoca el script `verify_hidden_failure_gate.sh` que valida la estructura. Pero NO valida explícitamente cada uno de los 20 patrones HF-V/S/E/G.

**Acción**: añadir un CHECKPOINT F1.5 que enumere los patrones relevantes para el task_class y verifique que no se violen.

### Gap B: Falta invocación de Phase I/II/III cuando se modifica código del proyecto

Si el agente modifica `.jcode/lib/*.py` o `.jcode/handbook/*.json`, debe rebuildear el handbook. Orient no lo ejecuta.

**Acción**: añadir CHECKPOINT F6 — Rebuild handbook si toca código del harness.

### Gap C: Falta Phase III (síntesis navegable) explícito

Orient menciona BGPD en Fase 2-B pero no invoca explícitamente Phase III.

**Acción**: añadir Fase 2-D "Maintenance" que ejecute P                                          │
                                            ▼
                                    ┌──────────────┐
                                    │  ORIENT       │
                                    │  (skill)      │
                                    └──────┬───────┘
                                           │
        ┌──────────┬──────────┬───────────┼───────────┬────────────┬──────────┐
        ▼          ▼          ▼           ▼           ▼            ▼          ▼
     FASE 0     FASE 1     FASE 2-A   FASE 2-B   FASE 2-C     FASE 2-D     FASE 3     FASE 4
   bootstrap  triage    MICROFIX   SLICE       REMEDIATION  MAINTENANCE  traza     re-anclaje
        │       │          │          │            │              │           │          │
        ▼       ▼          ▼          ▼            ▼              ▼           ▼          ▼
   bootstrap  P1-P10    F1         BGPD L1-L3    iter log     Phase I/II/III  compliance  re-fetch
   .py       (10       (anti-      verify       budget 5      source_hash   ≥80        selectivo
            preguntas) oracle)     resync       check F1       compliance
                       F4         (frozen)                    check F7
                       (self)     reviewer                    smoke tests
                                 spawn (F5)
                                 Γ (F10)
                                 maintenance
                                 (F6, F11)

OUTPUT ↓

PRINCIPLES.md ← Orient §compatibilidad
FAILURE-PATTERNS.md ← F1 + patrones en validaciones
quality-preamble.md ← F2/F3/F4/F5
AGENT-PROTOCOL.md ← Fase 2-B Swarm Check + §4.7
LOOPS.md ← formato + hf_gate + budget
```

---

## §8 Veredicto

| Métrica | v101.3 | v101.4 (propuesto) |
|---------|--------|---------------------|
| Preguntas en árbol | 5 | 10 |
| Checkpoints | 6 | 11 |
| Fases | 5 (0, 1, 2-A, 2-B, 2-C, 3, 4) | 7 (+ 2-D) |
| Cobertura leyes | 36% | 86% |
| Cobertura paper | 0% | 78% |
| Cobertura HF | 25% | 75% |
| **Total cobertura** | **35%** | **~85%** |

**Recomendación**: actualizar Orient a v101.4 con:
1. Árbol de 10 preguntas (P6-P10 nuevas)
2. CHECKPOINTS F6-F11
3. Nueva Fase 2-D (Maintenance)
4. Validación de cierre extendida
