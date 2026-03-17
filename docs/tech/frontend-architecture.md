# Arquitectura Frontend — Agendify Web

Documentacion tecnica de la aplicacion frontend de Agendify, construida con Next.js 16 como PWA.

**Repositorio:** `agendify-web`
**Ultima actualizacion:** Marzo 2026
**Archivos TS/TSX:** 109

---

## 1. Stack tecnologico

| Tecnologia | Version | Proposito |
|---|---|---|
| **Next.js** | 16.1.6 | Framework principal, App Router, SSG para paginas publicas |
| **React** | 19.2.3 | Libreria UI |
| **TypeScript** | 5.x | Tipado estatico en todo el proyecto |
| **Tailwind CSS** | 4.x | Sistema de estilos utility-first |
| **Zustand** | 5.0.12 | Estado del cliente (auth, UI, booking flow) |
| **TanStack Query** | 5.90.21 | Estado del servidor, cache, sincronizacion |
| **React Hook Form** | 7.71.2 | Manejo de formularios |
| **Zod** | 4.3.6 | Validacion de esquemas |
| **@hookform/resolvers** | 5.2.2 | Integracion Zod + React Hook Form |
| **Axios** | 1.13.6 | Cliente HTTP con interceptores JWT |
| **FullCalendar** | 6.1.20 | Componente de calendario (agenda del negocio) |
| **recharts** | 3.8.0 | Graficas para reportes |
| **dayjs** | 1.11.20 | Manejo de fechas y timezones |
| **lucide-react** | 0.577.0 | Iconos |
| **qrcode.react** | 4.2.0 | Generacion de codigos QR |
| **react-dropzone** | 15.0.0 | Upload de archivos (comprobantes de pago) |
| **leaflet** | 1.9.4 | Libreria de mapas interactivos (explore, location picker) |
| **react-leaflet** | 5.0.0 | Bindings React para Leaflet |
| **@types/leaflet** | 1.9.21 | Tipos TypeScript para Leaflet |
| **@ducanh2912/next-pwa** | 10.2.9 | Service worker y manifest PWA |
| **nats.ws** | — | Cliente NATS para WebSocket (tiempo real) |
| **clsx + tailwind-merge** | — | Utilidad para merge de clases CSS |
| **Vitest** | 4.1.0 | Testing unitario |
| **React Testing Library** | 16.3.2 | Testing de componentes |

---

## 2. Estructura del proyecto

