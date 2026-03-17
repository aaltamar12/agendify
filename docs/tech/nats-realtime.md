# Sistema de Tiempo Real — NATS + Notificaciones del Navegador

> Última actualización: 2026-03-16
> **ADR:** [003-nats-realtime.md](decisiones/003-nats-realtime.md)

## Resumen

Agendity usa un servidor NATS self-hosted para entregar eventos en tiempo real al dashboard del negocio. Cuando ocurre una acción (nueva reserva, pago enviado, cancelación), el backend publica un evento a NATS y el frontend lo recibe vía WebSocket. Al recibir el evento, se ejecutan 3 acciones:

1. **Invalidación de cache** — TanStack Query refresca la data relevante (calendario, pagos, notificaciones)
2. **Notificación del navegador** — Notification API nativa con título y resumen del evento
3. **Sonido de notificación** — Chime generado con Web Audio API (configurable on/off)

Si NATS no está disponible, el sistema cae automáticamente al polling existente (`refetchInterval` cada 15-30s). **No se pierde funcionalidad.**

---

## Arquitectura

```
┌─────────────────┐     NATS protocol     ┌──────────────┐     WebSocket      ┌─────────────────┐
│   Rails API     │ ──────────────────────▶│  NATS Server │◀────────────────── │  Next.js (PWA)  │
│  (Publisher)    │     puerto 4222        │  (Docker)    │     puerto 8222    │  (Subscriber)   │
└─────────────────┘                        └──────────────┘                    └─────────────────┘
```

### Flujo completo

```
1. Usuario final reserva una cita
2. Rails crea la cita → dispara SendNewBookingNotificationJob (Sidekiq)
3. El job publica a NATS: business.123.new_booking (vía NatsPublisher)
4. El dashboard del negocio recibe el mensaje vía WebSocket (use-realtime.ts)
5. use-event-notifications.ts:
   a) Invalida queries de appointments y notifications
   b) Muestra notificación nativa del navegador: "Nueva reserva — Juan reservó Corte de cabello"
   c) Reproduce sonido de notificación (si está habilitado)
```

---

## Backend — NatsPublisher

**Archivo:** `app/services/realtime/nats_publisher.rb`
**Gema:** `nats-pure`

```ruby
# Publicar evento a NATS
Realtime::NatsPublisher.publish(
  business_id: 123,
  event: "new_booking",
  data: { customer_name: "Juan", service_name: "Corte de cabello" }
)
```

- Conexión lazy al servidor NATS (`NATS_URL` o `nats://localhost:4222`)
- Si NATS no está disponible, logea el error y retorna silenciosamente
- Subject format: `business.<id>.<event_name>`
- Payload JSON: `{ event, data, timestamp }`

### Jobs que publican eventos

| Job (Sidekiq) | Evento | Momento |
|---|---|---|
| `SendNewBookingNotificationJob` | `new_booking` | Al crear una reserva pública |
| `SendBookingConfirmedJob` | `booking_confirmed` | Al aprobar el pago de una cita |
| `SendBookingCancelledJob` | `booking_cancelled` | Al cancelar una cita |
| `SendPaymentSubmittedJob` | `payment_submitted` | Al subir un comprobante de pago |

### Inicializador

**Archivo:** `config/initializers/nats.rb`

Pre-carga la conexión al arrancar Rails (para evitar lazy-loading en el primer request).

---

## Frontend — Hooks y utilidades

### `use-realtime.ts`

**Archivo:** `src/lib/hooks/use-realtime.ts`

Hook principal que gestiona la conexión WebSocket a NATS. Se activa en el layout del dashboard (`src/app/dashboard/layout.tsx`).

```typescript
// En dashboard/layout.tsx
useRealtime(); // Se conecta a NATS y empieza a escuchar eventos
```

**Comportamiento:**
- Importa `nats.ws` dinámicamente (solo en el cliente)
- Se conecta a `NEXT_PUBLIC_NATS_WS_URL` (default: `ws://localhost:8222`)
- Se suscribe a `business.<businessId>.>` (wildcard para todos los eventos del negocio)
- Al recibir un mensaje, delega a `useEventNotifications` para procesarlo
- Si la conexión falla, logea warning en consola y el polling existente sigue funcionando
- Limpieza automática al desmontar (unsubscribe + close)

### `use-event-notifications.ts`

**Archivo:** `src/lib/hooks/use-event-notifications.ts`

Procesa cada evento recibido de NATS y ejecuta 3 acciones:

1. **Invalidación de queries:**
   - Eventos de booking (`new_booking`, `booking_cancelled`, `booking_confirmed`) → invalida `['appointments']`
   - Evento `payment_submitted` → invalida `['payments']`
   - Todos los eventos → invalida `['notifications']` y `['notificationsUnreadCount']`

2. **Notificación del navegador:**
   - Usa la Notification API nativa del navegador
   - Muestra título y cuerpo personalizado por tipo de evento
   - Auto-cierra en 5 segundos
   - Click en la notificación → foco en la ventana del dashboard

3. **Sonido de notificación:**
   - Solo si el usuario lo tiene habilitado (configurable en Settings)
   - Genera un chime de dos tonos con Web Audio API

### Configuración de eventos

| Evento | Título | Ejemplo de cuerpo |
|---|---|---|
| `new_booking` | "Nueva reserva" | "Juan reservó Corte de cabello" |
| `payment_submitted` | "Comprobante recibido" | "Juan envió un comprobante de pago" |
| `booking_cancelled` | "Cita cancelada" | "Juan canceló su cita" |
| `booking_confirmed` | "Pago confirmado" | "Pago confirmado para Juan" |

