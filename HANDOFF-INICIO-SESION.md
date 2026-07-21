# HANDOFF — Inicio de Sesión para Próximo Agente

> **Documento vivo**. Cada sesión DEBE actualizar este archivo al
> cerrar. El próximo agente o humano lee esto primero antes que nada.

---

## §1 Estado actual del proyecto

| Campo | Valor |
|---|---|
| **Nombre** | `proyecto-01` |
| **Fase actual** | **Paper-Compliant Bootstrap Completo** ✅ |
| **Score compliance actual** | 100/100 (ver `bash .jcode/lib/harness.sh status`) |
| **Última actualización** | 2026-07-21T03:57Z |
| **Rama activa** | `feat/paper-compliant-bootstrap` |

### Lo que está hecho

- ✅ Bootstrap del repo con arnés v100-clean agnóstico (54 archivos base)
- ✅ `AGENTS.md`, `PROJECT.md`, `PDR.md` (placeholders por llenar)
- ✅ `.jcode/` completo (8 skills, 4 hooks, 5 libs, 3 templates, visualizer)
- ✅ **FASE 1 cerrada**: C-01 (9 tests) + H-01 (regex fix) + H-02 (config extensions)
- ✅ **FASE 2 cerrada**: Construction Pipeline Phase I/II/III (12 funcs, 11 L3 entries)
- ✅ **FASE 3 cerrada**: Resync automático post-commit
- ✅ **FASE 4 cerrada**: BGPD source verification
- ✅ **FASE 5 cerrada**: Edit Planning Γ + smoke_paper_compliance
- ✅ 10 tests pasan (9 audit + 1 paper_compliance), 0 contaminación

### Lo que falta (primeras tareas del proyecto)

- [ ] Llenar `AGENTS.md §1-§12` con datos reales del proyecto
- [ ] Llenar `PROJECT.md §1-§9` con spec del dominio
- [ ] Llenar `PDR.md §1-§13` con requisitos del producto
- [ ] Llenar `.jcode/STATE-REGISTERS.md` con campos de estado reales
- [ ] Llenar `.jcode/BEHAVIOR-INDEX.md` con comportamientos reales (B-001+)
- [ ] Llenar `.jcode/iterations/PLAN-VIVO.md §2, §3, §7, §8`
- [ ] Editar `.jcode/config.toml` con `[project]` y `[workspace]` reales
- [ ] Editar `.jcode/mcp.json` con filesystem path absoluto
- [ ] Editar `.jcode/lib/contamination_patterns.txt` con el nombre del proyecto
- [ ] Correr `bash .jcode/lib/harness.sh check` y verificar 0 contaminación
- [ ] Primer commit + primer loop declarado

### Métricas del handbook paper-compliant

| Métrica | Valor |
|---|---|
| **Funciones extraídas** | 12 |
| **Call edges** | 101 |
| **State accesses** | 5 |
| **L3 entries** | 11 |
| **State registers (Vista Z)** | 5 (1 atributo self.* × 2 access types) |
| **Stages (L2)** | 6 |
| **Frozen entries** | 0 |

---

## §2 Cómo continuar el trabajo

### Si eres un agente nuevo

1. **Lee `README.md` → §"5 pasos para empezar"** (orden estricto)
2. **Lee `AGENTS.md`** completo (reemplaza placeholders primero)
3. **Lee `PROJECT.md`** completo (spec del dominio)
4. **Lee `PDR.md`** completo (requisitos del producto)
5. **Lee `.jcode/AGENT-PROTOCOL.md`** (checklist por turno)
6. **Declara tu loop en `.jcode/iterations/PLAN-VIVO.md §8`**
7. **Ejecuta el checklist de los 11 items** antes de tocar código

### Si eres un humano nuevo

1. Lee el README
2. Lee `AGENTS.md §1-§12` para entender el proyecto
3. Lee `PDR.md §1-§6` para entender QUÉ y POR QUÉ
4. Lee `PROJECT.md §1-§5` para entender el dominio
5. Revisa `.jcode/iterations/PLAN-VIVO.md §7-§8` para ver qué se hace ahora
6. Si vas a tomar una decisión de arquitectura: lee
   `.jcode/INTERPRETACION.md` y consulta con la skill
   `arquitecto-proyecto`

