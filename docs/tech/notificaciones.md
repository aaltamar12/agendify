# Sistema de Notificaciones — Agendify

> Última actualización: 2026-03-16

## Canales implementados

| Canal | Estado | Tecnología |
|---|---|---|
| **In-app** (campanita) | Implementado | PostgreSQL + polling 30s |
| **Email** | Implementado (mailers) | Action Mailer + Sidekiq |
| **WhatsApp** | Pendiente | WhatsApp Business API |
| **Push** | Pendiente | Capacitor (fase futura) |

---

## Notificaciones In-App

### Modelo de datos

```sql
CREATE TABLE notifications (
  id bigint PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id),
  title varchar NOT NULL,
  body text,
  notification_type varchar NOT NULL,
  link varchar,
  read boolean DEFAULT false,
  created_at timestamp,
  updated_at timestamp
);
```

**Tipos:**
- `new_booking` — Nueva reserva creada
- `payment_submitted` — Comprobante de pago subido
- `booking_cancelled` — Cita cancelada
- `payment_approved` — Pago aprobado
- `reminder` — Recordatorio

### API Endpoints

```bash
# Listar notificaciones (paginadas)
GET /api/v1/notifications?page=1

# Contar no leídas
GET /api/v1/notifications/unread_count

# Marcar una como leída
POST /api/v1/notifications/:id/mark_read

# Marcar todas como leídas
POST /api/v1/notifications/mark_all_read
```

### Frontend

**Campanita en topbar** (`components/layout/notification-bell.tsx`):
- Ícono Bell con badge rojo (count de no leídas)
- Polling cada 30 segundos vía `useUnreadCount()`
- Dropdown con las 5 notificaciones más recientes
- Click → marca como leída + navega al link
- "Ver todas" → `/dashboard/notifications`

**Página de notificaciones** (`app/dashboard/notifications/page.tsx`):
- Lista paginada completa
- Cards con íconos por tipo
- Indicador visual de no leída (borde violeta)
- "Marcar todas como leídas"

---

## Email (Action Mailer)

### Mailers

**`AppointmentMailer`:**
| Método | Destinatario | Evento |
|---|---|---|
| `new_booking` | Negocio | Nueva reserva creada |
| `booking_confirmed` | Cliente | Pago aprobado + ticket |
| `booking_cancelled` | Ambos | Cita cancelada |
| `reminder` | Cliente | 24h antes de la cita |

**`BusinessMailer`:**
| Método | Destinatario | Evento |
|---|---|---|
| `payment_submitted` | Negocio | Comprobante subido |

### Diseño de emails
- Layout HTML con header violeta + branding Agendify
- Versión texto plano para cada email
- Todos los textos en español

---

## Background Jobs (Sidekiq)

| Job | Trigger | Qué hace |
|---|---|---|
| `SendNewBookingNotificationJob` | Booking creado | Email al negocio + notificación in-app |
| `SendPaymentSubmittedJob` | Comprobante subido | Email al negocio + notificación in-app |
| `SendBookingConfirmedJob` | Pago aprobado | Email al cliente con ticket |
| `SendBookingCancelledJob` | Cita cancelada | Email a ambos + notificación in-app |
| `SendReminderJob` | Scheduler diario | Email recordatorio al cliente |
| `AppointmentReminderSchedulerJob` | Cron 8am diario | Encola reminders para citas de mañana |
| `CleanupExpiredTokensJob` | Cron domingo 3am | Limpia tokens expirados |

### Scheduled Jobs (`config/recurring.yml`)

```yaml
reminder_scheduler:
  class: AppointmentReminderSchedulerJob
  schedule: every day at 8am

token_cleanup:
  class: CleanupExpiredTokensJob
  schedule: every sunday at 3am
```