```
src/
├── app/                          # App Router (rutas)
│   ├── layout.tsx                # Root layout (AppProviders, fuentes, globals.css)
│   ├── page.tsx                  # Landing page (/)
│   ├── globals.css               # Estilos globales + Tailwind
│   │
│   ├── (auth)/                   # Route group: autenticacion
│   │   ├── layout.tsx            # Layout compartido auth (centrado, sin sidebar)
│   │   ├── login/page.tsx        # /login
│   │   └── register/page.tsx     # /register
│   │
│   ├── dashboard/                # Panel del negocio (layout con sidebar + topbar)
│   │   ├── layout.tsx            # Layout con sidebar + topbar + mobile nav
│   │   ├── agenda/page.tsx       # /dashboard/agenda (FullCalendar)
│   │   ├── services/page.tsx     # /dashboard/services
│   │   ├── employees/page.tsx    # /dashboard/employees
│   │   ├── customers/page.tsx    # /dashboard/customers
│   │   ├── payments/page.tsx     # /dashboard/payments (gestión de comprobantes)
│   │   ├── notifications/page.tsx # /dashboard/notifications (todas las notificaciones)
│   │   ├── reports/page.tsx      # /dashboard/reports
│   │   ├── reviews/page.tsx      # /dashboard/reviews
│   │   ├── checkin/page.tsx       # /dashboard/checkin (check-in por código de ticket)
│   │   ├── qr/page.tsx           # /dashboard/qr
│   │   ├── settings/page.tsx     # /dashboard/settings (perfil, logo, colores, horarios, pagos, notificaciones)
│   │   └── onboarding/page.tsx   # /onboarding (wizard post-registro)
│   │
│   ├── explore/page.tsx          # /explore (mapa y listado de negocios)
│   │
│   └── [slug]/                   # Paginas publicas por negocio
│       ├── page.tsx              # /barberia-elite (perfil + booking flow)
│       └── ticket/[code]/page.tsx # /barberia-elite/ticket/ABC123
│
├── components/
│   ├── ui/                       # Design system (14 componentes base)
│   │   ├── button.tsx            # Button (primary, secondary, ghost, destructive, outline)
│   │   ├── input.tsx             # Input con label y error
│   │   ├── textarea.tsx          # Textarea
│   │   ├── select.tsx            # Select nativo estilizado
│   │   ├── modal.tsx             # Modal con overlay
│   │   ├── drawer.tsx            # Drawer lateral (mobile)
│   │   ├── card.tsx              # Card contenedor
│   │   ├── badge.tsx             # Badge de estado
│   │   ├── avatar.tsx            # Avatar con fallback
│   │   ├── spinner.tsx           # Loading spinner
│   │   ├── skeleton.tsx          # Skeleton loader
│   │   ├── toast.tsx             # Sistema de notificaciones toast
│   │   ├── empty-state.tsx       # Estado vacio con icono y CTA
│   │   └── index.ts              # Barrel export
│   │
│   ├── layout/                   # Componentes de layout
│   │   ├── sidebar.tsx           # Sidebar desktop (con locks por plan)
│   │   ├── topbar.tsx            # Barra superior (con NotificationBell + plan badge)
│   │   ├── notification-bell.tsx # Campanita con badge de no leidas + dropdown
│   │   └── mobile-nav.tsx        # Navegacion mobile (bottom nav)
│   │
│   ├── agenda/                   # Componentes de la agenda
│   │   ├── agenda-calendar.tsx   # Wrapper de FullCalendar
│   │   ├── create-appointment-modal.tsx
│   │   ├── appointment-detail-modal.tsx
│   │   └── block-slot-modal.tsx
│   │
│   ├── booking/                  # Flujo de reserva publica
│   │   ├── booking-flow.tsx      # Orquestador del wizard de 5 pasos
│   │   ├── service-selector.tsx
│   │   ├── employee-selector.tsx
│   │   ├── date-time-picker.tsx
│   │   ├── customer-form.tsx
│   │   └── booking-confirmation.tsx
│   │
│   ├── onboarding/               # Wizard de onboarding (6 pasos)
│   │   ├── step-business-profile.tsx
│   │   ├── step-business-hours.tsx
│   │   ├── step-services.tsx
│   │   ├── step-employees.tsx
│   │   ├── step-payment-methods.tsx
│   │   └── step-cancellation-policy.tsx
│   │
│   ├── forms/                    # Formularios reutilizables
│   │   ├── service-form.tsx
│   │   └── employee-form.tsx
│   │
│   ├── reports/                  # Componentes de reportes
│   │   ├── summary-card.tsx
│   │   ├── revenue-chart.tsx
│   │   ├── top-services-chart.tsx
│   │   └── top-employees-chart.tsx
│   │
│   └── shared/                   # Componentes compartidos
│       ├── business-card.tsx     # Card de negocio (explore, listados)
│       ├── explore-map.tsx       # Mapa interactivo Leaflet para /explore
│       ├── image-viewer-modal.tsx # Modal para ver comprobantes/imagenes a pantalla completa
│       ├── location-picker.tsx   # Picker de ubicacion con Leaflet (settings, onboarding)
│       ├── map-embed.tsx         # Google Maps embed (pagina publica)
│       ├── qr-code-display.tsx   # Generador/display de QR
│       ├── star-rating.tsx       # Componente de estrellas para reviews
│       └── upgrade-banner.tsx    # Banner CTA para upgrade de plan
│
├── lib/
│   ├── api/
│   │   ├── client.ts             # Axios instance + interceptores JWT
│   │   ├── endpoints.ts          # Mapa centralizado de endpoints
│   │   └── types.ts              # Interfaces TypeScript (modelos del backend)
│   │
│   ├── hooks/                    # Custom hooks — 17 hooks
│   │   ├── use-auth.ts           # Login, register, refresh, logout
│   │   ├── use-appointments.ts   # CRUD citas + state transitions + checkinByCode
│   │   ├── use-services.ts       # CRUD servicios
│   │   ├── use-employees.ts      # CRUD empleados
│   │   ├── use-customers.ts      # Listado y detalle de clientes
│   │   ├── use-business.ts       # Negocio actual + upload logo
│   │   ├── use-onboarding.ts     # Wizard de onboarding
│   │   ├── use-reports.ts        # Datos de reportes
│   │   ├── use-reviews.ts        # Resenias
│   │   ├── use-blocked-slots.ts  # Bloqueos de agenda
│   │   ├── use-public.ts         # Endpoints publicos (perfil, availability, booking)
│   │   ├── use-explore.ts        # Explorar negocios
│   │   ├── use-payments.ts       # Pagos pendientes, aprobados, rechazados + approve/reject
│   │   ├── use-notifications.ts  # Notificaciones, unread count, mark read
│   │   ├── use-subscription.ts   # Plan actual, feature locks, upgrade checks
│   │   ├── use-realtime.ts       # Conexion NATS WebSocket para tiempo real
│   │   └── use-event-notifications.ts # Procesador de eventos → invalidacion + browser notifications + sonido
│   │
│   ├── stores/                   # Zustand stores
│   │   ├── auth-store.ts         # Persistido (JWT + user)
│   │   ├── ui-store.ts           # Sidebar, modals, toasts
│   │   ├── booking-store.ts      # Estado del flujo de reserva publica
│   │   └── __tests__/            # Tests de stores
│   │
│   ├── validations/              # Esquemas Zod
│   │   ├── auth.ts               # login, register
│   │   ├── booking.ts            # customerInfo
│   │   ├── appointment.ts        # createAppointment
│   │   └── onboarding.ts         # pasos del wizard
│   │
│   ├── utils/
│   │   ├── cn.ts                 # clsx + tailwind-merge
│   │   ├── format.ts             # formatCurrency, formatPhone, truncate, capitalize
│   │   ├── date.ts               # Utilidades de fecha con dayjs
│   │   ├── browser-notification.ts # Wrapper de Notification API nativa
│   │   ├── notification-sound.ts # Chime con Web Audio API (sin archivo externo)
│   │   └── __tests__/            # Tests de utils
│   │
│   └── constants.ts              # Constantes globales
│
├── providers/
│   └── app-providers.tsx         # QueryClientProvider (TanStack Query)
│
├── middleware.ts                  # Proteccion de rutas (JWT en cookie)
│
└── test/
    └── setup.ts                  # Configuracion de Vitest
```

