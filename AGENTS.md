---
type: CONSTITUTION
importance: H
version: 100-clean.template
date: 2026-07-21
title: AGENTS.md — Constitución del proyecto (plantilla agnóstica)
---

# AGENTS.md — Constitución del Proyecto

> **Entry-point del repo.** Define identidad, prioridad de fuentes,
> separación proyecto/arnés y reglas de dominio del negocio.
>
> **NO contiene toda la ley operativa del arnés.** El comportamiento
> operativo portable (loops, fixed_check, stop conditions, estados,
> benchmark, sincronización) vive en `.jcode/PRINCIPLES.md` (canónico) y
> se referencia desde aquí.
>
> **Esta es una PLANTILLA agnóstica**. Reemplaza cada `<placeholder>`
> con el contenido real del proyecto. Lo que NO está definido en esta
> constitución pertenece a `.jcode/` (arnés) o `PROJECT.md` (spec del
> dominio) o `PDR.md` (requisitos del producto).

---

## §1 Identidad del proyecto

| Campo | Valor |
|---|---|
| **Nombre** | `<nombre-del-proyecto>` |
| **Descripción corta** | `<1 línea: qué hace y para quién>` |
| **Mantenedor principal** | `<nombre del responsable>` |
| **Repo** | `<URL-git-del-repo>` |
| **Versión actual** | `<M.m.p>` (semver) |
| **Ambiente prod** | `<URL-de-producción>` |
| **Stack principal** | `<lenguaje + framework + DB + frontend>` |

### Objetivo (1 párrafo)

`<Describe en 1 párrafo qué problema resuelve este sistema y para quién.>`

---

## §2 Stack técnico (resumen)

| Capa | Tecnología | Justificación |
|---|---|---|
| Backend | `<Go / Node / Python / Rust / Java / ...>` | `<por qué>` |
| Framework | `<Gin / Express / FastAPI / Actix / Spring / ...>` | `<por qué>` |
| ORM/Query | `<GORM / Prisma / SQLAlchemy / sqlx / ...>` | `<por qué>` |
| Frontend | `<Astro / Next / React / Vue / Svelte / ...>` | `<por qué>` |
| UI lib | `<shadcn/ui / Material UI / Tailwind / Chakra / ...>` | `<por qué>` |
| DB | `<Postgres / MySQL / SQLite / MongoDB / ...>` | `<por qué>` |
| Migraciones | `<golang-migrate / Prisma migrate / Alembic / ...>` | `<por qué>` |
| Tests | `<go test + Playwright / Jest + Cypress / Pytest + Selenium / ...>` | `<por qué>` |
| Infra | `<docker-compose / k8s / serverless / ...>` | `<por qué>` |
| CI/CD | `<GitHub Actions / GitLab CI / CircleCI / ...>` | `<por qué>` |

> Los servicios externos (email, pagos, storage, etc.) se documentan en
> `PROJECT.md §6 Servicios externos`.

---

## §3 Reglas del dominio (R-N)

> Resumen ejecutivo. Para detalle técnico ver `PROJECT.md §4`.
> Los IDs **son estables** — NUNCA reasignar aunque se archiven.

> **Mínimo 5 reglas de negocio** + **reglas derivadas** a medida que
> el proyecto crezca. Mantener máximo 40 reglas activas.

### Reglas core (siempre presentes)

- **R-1**: `<regla de dominio fundamental>`
- **R-2**: `<regla de dominio fundamental>`
- **R-3**: `<regla de dominio fundamental>`
- **R-4**: `<regla de dominio fundamental>`
- **R-5**: `<regla de dominio fundamental>`

### Reglas derivadas (a medida que el proyecto crece)

- **R-NN**: `<título breve>`
- **R-NN**: `<título breve>`
- ...

> Para detalle de cada regla (descripción completa, invariantes,
> excepciones), ver `PROJECT.md §4 Reglas de negocio`.

---

## §4 Entidades principales

> Tabla de las entidades principales del dominio. Para detalle de
> campos, ver `PROJECT.md §3 Modelo de datos`.

| Entidad | Propósito | Estados / valores válidos |
|---|---|---|
| `<Entidad 1>` | `<qué representa>` | `<enum de estados>` |
| `<Entidad 2>` | `<qué representa>` | `<enum de estados>` |
| `<Entidad 3>` | `<qué representa>` | `<enum de estados>` |
| ... | ... | ... |

---

## §5 Flujos críticos del negocio (F-NN)

> Top 5-10 flujos más importantes. Para detalle, ver `PROJECT.md §5`.

