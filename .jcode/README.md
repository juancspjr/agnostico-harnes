---
type: HARNESS-MAP
version: 100-clean
date: 2026-07-16
title: Arnés JCode — Agnóstico (versión limpia)
---

# Arnés JCode — Mapa del Arnés (v100-clean)

> **Filosofía**: este arnés es **agnóstico al dominio**. Cero paths de proyecto,
> cero contraseñas, cero reglas de negocio. Toda la mecánica operativa portable
> vive aquí; toda la lógica del dominio vive en `AGENTS.md`, `PROJECT.md` y
> `docs/` **en la raíz del proyecto**.

---

## Regla de oro — separación

| Pregunta | Respuesta |
|---|---|
| ¿Esto define CÓMO trabaja el agente (loops, strikes, scoring)? | → vive en `.jcode/` |
| ¿Esto define QUÉ es el proyecto (reglas de negocio, stack, DB)? | → vive en raíz del repo |
| ¿Tiene un path absoluto `/home/...` o un nombre de proyecto? | → NO debe estar en `.jcode/` |
| ¿Contiene contraseñas, usuarios, emails, tablas DB? | → NO debe estar en `.jcode/` |

---

## Archivos canónicos del arnés

```
.jcode/
├── README.md                          # Este mapa
├── PRINCIPLES.md                      # Ley operativa + 6 principios LLM
├── AGENT-PROTOCOL.md                  # Checklist por turno (11 items)
├── LOOPS.md                           # Catálogo de loops
├── INTERPRETACION.md                  # **NUEVO** Capa de decisión pre-código
├── INCIDENT-PROTOCOLS.md              # Protocolos raros (fragmentación, preflight)
├── config.toml                        # Política ejecutable (env-based)
├── mcp.json                           # MCPs agnósticos
│
├── hooks/                             # 4 hooks bash (mínimos)
│   ├── sessionstart.sh                # State init + integrity check
│   ├── turn_start.sh                  # Nuevo turno + reminder
│   ├── turnend.sh                     # Log score + handoff reminder
│   └── posttool.sh                    # Log + tracking reads (NADA más)
│
├── lib/                               # 3 libs (mínimas)
│   ├── harness.sh                     # Comando /h$
│   ├── state_manager.sh               # Compliance scoring (suma 100)
│   └── jcode-hook-dispatcher.sh       # Dispatcher (única vía)
│
├── skills/                            # 4 skills (bajo demanda según task_type)
│   ├── arquitecto-proyecto/
│   ├── worker-ejecutor/
│   ├── reviewer-calidad/
│   └── guardrails/
│
├── templates/                         # 2 plantillas
│   ├── OP.md
│   └── STATE.md
│
├── iterations/                        # Por proyecto (NO se sincroniza)
│   ├── INDEX.md
│   └── PLAN-VIVO.md                   # ≤100 líneas, sprint activo
│
└── visualizer/                        # Debug visual en tiempo real
    ├── server/                        # Node.js SSE + WS
    └── public/                        # Frontend D3
```

**Total: ~800 líneas (vs 5,377 del arnés anterior, vs 1,200 de v100-clean).

---

## Qué NO está aquí (y por qué)

| Eliminado | Razón |
|---|---|
| `lib/jcode-spawn-agent.sh` | jcode ya tiene swarm + Ctrl+N nativos |
| `lib/jcode-spawn-interactive.sh` | Wrapper inútil de 53 líneas |
| `lib/coordinator_self_repair.sh` | Llamaba jcode sin `--socket`, con roles inventados. Reemplazado por `hooks/sessionstart.sh` que solo hace `git restore` de hooks |
| `lib/parallel-validation.sh` + `parallel_worker.py` | 100% específico del proyecto. Mover al repo del proyecto |
| `lib/sync_harness.sh` | Peligroso: propagaba contaminación. Usar git submodule o template |
| `lib/migrate_harness_refs.sh` | Stub de 5 líneas |
| `lib/start_session.sh` | Duplicaba `sessionstart.sh` |
| `hooks/posttool_auto_compile.sh` | Stack lock-in (Go + Astro + Docker). El proyecto tiene su propio `make watch` |
| `hooks/session_safety_check.sh` | 100% específico del proyecto anterior (contraseñas, tablas, migraciones) |
| `MEJORA_HARNES.md` | Stub inútil, mal escrito |
| `skills/agentic-workflow/` | Es para Claude Code, no jcode |