---

## 3. Arquitectura de datos

### Separacion de estado servidor vs. cliente

El proyecto separa de forma estricta el estado del servidor y el estado del cliente:

| Tipo | Herramienta | Uso |
|---|---|---|
| **Estado del servidor** | TanStack Query | Datos que vienen del API (citas, servicios, empleados, etc.) |
| **Estado del cliente** | Zustand | Estado local de la UI (auth, sidebar, booking flow, toasts) |

Esta separacion evita duplicar datos del servidor en stores locales y garantiza que TanStack Query sea la unica fuente de verdad para datos remotos.

### TanStack Query — Estado del servidor

**Configuracion global** (`app-providers.tsx`):

```typescript
new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,    // 5 minutos — los datos se consideran frescos
      gcTime: 10 * 60 * 1000,       // 10 minutos — cache en memoria
      retry: 1,                      // 1 reintento en caso de error
      refetchOnWindowFocus: false,   // No refetch al volver a la ventana
    },
  },
})
```

**Patron de query keys** (ejemplo de `use-appointments.ts`):

```typescript
const appointmentKeys = {
  all: ['appointments'] as const,
  list: (params: Record<string, unknown>) => ['appointments', 'list', params] as const,
  detail: (id: number) => ['appointments', 'detail', id] as const,
};
```

Este patron permite invalidacion granular. Al crear o actualizar una cita, se invalida `appointmentKeys.all` y TanStack Query refresca automaticamente todas las queries que dependen de `['appointments', ...]`.

**Invalidacion**:
Cada mutation (`useCreateAppointment`, `useCancelAppointment`, etc.) invalida las queries relacionadas en su callback `onSuccess`:

```typescript
onSuccess: () => {
  queryClient.invalidateQueries({ queryKey: appointmentKeys.all });
}
```

**Hooks por recurso**:
Cada recurso del API tiene su propio archivo de hooks en `lib/hooks/`:
- `use-appointments.ts` — queries y mutations de citas
- `use-services.ts` — CRUD de servicios
- `use-employees.ts` — CRUD de empleados
- `use-customers.ts` — listado y detalle de clientes
- `use-reports.ts` — datos de reportes
- `use-public.ts` — endpoints publicos (perfil de negocio, disponibilidad, booking)
- `use-payments.ts` — pagos pendientes/aprobados/rechazados + approve/reject mutations
- `use-notifications.ts` — lista paginada, unread count (polling 30s), mark read
- `use-subscription.ts` — plan actual derivado del business, feature locks, upgrade checks
- `use-explore.ts` — busqueda y filtrado de negocios para /explore
- `use-realtime.ts` — conexion NATS WebSocket, suscripcion al canal del negocio, fallback a polling
- `use-event-notifications.ts` — procesa eventos NATS → invalidacion de cache + browser notification + sonido

### Zustand — Estado del cliente

Tres stores, cada uno con una responsabilidad clara:

**1. `auth-store.ts`** (persistido en cookie):
- `token` — JWT access token
- `refreshToken` — JWT refresh token
- `user` — datos del usuario autenticado
- Acciones: `setAuth`, `setUser`, `clearAuth`
- Computed: `isAuthenticated()`
- Persistencia via `zustand/middleware/persist` con nombre `agendify-auth`