| # | Flujo | Actor principal | Estado final |
|---|---|---|---|
| F-01 | `<flujo end-to-end>` | `<rol>` | `<estado>` |
| F-02 | `<flujo end-to-end>` | `<rol>` | `<estado>` |
| ... | ... | ... | ... |

---

## §6 Roles y permisos del sistema

> **NO confundir con roles del arnés** (`arquitecto-proyecto`, etc. —
> esos viven en `.jcode/skills/`).

| Rol | Permisos clave |
|---|---|
| **`<rol 1>`** | `<qué puede hacer>` |
| **`<rol 2>`** | `<qué puede hacer>` |
| **`<rol 3>`** | `<qué puede hacer>` |

### Credenciales de desarrollo

> **NUNCA** pongas credenciales reales en este archivo. Solo dev.

| Email dev | Password dev | Rol | Uso |
|---|---|---|---|
| `<admin@dev.local>` | `<dev123>` | admin | Desarrollo local |
| `<user@dev.local>` | `<dev123>` | user | Desarrollo local |

> Las credenciales de staging/prod viven en **secret manager** (1Password,
> Vault, GitHub Secrets). NUNCA en el repo.

---

## §7 Reglas de implementación

### OBLIGATORIO

- Leer `PROJECT.md` y `PDR.md` antes de proponer cambios al dominio.
- Preferir diseño por módulos de negocio (no por capas técnicas).
- Escribir tests para funcionalidad crítica (cobertura mínima 80%).
- Mantener separación entre notas internas y mensajes visibles.
- Diseñar para extensibilidad (no hardcodear reglas de negocio).

### PROHIBIDO

- Hardcodear reglas de negocio como código cerrado (deben ser datos).
- Exponer datos sensibles en endpoints públicos.
- Dejar `TODO`, `FIXME`, funciones vacías como si fueran solución.
- Tocar la BD con SQL directo para crear/modificar data de negocio
  (usar la app, con un usuario real, vía API).
- Hardcodear nombres de roles en chequeos de permisos (usar tabla de
  permisos agnóstica).
- Simular swarm con scripts bash (usar el swarm nativo de jcode).

---

## §8 Cómo correr el proyecto

### Setup inicial (one-time)

```bash
# 1. Clonar y entrar
git clone <repo-url> && cd <directorio>

# 2. Copiar env template
cp .env.example .env
# Editar .env con valores locales

# 3. Instalar dependencias backend
cd backend && <comando-install> && cd ..

# 4. Instalar dependencias frontend
cd frontend && <comando-install> && cd ..

# 5. Levantar DB + containers
<docker compose up -d db o equivalente>
# Esperar a que la DB esté healthy

# 6. Correr migraciones
<comando-migrate>

# 7. (Opcional) Seed de datos de desarrollo
<comando-seed>
```

### Desarrollo con hot-reload

```bash
# Terminal 1 — Backend con hot-reload
make dev-backend
# o equivalente del stack

# Terminal 2 — Frontend con HMR
make dev-frontend
# o equivalente del stack
```

### Tests

```bash
# Unit
cd backend && <comando-test> ./...

# Smoke + integration + E2E
bash .jcode/tests/run_all.sh --quick
```

### URLs dev (referencia)

| Servicio | URL |
|---|---|
| Landing | `<http://localhost:8082>` |
| App | `<http://localhost:8082>` |
| Admin | `<http://localhost:8082/admin>` |
| Backend API | `<http://localhost:8081>` |

---

## §9 Documentación canónica del proyecto

| Archivo | Rol | Cuándo leer |
|---|---|---|
| `AGENTS.md` (este) | Constitución del proyecto | Siempre al iniciar sesión |
| `PROJECT.md` | Spec del dominio (detalle técnico) | Cambia dominio o reglas |
| `PDR.md` | Requisitos del producto (problema + scope) | Cambia alcance / features |
| `README.md` | Quick start del proyecto | Onboarding |
| `.jcode/README.md` | Mapa del arnés | Onboarding del harness |
| `.jcode/PRINCIPLES.md` | Ley operativa del arnés | Siempre |
| `.jcode/AGENT-PROTOCOL.md` | Checklist por turno | Siempre al iniciar turno |
| `.jcode/iterations/PLAN-VIVO.md` | Estado actual del proyecto | Siempre al iniciar sesión |
| `.jcode/iterations/INDEX.md` | Índice de iteraciones | Buscar loops previos |

> **Prohibido**: que `AGENTS.md` supere 600 líneas. Si crece, mover
> detalle a `PROJECT.md`, `PDR.md` o `docs/`.

### Prioridad de fuentes (en caso de conflicto)

1. `PDR.md` (source of truth del QUÉ se construye)
2. `PROJECT.md` (source of truth del dominio y reglas de negocio)
3. `AGENTS.md` (este archivo — constitución)
4. Documentación técnica vigente del repo
5. Estado real del código