---

## Cómo iniciar una sesión

1. `cat AGENTS.md` (raíz) → constitución del proyecto
2. `cat PROJECT.md` (raíz) → spec del dominio
3. `cat .jcode/INTERPRETACION.md §1-§2` → determinar task_type, skills, MCPs
4. `cat .jcode/AGENT-PROTOCOL.md` → checklist por turno
5. `cat .jcode/iterations/PLAN-VIVO.md` → estado actual (≤100L)
6. Si tu tarea es de loops → `cat .jcode/LOOPS.md`
7. Si hubo un incidente de guardrail → `cat .jcode/INCIDENT-PROTOCOLS.md`

**Token load frío: ~4K** (vs ~105K del arnés anterior, vs ~12K v100-clean).

---

## Cómo invocar sub-agentes

**USAR jcode NATIVO**. El arnés NO reimplimenta swarm.

- `Ctrl+N` en TUI → spawn prompt interactivo
- `Ctrl+O` en TUI → listar agentes activos
- En modo headless: declarar `swarm` en `config.toml [agents] swarm_spawn_mode = "auto"`
- jcode decide cuándo spawnear workers según el loop

**Prohibido**: scripts bash que llamen `jcode debug --socket ... create_session`
manualmente. Es frágil, depende de API inestable, y rompe el tracking nativo.

---

## Cómo usar el visualizador

```bash
cd .jcode/visualizer/server
npm install
node server.mjs                    # Sirve en http://localhost:7777
```

Abre el navegador en `http://localhost:7777`. Verás:

- **Grafo en tiempo real** de agentes activos y sus ramas
- **Flujo de loops** dinámico (cómo cambia el plan entre turnos)
- **Gobernanza**: strikes, compliance score, handoffs
- **Logs en vivo** por agente
- **Histórico** de sesiones para replay

El visualizador se conecta a jcode vía socket nativo (configurado en
`config.toml [jcode] socket`). Lee eventos `session_start`, `tool_call`,
`tool_result`, `turn_end`, `swarm_spawn`, `swarm_message`, `swarm_close`,
`state_change` y los renderiza en D3 force-directed graph.

---

## Cómo adaptar este arnés a otro proyecto

1. Copiar `.jcode/` al nuevo repo
2. Editar `.jcode/config.toml`:
   - `[project] name = "tu-proyecto"`
   - `[workspace] source_dirs = ["src", "tests"]` (paths del nuevo repo)
   - Todo lo demás se resuelve vía `$JCODE_SOCKET`, `$JCODE_CLI`, `$PROJECT_ROOT`
3. Editar `.jcode/mcp.json`:
   - `filesystem.args`: usar el path absoluto del repo. Jcode v0.51.1 no expande
     `${PROJECT_ROOT}` al pasar el argumento al proceso hijo.
   - Marcar `shared: false` en servidores que prefieras session-owned (siempre
     necesario para `cdp-browser`, recomendable para `filesystem` y
     `sequential-thinking`). Los overrides locales son por nombre de servidor:
     puedes declarar los globales con `disabled: true` para evitar que se
     autoconecten.
4. Crear `AGENTS.md` y `PROJECT.md` en la raíz del nuevo repo
5. Inicializar `iterations/PLAN-VIVO.md` vacío (plantilla en `templates/`)
6. Listo. Sin scripts de sync, sin contaminación cruzada.

---

## Versión

- **v101.1-vision-mcp-fix** (2026-07-18): Documentada la precedencia real de MCP
  en Jcode v0.51.1 (global + proyecto por nombre), los overrides de servidores
  globales con `disabled: true`, la obligación de usar paths absolutos y el
  wrapper canónico `playwright-cli`. Nueva skill `smoke_vision_strategy.sh`
  valida el estándar local antes de cada ajuste.
- **v100-clean** (2026-07-16): refactor completo. Eliminados 14 archivos,
  reducidas 5,377 → 1,200 líneas. Bug de scoring 90→100 corregido.
  Eliminada toda contaminación de proyecto. Añadido visualizador en tiempo real.