**2. `ui-store.ts`** (en memoria, no persistido):
- `sidebarOpen` — estado del sidebar en mobile
- `modalOpen` / `modalContent` — modal global programatico
- `toasts[]` — sistema de notificaciones toast con auto-dismiss (5s default)
- Acciones: `toggleSidebar`, `openModal`, `closeModal`, `addToast`, `removeToast`

**3. `booking-store.ts`** (en memoria, no persistido):
- Estado del wizard de reserva publica (5 pasos)
- `currentStep`, `selectedService`, `selectedEmployee`, `selectedDate`, `selectedTime`, `customerInfo`
- Cada setter avanza automaticamente al siguiente paso
- Accion `reset()` para limpiar al terminar o abandonar

---

## 4. Autenticacion

### Flujo JWT completo

```
1. Login/Register → POST /api/v1/auth/login
2. Backend responde: { token, refresh_token, user }
3. Frontend guarda en auth-store (Zustand persist → cookie "agendify-auth")
4. Axios interceptor adjunta Bearer token a cada request
5. Si el API responde 401 → interceptor intenta refresh
6. Si refresh falla → clearAuth() + redirect a /login
```

### Almacenamiento de tokens

El `auth-store` usa `zustand/middleware/persist` que serializa el estado como JSON en una cookie llamada `agendify-auth`. El middleware de Next.js lee esta cookie en el edge para proteger rutas sin necesidad de JavaScript del lado del cliente.

El store usa `partialize` para persistir solo lo necesario:

```typescript
partialize: (state) => ({
  token: state.token,
  refreshToken: state.refreshToken,
  user: state.user,
})
```

### Interceptores de Axios

**Request interceptor**: lee el token del `auth-store` y lo adjunta como `Authorization: Bearer <token>`.

**Response interceptor**: maneja 401 con refresh token queue:
- Si llega un 401 y hay refresh token, intenta renovar
- Si ya hay un refresh en progreso, encola las requests pendientes
- Cuando el refresh se completa, las requests encoladas se reenvian con el nuevo token
- Si el refresh falla, limpia auth y redirige a `/login`

Este patron de cola evita multiples refresh simultaneos cuando varias requests fallan a la vez.

### Timeout

El cliente Axios tiene un timeout de 15 segundos configurado globalmente.

---

## 5. Rutas y navegacion

### Route groups

| Grupo | Prefijo | Descripcion |
|---|---|---|
| `(auth)` | `/login`, `/register` | Paginas de autenticacion, layout centrado sin sidebar |
| `(dashboard)` | `/dashboard/*`, `/onboarding` | Panel del negocio, layout con sidebar + topbar |
| `[slug]` | `/<slug>` | Paginas publicas del negocio (SSG) |

### Logica del middleware

El middleware (`middleware.ts`) se ejecuta en el edge de Next.js para cada request (excepto archivos estaticos). Su logica:

1. **Rutas publicas** — se permiten sin autenticacion:
   - Exactas: `/`, `/login`, `/register`, `/explore`
   - Prefijo: `/explore/*`
   - Dinamicas: `/<slug>` (paginas de negocios), `/<slug>/ticket/<code>`
   - Internos: `/_next/*`, `/api/*`, archivos con extension

2. **Deteccion de slug**: Un segmento que no sea `dashboard`, `onboarding`, `login`, `register` o `explore` se considera slug de negocio.

3. **Rutas protegidas** — requieren token en cookie `agendify-auth`:
   - Si no hay token → redirect a `/login?redirect=<path>`
   - Si hay token pero onboarding no completado y va a `/dashboard/*` → redirect a `/onboarding`
   - Si hay token y onboarding completado y va a `/onboarding` → redirect a `/dashboard`

### Mapa de rutas del dashboard

| Ruta | Pagina |
|---|---|
| `/dashboard/agenda` | Calendario principal (FullCalendar) |
| `/dashboard/services` | CRUD de servicios |
| `/dashboard/employees` | CRUD de empleados |
| `/dashboard/customers` | Base de datos de clientes |
| `/dashboard/payments` | Gestion de pagos/comprobantes (aprobar/rechazar) |
| `/dashboard/notifications` | Todas las notificaciones del negocio |
| `/dashboard/checkin` | Check-in de clientes (ingreso de codigo de ticket) |
| `/dashboard/reports` | Reportes e ingresos |
| `/dashboard/reviews` | Resenas del negocio |
| `/dashboard/qr` | Generador de QR |
| `/dashboard/settings` | Configuracion del negocio (perfil, logo, colores, horarios, pagos, notificaciones) |
| `/onboarding` | Wizard de configuracion inicial (6 pasos) |

---

## 6. Componentes UI — Design system

### Sistema de diseno

El design system esta construido con Tailwind CSS v4 y componentes propios (sin dependencia de Shadcn, Radix ni otras librerias de componentes).