---

## Notificaciones del navegador

**Archivo:** `src/lib/utils/browser-notification.ts`

Wrapper sobre la Notification API nativa:

- `requestNotificationPermission()` — Solicita permiso al usuario. Retorna `true` si fue concedido.
- `showBrowserNotification(title, options)` — Muestra una notificación nativa con:
  - Icono de la app (`/icons/icon-192x192.png`)
  - Tag único para evitar duplicados
  - Auto-cierre en 5 segundos
  - Click → `window.focus()` + cerrar notificación

**Gestión de permisos en Settings:**

La página de configuración (`/dashboard/settings`) incluye una `NotificationSection` que:
- Muestra el estado actual del permiso (Activadas / Bloqueadas / No disponible)
- Botón "Activar" para solicitar permiso si no ha sido otorgado
- Mensaje de ayuda si el usuario bloqueó las notificaciones

---

## Sonido de notificación

**Archivo:** `src/lib/utils/notification-sound.ts`

Genera un chime de dos tonos usando Web Audio API pura (sin archivo de audio externo):

- Nota 1: D5 (587.33 Hz) — 0.15s
- Nota 2: A5 (880 Hz) — 0.3s
- Onda sinusoidal con fade-out exponencial
- Falla silenciosamente si el audio no está disponible (ej: página en background)

**Toggle on/off:**

El estado `notificationSoundEnabled` se almacena en `ui-store` (Zustand) y se persiste en localStorage (`agendity-ui`). Se puede activar/desactivar desde `/dashboard/settings` → sección "Notificaciones".

---

## Ejecutar NATS localmente

### Requisitos

- Docker instalado

### Opción 1: Con archivo de configuración (recomendada)

```bash
docker run -d --name agendity-nats \
  -p 4222:4222 \
  -p 8222:8222 \
  -v $(pwd)/docker/nats.conf:/etc/nats/nats.conf \
  nats:latest \
  -c /etc/nats/nats.conf
```

**Archivo de configuración** (`docker/nats.conf`):

```
listen: 0.0.0.0:4222
websocket {
  listen: "0.0.0.0:8222"
  no_tls: true
}
```

### Opción 2: Rápido sin config

```bash
docker run -d --name agendity-nats \
  -p 4222:4222 \
  -p 8222:8222 \
  nats:latest \
  --websocket_port 8222
```

### Puertos

| Puerto | Protocolo | Uso |
|---|---|---|
| `4222` | NATS (TCP) | Backend Rails se conecta aquí para publicar |
| `8222` | WebSocket | Frontend Next.js se conecta aquí para suscribirse |

### Verificar que funciona

```bash
# Ver logs
docker logs agendity-nats

# Health check
curl http://localhost:8222/healthz
```

---

## Variables de entorno

### Backend (`.env`)

| Variable | Default | Descripción |
|---|---|---|
| `NATS_URL` | `nats://localhost:4222` | URL del servidor NATS (protocolo nativo) |

### Frontend (`.env.local`)

| Variable | Default | Descripción |
|---|---|---|
| `NEXT_PUBLIC_NATS_WS_URL` | `ws://localhost:8222` | URL del servidor NATS (WebSocket) |

---

## Fallback a polling

NATS es una **mejora progresiva**. El sistema funciona completamente sin NATS:

| Componente | Sin NATS (polling) | Con NATS (real-time) |
|---|---|---|
| Citas en calendario | Polling cada 15s | Actualización instantánea |
| Pagos/comprobantes | Polling cada 30s | Actualización instantánea |
| Notificaciones (campanita) | Polling cada 30s | Actualización instantánea + sonido + notificación nativa |

**Backend:** `NatsPublisher.publish` captura errores silenciosamente y los logea. Ningún job falla por NATS.

**Frontend:** `useRealtime` captura errores de conexión y logea warning en consola. El `refetchInterval` de TanStack Query sigue activo como fallback.

---

## Seguridad (producción)

- NATS corre dentro de la red Docker, no expuesto públicamente al internet
- Solo el puerto WebSocket (8222) se expone vía Nginx con TLS (wss://)
- Auth tokens configurables en `nats.conf` para restringir acceso
- Los subjects están scoped por `business_id` — un negocio no puede ver eventos de otro

---

## Archivos relevantes

| Archivo | Repositorio | Descripción |
|---|---|---|
| `app/services/realtime/nats_publisher.rb` | agendity-api | Publisher de eventos a NATS |
| `config/initializers/nats.rb` | agendity-api | Pre-carga de conexión |
| `app/jobs/send_new_booking_notification_job.rb` | agendity-api | Job que publica `new_booking` |
| `app/jobs/send_booking_confirmed_job.rb` | agendity-api | Job que publica `booking_confirmed` |
| `app/jobs/send_booking_cancelled_job.rb` | agendity-api | Job que publica `booking_cancelled` |
| `app/jobs/send_payment_submitted_job.rb` | agendity-api | Job que publica `payment_submitted` |
| `docker/nats.conf` | raíz del proyecto | Configuración del servidor NATS |
| `src/lib/hooks/use-realtime.ts` | agendity-web | Hook de conexión NATS WebSocket |
| `src/lib/hooks/use-event-notifications.ts` | agendity-web | Procesador de eventos → invalidación + notificaciones |
| `src/lib/utils/browser-notification.ts` | agendity-web | Wrapper de Notification API |
| `src/lib/utils/notification-sound.ts` | agendity-web | Generador de sonido con Web Audio API |
| `src/app/dashboard/layout.tsx` | agendity-web | Donde se activa `useRealtime()` |
