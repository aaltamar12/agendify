# ADR 003 — NATS como sistema de mensajería real-time

> **Fecha:** 2026-03-16
> **Estado:** Aceptada
> **Contexto:** Dashboard del negocio en Agendify necesita actualizaciones en tiempo real

## Problema

Cuando un usuario final reserva una cita, sube un comprobante de pago o cancela, el negocio necesita ver estos cambios reflejados inmediatamente en su dashboard sin necesidad de refrescar la página manualmente.

### Requisitos

1. **Latencia baja:** El negocio debe ver eventos en menos de 1 segundo
2. **Simplicidad operativa:** Debe correr en un solo VPS con Docker Compose
3. **Degradación elegante:** Si el sistema de real-time falla, la app debe seguir funcionando
4. **Notificaciones nativas:** Alertas visibles incluso si el dashboard no está en primer plano

## Decisión

Usar **NATS** como servidor de mensajería self-hosted con conexión WebSocket al frontend. El patrón es pub/sub: el backend publica eventos a NATS y el frontend se suscribe vía `nats.ws`.

### Arquitectura elegida

```
Rails API → Sidekiq Job → NatsPublisher → NATS Server ← WebSocket ← Next.js Dashboard
                                            (Docker)
```

- **Backend:** Gema `nats-pure` para publicar mensajes al servidor NATS
- **Frontend:** Librería `nats.ws` para suscribirse vía WebSocket
- **Servidor:** Contenedor Docker con imagen oficial `nats:latest`
- **Puertos:** 4222 (NATS nativo, backend) + 8222 (WebSocket, frontend)
- **Subjects:** `business.<id>.<event>` — un namespace por negocio

### Complementos

- **Browser Notification API** — Notificaciones nativas del sistema operativo
- **Web Audio API** — Sonido de alerta generado por síntesis (sin archivos de audio)
- **TanStack Query invalidation** — Al recibir evento, se invalidan las queries relevantes

## Alternativas consideradas

### Action Cable (Rails built-in WebSocket)

- **Rechazada:** Action Cable requiere mantener conexiones WebSocket directamente en el proceso de Rails/Puma. Esto consume threads del servidor y escala peor bajo carga. Además, acopla el real-time al backend — si Rails se reinicia, se pierden todas las conexiones.
- **Ventaja no aprovechada:** Integración nativa con Rails. Pero como nuestro frontend es Next.js (no Rails views), esta ventaja desaparece.

### MQTT (Mosquitto)

- **Rechazada:** MQTT está diseñado para IoT con clientes de bajo ancho de banda. El soporte WebSocket existe pero no es nativo — requiere configuración adicional. NATS es más adecuado para aplicaciones web.
- **Ventaja no relevante:** QoS levels y retención de mensajes. No necesitamos garantía de entrega porque tenemos polling como fallback.

### Polling puro (sin WebSocket)

- **Rechazada como solución única:** El polling cada 15-30 segundos genera latencia perceptible y requests innecesarios al backend. Sin embargo, se mantiene como **fallback** cuando NATS no está disponible.
- **Ventaja conservada:** Sigue activo como red de seguridad. NATS es una mejora progresiva.

### Server-Sent Events (SSE)

- **Rechazada:** SSE es unidireccional (server → client), lo cual es suficiente para nuestro caso. Sin embargo, mantener conexiones SSE abiertas en Rails tiene los mismos problemas de escalabilidad que Action Cable. NATS desacopla las conexiones del backend.

### Servicios de terceros (Pusher, Ably, Firebase)

- **Rechazada:** Dependencia externa, costos recurrentes por mensaje, y latencia adicional. Agendify corre en un solo VPS — un servidor NATS local agrega ~20MB de RAM y latencia sub-milisegundo.

## Por qué NATS

| Criterio | NATS | Action Cable | MQTT | Polling |
|---|---|---|---|---|
| Desacople del backend | Si | No | Si | N/A |
| WebSocket nativo | Si | Si | Config | No |
| Overhead en Rails | Ninguno | Alto (threads) | Ninguno | Medio (requests) |
| Latencia | Sub-ms | ~100ms | ~100ms | 15-30s |
| Complejidad operativa | Baja (1 container) | Media | Media | Ninguna |
| Degradación elegante | Si (fallback a polling) | No (se pierde real-time) | No | N/A |
| Memoria | ~20MB | Variable | ~10MB | N/A |

## Consecuencias

### Positivas

- **Actualizaciones instantáneas** — El negocio ve cambios en menos de 1 segundo
- **Notificaciones nativas** — El negocio recibe alertas visibles y audibles
- **Cero impacto en Rails** — NATS maneja todas las conexiones WebSocket, Rails solo publica
- **Resiliente** — Si NATS cae, el polling sigue funcionando sin interrupción
- **Simple de operar** — Un contenedor Docker, sin clustering, sin configuración compleja

### Negativas

- **Dependencia adicional** — NATS es un servicio más que mantener (mitigado: es un solo contenedor estable)
- **Sin garantía de entrega** — Si el frontend no está conectado cuando llega un evento, lo pierde (mitigado: polling como fallback + invalidación de cache)
- **Sin autenticación por defecto** — En desarrollo, NATS acepta cualquier conexión (mitigado: en producción, NATS corre en red Docker interna + auth tokens en nats.conf)

## Implementación

### Backend

- `app/services/realtime/nats_publisher.rb` — Publisher singleton con conexión lazy
- `config/initializers/nats.rb` — Pre-carga de conexión al arrancar
- 4 Sidekiq jobs publican eventos: `SendNewBookingNotificationJob`, `SendBookingConfirmedJob`, `SendBookingCancelledJob`, `SendPaymentSubmittedJob`

### Frontend

- `src/lib/hooks/use-realtime.ts` — Hook de conexión NATS WebSocket, se activa en `dashboard/layout.tsx`
- `src/lib/hooks/use-event-notifications.ts` — Procesa eventos → invalidación + notificación + sonido
- `src/lib/utils/browser-notification.ts` — Wrapper de Notification API
- `src/lib/utils/notification-sound.ts` — Chime con Web Audio API
- `src/app/dashboard/settings/page.tsx` → `NotificationSection` — Configuración de permisos y sonido

### Infraestructura

- `docker/nats.conf` — Configuración del servidor NATS
- Variables de entorno: `NATS_URL` (backend), `NEXT_PUBLIC_NATS_WS_URL` (frontend)

## Referencias

- [Documentación de NATS](https://docs.nats.io/)
- [nats.ws — Cliente JavaScript para WebSocket](https://github.com/nats-io/nats.ws)
- [nats-pure — Cliente Ruby](https://github.com/nats-io/nats-pure.rb)
- `docs/tech/nats-realtime.md` — Documentación técnica completa del sistema
