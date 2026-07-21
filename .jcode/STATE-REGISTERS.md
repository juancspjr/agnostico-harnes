---
type: STATE-REGISTERS
importance: H
version: 001-template
date: 2026-07-21
title: STATE-REGISTERS — Quién lee/escribe cada estado (plantilla agnóstica)
---

# STATE-REGISTERS — Quién lee/escribe cada estado

> **Mapeo de campos críticos** (Vista Z). Evita tocar un estado sin ver
> todas sus dependencias. Antes de modificar un campo de estado, lee
> aquí TODOS los writers y readers para evitar desincronizaciones
> silenciosas.
>
> **Convención**: tabla por campo. Cada fila lista writers, readers e
> invariantes. Si un campo tiene más de 5 writers, probablemente debería
> ser descompuesto.
>
> **Esta es una PLANTILLA**. Llenar con los estados reales del proyecto
> antes del primer commit.

---

## Plantilla para cada campo de estado

```markdown
## <tabla>.<columna> (<descripción semántica>)

- **Writes**:
  - `<función/servicio/handler>` (<cuándo>)
  - `<función/servicio/handler>` (<cuándo>)
- **Reads**:
  - `<función/servicio/handler>` (<para qué>)
  - `<función/servicio/handler>` (<para qué>)
- **Invariantes**:
  - <invariante 1: relación con otros campos>
  - <invariante 2: reglas que no pueden violarse>
```

---

## Ejemplo rellenado (referencia — adaptar al proyecto)

```markdown
## users.status (Estado de cuenta del usuario)

- **Writes**:
  - `admin.users.UpdateStatus` (admin cambia estado vía UI)
  - `auth.Register` (al crear usuario, estado='active')
- **Reads**:
  - `auth.Middleware` (verifica 'active' antes de permitir login)
  - `admin.users.List` (filtro en listado)
- **Invariantes**:
  - Sincronización obligatoria con `users.last_login_at`
  - Si `status='suspended'`, los tokens existentes deben invalidarse
  - Trigger rechaza valores fuera de {active, suspended, deleted}
```

---

## Estados a documentar (mínimo recomendado)

> Llenar según el dominio del proyecto. Esta es una lista genérica
> que aplica a muchos proyectos — ajustar a la realidad.

### Identidad / Auth

- [ ] `<tabla>.status` (estado de cuenta)
- [ ] `<tabla>.email_verified` (verificación de email)
- [ ] `<tabla>.role_id` (rol del usuario)

### Entidades de negocio (ajustar al dominio)

- [ ] `<entidad>.status` (estado principal)
- [ ] `<entidad>.created_by` / `<entidad>.updated_by` (auditoría)
- [ ] `<entidad>.deleted_at` (soft-delete)

### Transacciones / Movimientos

- [ ] `<transacción>.status` (estado de la transacción)
- [ ] `<transacción>.confirmed_at` (timestamp de confirmación)

### Configuración

- [ ] `<config>.value` (valor actual)
- [ ] `<config>.updated_by` (quién modificó)

---

## Reglas de mantenimiento

- **R-SYNC-1**: Cuando agregues un campo de estado nuevo, agrega entrada
  en este archivo en el mismo commit.
- **R-SYNC-2**: Si un campo tiene más de 5 writers, probablemente debería
  descomponerse en derived fields.
- **R-SYNC-3**: Cada invariante declarada aquí debe tener un test que
  la verifique (o documentar por qué no se puede testear).
- **R-SYNC-4**: Antes de refactorizar un campo, leer TODAS sus writers
  y readers aquí. Si hay muchos, considerar helper centralizado.

---

## Quién mantiene este archivo

| Sección | Mantenido por | Cuándo |
|---|---|---|
| Cada entrada `<tabla>.<columna>` | El ingeniero que toca el campo | Al agregarlo/modificarlo |
| Reglas R-SYNC-* | Arquitecto del proyecto | Al revisar PR |

---

## Versión

- **v001-template** (2026-07-21): Plantilla agnóstica del mapa de
  estados. Llenar con los campos reales del proyecto antes del primer
  commit que toque un estado.