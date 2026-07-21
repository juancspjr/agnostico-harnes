# shadcn/ui — Guía agnóstica (plantilla)

> **Documento opcional** — Solo aplica si tu stack usa shadcn/ui
> (componentes accesibles basados en Radix + Tailwind). Si usas otro
> stack UI (Material UI, Chakra, Ant Design, etc.), ignora este archivo.
>
> **Esta es una PLANTILLA agnóstica**. Los ejemplos deben ajustarse al
> proyecto real.

---

## §1 Resumen ejecutivo

| Aspecto | Valor |
|---|---|
| Stack frontend | `<Astro 4 + React 18 + Tailwind 3 / Next 14 + Tailwind 3 / Vite + React 18 + Tailwind 3 / ...>` |
| Librería base | shadcn/ui (código copiado en repo, NO npm) |
| Primitivas accesibles | Radix UI |
| Iconos | `lucide-react` |
| Utilidades | `clsx` + `tailwind-merge` (helper `cn()`) |
| Path alias | `<@/* → src/* o equivalente>` |
| Init | `npx shadcn@latest init` ejecutado, ver `components.json` |

---

## §2 Estructura típica

```
frontend/  (o equivalente)
├── components.json               ← config shadcn estándar
├── tailwind.config.mjs           ← theme + animate plugin
├── tsconfig.json                 ← strict + path alias
└── src/
    ├── components/
    │   ├── ui/                   ← **NO TOCAR salvo emergencia**
    │   │   ├── button.tsx
    │   │   ├── input.tsx
    │   │   ├── label.tsx
    │   │   ├── card.tsx
    │   │   ├── badge.tsx
    │   │   ├── toast.tsx
    │   │   ├── toaster.tsx
    │   │   ├── use-toast.ts
    │   │   ├── dialog.tsx
    │   │   ├── select.tsx
    │   │   └── skeleton.tsx
    │   └── <tus-componentes>     ← tu código va aquí
    ├── layouts/                  ← Layouts principales
    ├── pages/                    ← rutas
    ├── lib/
    │   ├── utils.ts              ← cn() helper
    │   └── api.ts                ← cliente HTTP
    └── styles/
        └── globals.css           ← tokens CSS + directivas Tailwind
```

---

## §3 Patrón canónico: helper `cn()`

```typescript
// src/lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

**Uso**: `className={cn("base-class", conditional && "active-class", className)}`.

> El helper acepta `className` externo como última posición para permitir
> override desde el padre (patrón Radix).

---

## §4 Patrón canónico: variantes con `cva`

```typescript
import { cva, type VariantProps } from "class-variance-authority";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "underline-offset-4 hover:underline text-primary",
      },
      size: {
        default: "h-10 py-2 px-4",
        sm: "h-9 px-3 rounded-md",
        lg: "h-11 px-8 rounded-md",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);
```

---

## §5 Patrón canónico: componente con forwardRef

```typescript
import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(/* ... */);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
```

---

## §6 Patrones de uso común

### §6.1 Form con validación (Zod + react-hook-form)

```typescript
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

const formSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export function LoginForm() {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { email: "", password: "" },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        {/* ... */}
        <Button type="submit">Ingresar</Button>
      </form>
    </Form>
  );
}
```

### §6.2 Badge con variante semántica

```typescript
import { Badge } from "@/components/ui/badge";

<Badge variant="default">Activo</Badge>
<Badge variant="secondary">Pendiente</Badge>
<Badge variant="destructive">Error</Badge>
<Badge variant="outline">Borrador</Badge>
```

### §6.3 Toast de feedback

```typescript
import { useToast } from "@/components/ui/use-toast";

const { toast } = useToast();

toast({
  title: "Guardado",
  description: "Los cambios se guardaron correctamente.",
});

toast({
  variant: "destructive",
  title: "Error",
  description: "No se pudo guardar. Intentá de nuevo.",
});
```

### §6.4 Dialog modal

```typescript
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

<Dialog>
  <DialogTrigger asChild>
    <Button variant="outline">Abrir</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Título</DialogTitle>
      <DialogDescription>Descripción</DialogDescription>
    </DialogHeader>
    {/* contenido */}
    <DialogFooter>
      <Button type="submit">Confirmar</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

---

## §7 Errores comunes y anti-patrones

### ❌ Editar archivos en `components/ui/`

Los archivos en `src/components/ui/` son código copiado de shadcn/ui.
NO se modifican manualmente. Para personalizarlos:

1. Crear wrapper en `src/components/<nombre-custom>.tsx`
2. Importar el base de `ui/` y aplicarle `cn()` con variantes adicionales

### ❌ Usar `style={{}}` inline

Usar siempre `className` con `cn()` para mantener consistencia.

### ❌ Hardcodear colores

Usar siempre tokens semánticos:

| Token | Uso |
|---|---|
| `bg-background` | Fondo principal |
| `bg-card` | Fondo de cards |
| `bg-primary` | Botón primario / acción principal |
| `bg-secondary` | Acción secundaria |
| `bg-destructive` | Acción destructiva / error |
| `bg-accent` | Hover / highlight |
| `text-muted-foreground` | Texto secundario |
| `border-border` | Bordes |

### ❌ No usar `forwardRef`

Componentes de shadcn/ui esperan refs. Si creás un wrapper sin
`React.forwardRef`, perdés la integración con forms y Radix.

### ❌ Olvidar `asChild`

Para wrappear elementos con `Button` (ej. un `<a>` que parece botón),
usar `asChild` para preservar la accesibilidad.

---

## §8 Mobile-first

shadcn/ui es mobile-first por default. Consideraciones:

- Tamaño mínimo táctil: 44×44px (botones en `size="default"` cumplen).
- En mobile, preferir `Sheet` (drawer lateral) en vez de `Dialog` modal.
- Stack vertical en mobile (`flex-col`), horizontal en desktop (`md:flex-row`).

---

## §9 Testing de componentes shadcn/ui

- Render test con `@testing-library/react`: verificar que el componente
  renderiza con las variantes correctas.
- Test de accesibilidad: usar `axe-core` con `@axe-core/react`.
- Test de interacción: simular clicks con `userEvent`.

---

## §10 Comandos útiles

```bash
# Agregar componente nuevo
npx shadcn@latest add <componente>
# ej: npx shadcn@latest add button card input

# Listar componentes disponibles
npx shadcn@latest add

# Actualizar componentes a última versión
npx shadcn@latest diff
```

---

## Versión

- **v001-template** (2026-07-21): Plantilla agnóstica de la guía de
  shadcn/ui. Ajustar al stack real del proyecto (Astro vs Next vs Vite)
  antes de usar.