---

## §3 Decisiones pendientes

> Las decisiones que necesitan input humano antes de tomar acción.

- **D-1**: `<decisión pendiente>` — owner: `<quién decide>`
- **D-2**: `<decisión pendiente>` — owner: `<quién decide>`

---

## §4 Riesgos conocidos

> Riesgos identificados durante el bootstrap.

- **R-1**: Si no se llenan los placeholders, el arnés no sabe cuál es
  el proyecto. Riesgo bajo (se detecta con `harness.sh check`).
- **R-2**: Si no se configura `mcp.json` con el path absoluto, el MCP
  filesystem no funcionará. Riesgo medio.
- **R-3**: Si no se ajusta `contamination_patterns.txt`, el detector
  no encontrará el nombre del proyecto. Riesgo bajo.

---

## §5 Lo que NO se debe hacer

- ❌ **NO empezar a codear sin antes llenar PDR.md + AGENTS.md +
  PROJECT.md**. Sin requisitos claros, el código será especulativo.
- ❌ **NO dejar placeholders `<...>` en archivos críticos**. El arnés
  no funciona con placeholders.
- ❌ **NO hardcodear reglas de negocio en código**. Las reglas van en
  `PROJECT.md §4` y se cargan como datos.
- ❌ **NO modificar `.jcode/PRINCIPLES.md` ni `.jcode/AGENT-PROTOCOL.md`
  sin justificación grave**. Son la ley del arnés.
- ❌ **NO copiar contenido de `.jcode/` al proyecto raíz** (ni
  viceversa). La separación es estricta.

---

## §6 Lecciones aprendidas en el bootstrap

- **2026-07-21** — Arnés v100-clean migrado desde Will-Cel. La
  versión limpia (sin contaminación de proyecto) es agnóstica y sirve
  para cualquier stack/dominio.
- **2026-07-21** — PDR (Product Requirements Document) agregado como
  documento canónico en raíz. Complementa AGENTS.md (constitución) y
  PROJECT.md (spec del dominio).
- **2026-07-21** — STATE-REGISTERS.md y BEHAVIOR-INDEX.md provistos
  como plantillas. Cada proyecto debe poblarlos con sus estados y
  comportamientos reales.

---

## §7 Handoff al próximo turno

### Sesión actual

- **Sesión ID**: `<session_id>`
- **Fecha inicio**: `<YYYY-MM-DDTHH:MMZ>`
- **Loop actual**: `<L-XXX-NNN>` — `<título>`
- **Goal de la sesión**: `<objetivo>`
- **Tareas realizadas**:
  1. `<tarea 1>`
  2. `<tarea 2>`
- **Tareas pendientes**:
  1. `<tarea 3>`
  2. `<tarea 4>`

### Próximo loop planeado

- **Loop**: `<L-XXX-NNN>`
- **Goal**: `<objetivo>`
- **Dependencias**: `<qué debe estar listo antes>`

### Notas para el próximo agente

> Contexto crítico que NO debe perderse entre turnos.

- `<nota 1>`
- `<nota 2>`

---

## §8 Cómo actualizar este archivo

Al cerrar cada sesión:

```bash
# 1. Actualizar §1 Estado actual
# 2. Actualizar §2 Cómo continuar (si cambió)
# 3. Actualizar §7 Handoff al próximo turno
# 4. Commit
git add HANDOFF-INICIO-SESION.md
git commit -m "docs(handoff): actualizar al cerrar sesión <loop_id>"
```

> Si el archivo supera 200 líneas, archivar la versión vieja a
> `docs/handoff-archive/HANDOFF-<fecha>.md` y empezar uno nuevo.

---

## Versión

- **v001-bootstrap** (2026-07-21): Documento inicial de handoff.
  Creado junto con el bootstrap del repo nuevo.