---

## §10 Convenciones del proyecto

### Git

- **Branch naming**: `<type>/<NN>-<slug>` ej `feature/42-multi-device-walkin`
- **Commit format**: `<type>(<scope>): <subject>` ej `feat(recepcion): multi-device walkin con accordion`
  - `feat` nueva feature, `fix` bugfix, `refactor` refactor, `docs` docs,
    `test` tests, `chore` tooling, `perf` performance
- **PR size**: máximo 400 líneas diff. Si más, partir en PRs más chicos.

### Código

- **Indentación**: 2 espacios (frontend), tabs (Go — gofmt) — ajustar al stack
- **Line length**: 100 caracteres
- **Naming**:
  - Archivos: `kebab-case` (frontend), `snake_case` (Go files) — ajustar al stack
  - Variables: `camelCase` (TS), `camelCase` (Go exported: `PascalCase`)
  - Tipos/Clases: `PascalCase`
  - Constantes: `SCREAMING_SNAKE_CASE`
- **Linter**: `<golangci-lint / eslint + prettier / ruff + mypy / ...>`

### Tests

- **Cobertura mínima**: 80% para código nuevo
- **Naming**: `test_<scenario>_<expected>` ej `test_createOrder_validInput_returns201`
- **Estructura**: Arrange → Act → Assert (AAA)
- **E2E**: OBLIGATORIO para UI (ver `.jcode/AGENT-PROTOCOL.md §30`)

---

## §11 Criterios de calidad para aprobar cambios

> Pesos sugeridos. Ajustar al contexto del proyecto.

| Criterio | Peso | Regla |
|----------|------|-------|
| Correctitud del dominio | 25% | Refleja la operación real |
| Robustez operativa | 20% | Soporta casos reales y fricción |
| Extensibilidad | 15% | No se rompe ante cambios |
| Trazabilidad | 15% | Registra eventos, actores, evidencia |
| UX / velocidad | 15% | Reduce fricción al usuario |
| Seguridad y permisos | 10% | Evita exposición indebida |

### Umbral mínimo

- **Aprobado**: 75/100 o más
- **Ningún criterio por debajo de 60**

---

## §12 Cómo iniciar el proyecto desde cero

> Esta sección es para el **ingeniero de software** que recibe un repo
> vacío con este template.

### Checklist de inicio (orden estricto)

1. **Leer PDR.md** — entender QUÉ hay que construir y por qué.
2. **Editar §1 Identidad** — nombre, descripción, mantenedor, repo, stack.
3. **Editar §2 Stack técnico** — la tabla con las decisiones tomadas.
4. **Editar §3 Reglas del dominio** — las 5 reglas core + las que apliquen.
5. **Editar §4 Entidades principales** — el modelo de datos inicial.
6. **Editar §5 Flujos críticos** — top 5-10 flujos del negocio.
7. **Editar §6 Roles y permisos** — los roles del producto (no del arnés).
8. **Editar §8 Cómo correr el proyecto** — los comandos reales.
9. **Editar §10 Convenciones** — adaptar al stack.
10. **Editar `.jcode/config.toml` [project] y [workspace]** — name + source_dirs.
11. **Editar `.jcode/mcp.json` filesystem.args** — path absoluto del nuevo repo.
12. **Editar `.jcode/lib/contamination_patterns.txt`** — agregar el nombre del proyecto para detección de contaminación.
13. **Editar `.jcode/iterations/PLAN-VIVO.md`** — llenar §2 (implementación actual), §3 (gaps), §7 (plan MVP), §8 (sesión actual).
14. **Ejecutar `bash .jcode/lib/harness.sh check`** — debe retornar 0 contaminación.
15. **Primer commit**: `chore(init): constitución del proyecto + arnés bootstrap`.

### Errores comunes a evitar

- ❌ Empezar a codear sin definir PDR ni reglas de dominio.
- ❌ Dejar placeholders `<...>` en archivos críticos.
- ❌ Olvidar editar `config.toml` y `mcp.json` — el arnés quedará apuntando al repo viejo.
- ❌ Olvidar poblar `contamination_patterns.txt` — el detector no funcionará.
- ❌ Crear reglas de negocio hardcoded en código en vez de datos.
- ❌ Saltarse `PLAN-VIVO.md` — sin plano mayor no hay trazabilidad.

---

## Versión y cambios

- **v100-clean.template** (2026-07-21): Plantilla agnóstica del harness
  v100-clean. Lista para cualquier stack y cualquier dominio. Reemplaza
  placeholders con valores reales del proyecto antes del primer commit.