**Color primario**: `violet-600` (`#7c3aed`)
**Utilidad de clases**: `cn()` = `clsx` + `tailwind-merge` para merge inteligente de clases.

### Catalogo de componentes (`components/ui/`)

| Componente | Variantes/Props |
|---|---|
| **Button** | variant: `primary`, `secondary`, `ghost`, `destructive`, `outline` / size: `sm`, `md`, `lg` / `loading`, `fullWidth` |
| **Input** | label, error message, todos los props nativos |
| **Textarea** | label, error message |
| **Select** | opciones tipadas con `SelectOption[]` |
| **Modal** | overlay, contenido dinamico via `ui-store` |
| **Drawer** | panel lateral para mobile |
| **Card** | contenedor con padding y sombra |
| **Badge** | indicadores de estado (colores por tipo) |
| **Avatar** | imagen con fallback por iniciales |
| **Spinner** | animacion de carga, tamanos |
| **Skeleton** | placeholder de carga |
| **Toast** | notificaciones: `success`, `error`, `warning`, `info` / auto-dismiss |
| **EmptyState** | estado vacio con icono, titulo, descripcion y CTA |

### Iconos

Se usa `lucide-react` para todos los iconos de la aplicacion. Consistente, tree-shakeable, y con la misma estetica lineal.

---

## 7. Formularios y validacion

### Patron: React Hook Form + Zod v4

Cada formulario sigue el mismo patron:

1. **Esquema Zod** en `lib/validations/` — define la forma y reglas de validacion
2. **Tipo inferido** con `z.infer<typeof schema>` — genera el tipo TypeScript automaticamente
3. **Hook del formulario** con `useForm<T>({ resolver: zodResolver(schema) })`
4. **Mensajes en espanol** — los mensajes de error estan en espanol para el usuario final

**Ejemplo del patron** (login):

```typescript
// lib/validations/auth.ts
export const loginSchema = z.object({
  email: z.string().min(1, 'El correo es requerido').email('Ingresa un correo valido'),
  password: z.string().min(6, 'La contrasena debe tener al menos 6 caracteres'),
});

export type LoginFormData = z.infer<typeof loginSchema>;

// Componente
const { register, handleSubmit, formState: { errors } } = useForm<LoginFormData>({
  resolver: zodResolver(loginSchema),
});
```

### Esquemas existentes

| Archivo | Esquemas |
|---|---|
| `auth.ts` | `loginSchema`, `registerSchema` (con `.refine` para confirmar contrasena) |
| `booking.ts` | `customerInfoSchema` (nombre, email, telefono con regex colombiano) |
| `appointment.ts` | `createAppointmentSchema` |
| `onboarding.ts` | Esquemas para cada paso del wizard |

---

## 8. PWA (Progressive Web App)

### Configuracion

Se usa `@ducanh2912/next-pwa` integrado en `next.config.ts`:

```typescript
export default withPWA({
  dest: "public",                              // Service worker en /public
  disable: process.env.NODE_ENV === "development", // Deshabilitado en dev
  register: true,                              // Auto-registro del SW
})(nextConfig);
```

### Capacidades

- **Instalable**: La app se puede instalar desde el navegador (Add to Home Screen) en Android, iOS y desktop
- **Service worker**: Generado automaticamente por next-pwa, habilita cache offline para assets estaticos
- **Manifest**: `manifest.json` en `/public` con nombre, iconos y colores de la app
- **Offline basico**: Assets y paginas visitadas se cachean para funcionar sin conexion

### Imagen remota

Next.js Image esta configurado para aceptar imagenes de:
- `https://api.agendify.com` (produccion)
- `http://localhost:3000` (desarrollo)

---

## 9. Testing

### Stack

| Herramienta | Uso |
|---|---|
| **Vitest 4.1** | Test runner, compatible con la API de Jest |
| **React Testing Library 16.3** | Renderizado y queries de componentes React |
| **@testing-library/jest-dom** | Matchers adicionales para DOM |
| **jsdom 29** | Entorno DOM simulado |

### Estructura de tests

```
src/
├── lib/stores/__tests__/
│   ├── auth-store.test.ts       # 5 tests — setAuth, clearAuth, isAuthenticated, setUser
│   └── booking-store.test.ts    # 8 tests — pasos del wizard, reset, nextStep, prevStep
│
├── lib/utils/__tests__/
│   ├── format.test.ts           # 13 tests — formatCurrency, formatPhone, truncate, capitalize
│   └── cn.test.ts               # 6 tests — merge de clases, conflictos Tailwind, valores nulos
│
└── test/setup.ts                # Setup global (jest-dom matchers)
```

### Estado actual

