---
type: BEHAVIOR-INDEX
importance: M
version: 001-template
date: 2026-07-21
title: BEHAVIOR-INDEX — Mapa comportamiento → código (plantilla agnóstica)
---

# BEHAVIOR-INDEX — Mapa comportamiento → código

> **Léeme ANTES de tocar código (Paso 0 BGPD)**. Cada comportamiento
> mapea a archivos, estados y reglas. Si vas a modificar un
> comportamiento, lee primero su entrada completa para entender todas
> las dependencias acopladas.
>
> **Convención de IDs**: `B-XXX` (3 dígitos). Los IDs son índice interno
> estable. NUNCA reasignar aunque el comportamiento se archive.
>
> **Esta es una PLANTILLA**. Llenar con los comportamientos reales del
> proyecto antes del primer commit.

---

## Plantilla para cada comportamiento

```markdown
## B-XXX — <nombre del comportamiento>

- **Comportamiento**: <qué hace el sistema, en lenguaje de negocio>
- **Archivos**:
  - `<path/al/archivo>` (backend/frontend/SQL)
  - `<path/al/archivo>` (backend/frontend/SQL)
- **Estados**:
  - `<tabla>.<columna>` (<qué se muta>)
  - `<tabla>.<columna>` (<qué se lee>)
- **Reglas**: <R-1, R-5, R-NN> (referencias a PROJECT.md)
- **Loop típico**: <L-SLICE-NNN-...>
- **Tests críticos**: <qué test verificar>
```

---

## Comportamientos a documentar (mínimo recomendado)

> Llenar según el dominio del proyecto. Esta es una lista genérica
> que aplica a muchos proyectos — ajustar a la realidad.

### Identidad / Auth

- [ ] **B-001** — Registro de nuevo usuario
- [ ] **B-002** — Login con email + password
- [ ] **B-003** — Refresh token
- [ ] **B-004** — Logout (invalidación de tokens)
- [ ] **B-005** — Recuperación de contraseña

### Operaciones CRUD básicas

- [ ] **B-010** — Crear `<entidad principal>`
- [ ] **B-011** — Editar `<entidad principal>`
- [ ] **B-012** — Eliminar `<entidad principal>` (soft o hard delete)
- [ ] **B-013** — Listar `<entidad principal>` con filtros + paginación

### Flujos críticos del dominio

- [ ] **B-020** — `<nombre del flujo 1>` (end-to-end)
- [ ] **B-021** — `<nombre del flujo 2>`
- [ ] **B-022** — `<nombre del flujo 3>`

### Notificaciones

- [ ] **B-030** — Notificación por email
- [ ] **B-031** — Notificación push (si aplica)
- [ ] **B-032** — Notificación in-app

### Administración

- [ ] **B-040** — CRUD de usuarios (admin)
- [ ] **B-041** — CRUD de roles / permisos
- [ ] **B-042** — Configuración del sistema (tasa BCV, feature flags, etc.)
- [ ] **B-043** — Auditoría / logs

---

## Ejemplo rellenado (referencia — adaptar al proyecto)

```markdown
## B-001 — Registro de nuevo usuario

- **Comportamiento**: Usuario nuevo completa formulario de registro →
  email de verificación → confirmar → cuenta activa.
- **Archivos**:
  - `backend/internal/handlers/auth.go`
  - `frontend/src/pages/register.astro`
  - `db/migrations/003_create_users.sql`
- **Estados**:
  - `users.status` (`pending_verification` → `active`)
  - `users.email_verified` (false → true)
  - `email_verifications.expires_at`
- **Reglas**: R-1 (trazabilidad), R-NN (validación email)
- **Loop típico**: `L-SLICE-001-register`
- **Tests críticos**: email único, password hasheado, expiración token
```

---

## Reglas de mantenimiento

- **R-MAINT-1**: Cada comportamiento nuevo debe tener una entrada B-NNN
  en este archivo, creada en el mismo PR que introduce el comportamiento.
- **R-MAINT-2**: Si un comportamiento se depreca, marcarlo como
  `> **DEPRECATED**: reemplazado por B-MMM el YYYY-MM-DD` y mantenerlo
  visible por 6 meses.
- **R-MAINT-3**: Las referencias a reglas (`R-NN`) deben existir en
  `PROJECT.md §4`. Si agregás una regla nueva, crear el PDR correspondiente.
- **R-MAINT-4**: Las referencias a loops (`L-XXX-NNN`) deben existir en
  `INDEX.md §Loops`. Si se cierra un loop, mover su entrada al archive
  pero mantener la referencia en este BEHAVIOR-INDEX.

---

## Quién mantiene este archivo

| Sección | Mantenido por | Cuándo |
|---|---|---|
| Cada entrada B-XXX | El ingeniero que introduce el comportamiento | En el mismo PR |
| Reglas R-MAINT-* | Arquitecto del proyecto | Al revisar PR |

---

## Versión

- **v001-template** (2026-07-21): Plantilla agnóstica del mapa de
  comportamientos. Llenar con los comportamientos reales del proyecto
  antes del primer commit.