- **4 archivos de test**
- **28 tests** passing (4 failing por cambios recientes)
- Cobertura enfocada en: stores (Zustand) y utilidades puras
- Los tests de stores validan el estado directamente sin renderizar componentes (acceso via `getState()`)

### Ejecucion

```bash
npm test          # Ejecutar una vez
npm run test:watch # Modo watch
```

---

## 10. Sistema de planes y suscripciones

### Arquitectura del sistema de planes en frontend

El sistema de planes controla que features estan disponibles segun la suscripcion del negocio.

**Hook principal: `use-subscription.ts`**

El hook `useCurrentSubscription()` deriva el plan actual a partir de la respuesta del API de business:
- Lee `business.current_subscription.plan.name`
- Normaliza el nombre a un `PlanSlug`: `trial`, `basico`, `profesional`, `inteligente`
- Expone: `planSlug`, `planLabel`, `isTrialing`, `subscription`, `plan`

**Feature locks: `useCanAccessFeature(featurePath)`**

Retorna `true/false` segun si el plan actual tiene acceso a un feature dado. Los locks estan definidos en `lib/constants.ts` via `PLAN_FEATURE_LOCKS`.

**Componentes UI del sistema de planes:**

| Componente | Ubicacion | Funcion |
|---|---|---|
| **Plan Badge** | Topbar | Muestra el nombre del plan actual con color |
| **Lock icons** | Sidebar | Icono de candado en items del menu sin acceso |
| **UpgradeBanner** | `components/shared/upgrade-banner.tsx` | Banner CTA cuando un feature esta bloqueado |

---

## 11. Mapas con Leaflet

### Componentes de mapas

El proyecto usa **Leaflet + react-leaflet** para mapas interactivos (no Google Maps API, que solo se usa como embed).

| Componente | Archivo | Uso |
|---|---|---|
| **LocationPicker** | `components/shared/location-picker.tsx` | Picker interactivo para seleccionar ubicacion del negocio (settings, onboarding). Click en mapa → coordenadas |
| **ExploreMap** | `components/shared/explore-map.tsx` | Mapa de negocios en `/explore` con markers por cada negocio. Click en marker → card del negocio |
| **MapEmbed** | `components/shared/map-embed.tsx` | Google Maps embed (iframe) para la pagina publica del negocio. Muestra la ubicacion y boton "Como llegar" |

### Configuracion de Leaflet

Leaflet requiere carga dinamica en Next.js (no compatible con SSR):

```typescript
// Los componentes de Leaflet se importan con dynamic() y ssr: false
import dynamic from 'next/dynamic';
const LocationPicker = dynamic(() => import('@/components/shared/location-picker'), { ssr: false });
```

Los tiles del mapa usan OpenStreetMap (gratuito, sin API key).

---

## 12. Tiempo real con NATS

> Documentacion completa: [nats-realtime.md](nats-realtime.md)

El dashboard se conecta a un servidor NATS via WebSocket para recibir actualizaciones en tiempo real. Se activa automaticamente en el layout del dashboard:

```typescript
// src/app/dashboard/layout.tsx
useRealtime(); // Conexion NATS → suscripcion al canal del negocio
```

### Flujo de procesamiento de eventos

1. **`use-realtime.ts`** — Se conecta a NATS via `nats.ws`, suscribe a `business.<id>.>`, parsea mensajes JSON
2. **`use-event-notifications.ts`** — Recibe cada evento y ejecuta:
   - Invalidacion de queries de TanStack Query (calendario, pagos, notificaciones)
   - Notificacion nativa del navegador (`browser-notification.ts`)
   - Sonido de notificacion (`notification-sound.ts`, si esta habilitado)

### Fallback

Si NATS no esta disponible, `useRealtime` logea un warning y el polling existente (`refetchInterval`) sigue funcionando:
- Citas: polling cada 15s
- Pagos: polling cada 30s
- Notificaciones: polling cada 30s

---

## 13. Notificaciones del navegador y sonido

### `browser-notification.ts`

Wrapper sobre la Notification API nativa:
- `requestNotificationPermission()` — Solicita permiso al usuario
- `showBrowserNotification(title, options)` — Muestra notificacion con icono de la app, auto-cierre en 5s, click foca la ventana

### `notification-sound.ts`

Genera un chime de dos tonos con Web Audio API pura (D5 + A5, onda sinusoidal con fade-out). No requiere archivo de audio externo.

### Configuracion en Settings

La pagina `/dashboard/settings` incluye una seccion `NotificationSection`:
- Estado de permisos del navegador (Activadas / Bloqueadas / No disponible)
- Toggle de sonido on/off (persistido en `ui-store` → localStorage `agendify-ui`)

---

## 14. Check-in de clientes

**Pagina:** `/dashboard/checkin` (`src/app/dashboard/checkin/page.tsx`)

Permite al negocio registrar la llegada de un cliente ingresando el codigo de su ticket:

1. El negocio ingresa el codigo del ticket (ej: `FE89E62168B5`) manualmente o escanea el QR
2. Llama a `POST /api/v1/appointments/checkin_by_code` via `useCheckinByCode()` (hook en `use-appointments.ts`)
3. Si es exitoso, muestra los detalles de la cita (cliente, servicio, empleado, fecha, hora)
4. La cita pasa a estado `checked_in` en el backend

---

## 15. QR en confirmacion de reserva

Cuando un usuario final completa una reserva, la pantalla de exito (`booking-confirmation.tsx`) muestra:
- Datos de la reserva (servicio, fecha, hora, codigo de ticket)
- **Codigo QR** generado con `qrcode.react` que codifica la URL del ticket: `/{slug}/ticket/{code}`
- Boton "Ver mi ticket" que lleva a la pagina completa del ticket digital
- Boton "Nueva reserva" para reiniciar el flujo

---

## 16. Upload de logo

**Frontend:** `LogoSection` en `/dashboard/settings`
**Backend:** `has_one_attached :logo` en `Business` (ActiveStorage)
**Hook:** `useUploadLogo()` en `use-business.ts`

Flujo:
1. Click en avatar o boton "Seleccionar archivo"
2. Validacion cliente: solo imagenes, maximo `MAX_FILE_SIZE_MB`
3. Upload multipart via `uploadLogo.mutateAsync(file)`
4. El backend almacena con ActiveStorage y retorna `logo_url`

---

## 17. Personalizacion de colores

**Frontend:** `ColorSection` en `/dashboard/settings`
**Restriccion:** Solo disponible para planes Profesional+ (`BRAND_CUSTOMIZATION_PLANS`)

Permite al negocio definir:
- **Color primario** (default: `#7C3AED` — violet-600)
- **Color secundario** (default: `#1A1A2E`)

Incluye:
- Selectores de color (`input type="color"` + campo de texto hex)
- Vista previa en tiempo real (circulos de color)
- Si el plan no tiene acceso, muestra `UpgradeBanner`

---

## 18. Prevencion de slots pasados

El sistema de disponibilidad (`date-time-picker.tsx`) filtra automaticamente los horarios que ya pasaron para el dia actual. Si un usuario selecciona la fecha de hoy, solo ve los slots futuros. Esto se valida tanto en frontend como en backend.

---

## 19. Auto-refresh por polling

Ademas del tiempo real con NATS, el frontend mantiene polling como fallback y como mecanismo de sincronizacion:

| Recurso | Intervalo | Hook |
|---|---|---|
| Citas / calendario | 15 segundos | `use-appointments.ts` |
| Pagos / comprobantes | 30 segundos | `use-payments.ts` |
| Notificaciones (unread count) | 30 segundos | `use-notifications.ts` |

Con NATS activo, estos pollings se complementan con actualizaciones instantaneas via `queryClient.invalidateQueries()`.

---

## 20. API Client y endpoints

### Cliente HTTP (`lib/api/client.ts`)

Axios centralizado con:
- `baseURL` desde `NEXT_PUBLIC_API_URL`
- Headers `Content-Type: application/json`
- Timeout de 15 segundos
- Interceptor de request (JWT)
- Interceptor de response (refresh token queue)

### Helpers tipados

5 funciones genericas que extraen `response.data` automaticamente:

```typescript
get<T>(url, config?)    // GET
post<T>(url, data?, config?) // POST
put<T>(url, data?, config?)  // PUT
patch<T>(url, data?, config?) // PATCH
del<T>(url, config?)    // DELETE
```

### Mapa de endpoints (`lib/api/endpoints.ts`)

Todos los endpoints estan centralizados en un objeto `ENDPOINTS` constante:

| Grupo | Endpoints |
|---|---|
| `AUTH` | login, register, refresh, me, logout |
| `BUSINESS` | current, onboarding, uploadLogo |
| `SERVICES` | list, create, show(id), update(id), delete(id) |
| `EMPLOYEES` | list, create, show(id), update(id), delete(id) |
| `APPOINTMENTS` | list, create, show(id), update(id), delete(id), confirm, checkin, cancel, complete |
| `CUSTOMERS` | list, show(id) |
| `PAYMENTS` | submit(appointmentId), approve(paymentId), reject(paymentId) |
| `REVIEWS` | list |
| `BUSINESS_HOURS` | show, update |
| `BLOCKED_SLOTS` | CRUD completo |
| `REPORTS` | summary, revenue, topServices, topEmployees, frequentCustomers |
| `QR` | generate |
| `NOTIFICATIONS` | list, unreadCount, markRead(id), markAllRead |
| `PUBLIC` | business(slug), availability(slug), book(slug), ticket(code), explore |

Todos los endpoints usan el prefijo `/api/v1/`.

### Tipos TypeScript (`lib/api/types.ts`)

Interfaces que reflejan exactamente el esquema de la base de datos del backend Rails:

- Modelos: `User`, `Business`, `Employee`, `Service`, `Customer`, `Appointment`, `Payment`, `Review`, `BusinessHour`, `EmployeeSchedule`, `BlockedSlot`, `Subscription`, `Plan`, `DiscountCode`, `BusinessQR`, `AnalyticsEvent`, `AIInsight`, `AIPrediction`
- Enums: `AppointmentStatus`, `PaymentStatus`, `BusinessStatus`, `SubscriptionStatus`, `BusinessType`, `UserRole`, `DayOfWeek`
- Wrappers: `ApiResponse<T>`, `PaginatedResponse<T>` (con metadata de paginacion)

---

## 21. Decisiones tecnicas y trade-offs

### Next.js 16 (App Router)

**Por que**: Framework estandar de React con soporte nativo para SSG (paginas publicas de negocios necesitan SEO), route groups para organizar layouts, y middleware en el edge para proteccion de rutas. Turbopack habilitado para desarrollo rapido.

**Trade-off**: La app es mayormente client-side (SPA con dashboard), por lo que no se aprovecha al maximo SSR. Sin embargo, las paginas publicas (`/[slug]`) si se benefician de SSG.

### Zustand sobre Redux/Context

**Por que**: API minimalista, sin boilerplate, tipado perfecto con TypeScript, middleware de persistencia integrado. Zustand permite acceder al store fuera de React (`getState()`) lo cual es esencial para los interceptores de Axios.

**Trade-off**: Menos tooling de devtools comparado con Redux, pero la simplicidad compensa en un proyecto de este tamano.

### TanStack Query sobre SWR

**Por que**: Invalidacion granular via query keys, mutation helpers, gcTime/staleTime configurables, y mejor soporte para patrones de invalidacion en cascada (e.g., invalidar todas las citas al crear una).

**Trade-off**: Bundle ligeramente mayor que SWR, pero las capacidades de cache y invalidacion justifican la diferencia.

### React Hook Form + Zod v4

**Por que**: React Hook Form minimiza re-renders y tiene excelente performance con formularios grandes (onboarding wizard de 6 pasos). Zod v4 permite definir validacion y tipos TypeScript en un solo lugar.

**Trade-off**: Requiere `@hookform/resolvers` como bridge, pero elimina toda validacion manual.

### Componentes propios sobre Shadcn/Radix

**Por que**: Control total del diseno, sin dependencia de librerias externas para UI, bundle mas ligero. Los componentes son simples wrappers de Tailwind con variantes explicitas.

**Trade-off**: Mas trabajo inicial para construir cada componente, pero evita la complejidad de customizar librerias de terceros.

### Tailwind CSS v4

**Por que**: Utility-first CSS permite prototipar rapido sin salir del JSX. La v4 mejora performance y reduce el bundle CSS.

**Trade-off**: Clases largas en el markup, mitigado con `cn()` para componer clases y el extracto de componentes.

### Axios sobre fetch nativo

**Por que**: Interceptores nativos para JWT (request y response), timeout configurable, y transformacion automatica de JSON. El patron de refresh token queue seria complejo de implementar con fetch puro.

**Trade-off**: Dependencia adicional (~13KB gzip), pero los interceptores son criticos para la experiencia de autenticacion.

### PWA sobre app nativa

**Por que**: Un solo codebase para Android, iOS y desktop. Instalable desde el navegador sin app stores. Fase futura: Capacitor para publicar en stores sin reescribir.

**Trade-off**: Sin acceso a APIs nativas avanzadas (push notifications limitadas en iOS). Se mitiga en fase futura con Capacitor.

### Vitest sobre Jest

**Por que**: Configuracion nativa con Vite/Turbopack, misma API que Jest pero mas rapido (ejecucion en 1.3s para 32 tests), soporte nativo de ESM y TypeScript.

**Trade-off**: Ecosistema de plugins mas pequeno que Jest, pero suficiente para las necesidades actuales.

---

## 22. Variables de entorno

| Variable | Descripcion |
|---|---|
| `NEXT_PUBLIC_API_URL` | URL base del API Rails (e.g., `http://localhost:3001` en dev, `https://api.agendify.com` en prod) |
| `NEXT_PUBLIC_APP_URL` | URL base del frontend (e.g., `http://localhost:3000`) |
| `NEXT_PUBLIC_NATS_WS_URL` | URL WebSocket de NATS para tiempo real (default: `ws://localhost:8222`) |
| `NODE_ENV` | Entorno (`development` deshabilita PWA service worker) |
