# Sidekiq Jobs — Agendity

> Ultima actualizacion: 2026-03-25
> Backend: Rails 8 API + Sidekiq 7.x + sidekiq-cron 2.x + Redis

---

## Resumen

Agendity usa Sidekiq para procesar trabajos en background. Hay dos tipos:

- **Jobs disparados por eventos**: se encolan cuando ocurre algo (nueva reserva, pago confirmado, etc.)
- **Jobs recurrentes (cron)**: se ejecutan automaticamente en un horario definido via `sidekiq-cron`

---

## Configuracion

### config/sidekiq.yml

```yaml
---
:concurrency: 5
:queues:
  - default
  - notifications
  - intelligence
  - mailers
```

- `default` — jobs generales (notificaciones al negocio, alertas de suscripcion, limpieza)
- `notifications` — notificaciones al usuario final (rating request, cashback)
- `intelligence` — jobs de IA (sugerencias de tarifa dinamica)
- `mailers` — reservado para futuros jobs de email dedicados

### config/initializers/sidekiq_cron.rb

```ruby
if Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash!(
    "complete_appointments" => {
      "class"       => "CompleteAppointmentsJob",
      "cron"        => "*/15 * * * *",   # Cada 15 minutos
      "queue"       => "default",
      "description" => "Marca como completadas las citas checked_in cuya hora ya paso"
    },
    "trial_expiry_alerts" => {
      "class"       => "TrialExpiryAlertJob",
      "cron"        => "0 8 * * *",      # Diario 8:00 AM
      "queue"       => "default",
      "description" => "Alertas de trial (2d antes, dia de, +2d suspension, +7d inactivar)"
    },
    "subscription_expiry_alerts" => {
      "class"       => "SubscriptionExpiryAlertJob",
      "cron"        => "0 8 * * *",      # Diario 8:00 AM
      "queue"       => "default",
      "description" => "Alertas de suscripcion (5d antes, dia de, +2d suspension, +7d inactivar)"
    },
    "birthday_campaign" => {
      "class"       => "BirthdayCampaignJob",
      "cron"        => "0 8 * * *",      # Diario 8:00 AM
      "queue"       => "default",
      "description" => "Genera codigos de cumpleanos y envia felicitaciones"
    },
    "pricing_suggestions" => {
      "class"       => "Intelligence::PricingSuggestionJob",
      "cron"        => "0 8 1,15 * *",   # Dia 1 y 15 de cada mes a las 8:00 AM
      "queue"       => "intelligence",
      "description" => "Analiza demanda y genera sugerencias de tarifas (Plan Inteligente)"
    }
  )
end
```

Los jobs se registran automaticamente al iniciar Sidekiq. No requieren configuracion manual.

### Monitoreo

- `/admin/sidekiq` — panel Sidekiq Web: queues, stats, retries, dead jobs
- `/admin/sidekiq/cron` — jobs recurrentes: ultima ejecucion, proximo run, estado
- Protegido con autenticacion basica de ActiveAdmin

---

## Jobs recurrentes (cron)

| Job | Clase | Cola | Frecuencia | Descripcion |
|-----|-------|------|------------|-------------|
| complete_appointments | `CompleteAppointmentsJob` | default | Cada 15 min | Marca `checked_in` → `completed` cuando pasa la hora de fin |
| trial_expiry_alerts | `TrialExpiryAlertJob` | default | Diario 8am | Alertas y suspension/desactivacion por trial vencido (4 stages) |
| subscription_expiry_alerts | `SubscriptionExpiryAlertJob` | default | Diario 8am | Alertas y suspension/desactivacion por suscripcion vencida (4 stages) |
| birthday_campaign | `BirthdayCampaignJob` | default | Diario 8am | Genera codigos de descuento de cumpleanos para negocios con la campana activa |
| pricing_suggestions | `Intelligence::PricingSuggestionJob` | intelligence | Dia 1 y 15, 8am | Analiza demanda historica y crea sugerencias de tarifas dinamicas (Plan Inteligente) |

---

## Jobs disparados por eventos

Estos jobs se encolan mediante `perform_later` desde controllers o service objects cuando ocurre un evento.

### Notificaciones de citas

#### SendNewBookingNotificationJob

- **Cola:** `default`
- **Disparado por:** `CreateAppointmentService` / `BookingsController` al crear una nueva reserva
- **Hace:**
  1. Envia email al negocio (`AppointmentMailer.new_booking`)
  2. Crea notificacion in-app para el negocio
  3. Publica evento NATS (`new_booking`) para actualizar la agenda en tiempo real

#### SendBookingConfirmedJob

- **Cola:** `default`
- **Disparado por:** `ApprovePaymentService` al aprobar el comprobante de pago
- **Hace:**
  1. Notifica al cliente via `MultiChannelService` (email siempre, WhatsApp si Plan Profesional+)
  2. Template: `:booking_confirmed` — incluye datos de la cita + ticket code + QR en el email
  3. Publica evento NATS (`booking_confirmed`)

#### SendBookingCancelledJob

- **Cola:** `default`
- **Disparado por:** `CancelAppointmentService` al cancelar una cita (por negocio o por cliente)
- **Hace:**
  1. Envia email al negocio (`AppointmentMailer.booking_cancelled`)
  2. Crea notificacion in-app para el negocio con texto diferenciado: "Cancelada por [negocio]" vs "El cliente cancelo"
  3. Notifica al cliente via `MultiChannelService` (email + WhatsApp si aplica)
  4. Publica evento NATS (`booking_cancelled`)

#### SendReminderJob

- **Cola:** `default`
- **Disparado por:** `AppointmentReminderSchedulerJob` (un `perform_later` por cada cita del dia siguiente)
- **Hace:**
  1. Verifica que la cita sigue en estado `confirmed`
  2. Notifica al cliente via `MultiChannelService` (email + WhatsApp si Plan Profesional+)
  3. Template: `:appointment_reminder` — fecha, hora, servicio, empleado

#### AppointmentReminderSchedulerJob

- **Cola:** `default`
- **Disparado por:** sidekiq-cron (diario 8am) — **no configurado en sidekiq_cron.rb actualmente, se dispara manualmente o desde recurring.yml legacy**
- **Hace:**
  1. Busca todas las citas `confirmed` para manana (`Date.tomorrow`)
  2. Encola un `SendReminderJob` por cada una

> **Nota:** Este job es el orquestador; el trabajo real lo hace `SendReminderJob`.

### Notificaciones de pagos

#### SendPaymentSubmittedJob

- **Cola:** `default`
- **Disparado por:** `PaymentsController` cuando el usuario sube un comprobante de pago
- **Hace:**
  1. Envia email al negocio (`BusinessMailer.payment_submitted`)
  2. Crea notificacion in-app para el negocio con link al panel de pagos
  3. Publica evento NATS (`payment_submitted`)

### Suscripciones

#### GenerateSubscriptionPaymentOrdersJob

- **Cola:** `default`
- **Disparado por:** schedule (diario 1am — legacy solid_queue; en produccion puede encolarse manualmente)
- **Hace:**
  1. Busca suscripciones activas que vencen en los proximos 7 dias
  2. Crea una `SubscriptionPaymentOrder` en estado `pending` para el siguiente periodo (si no existe ya)
  3. Crea notificacion in-app al negocio avisando de la proxima renovacion

#### SendSubscriptionReminderJob

- **Cola:** `default`
- **Disparado por:** schedule (diario 9am — legacy solid_queue)
- **Hace:**
  1. Busca ordenes de pago pendientes que vencen exactamente en 3 dias
  2. Crea notificacion in-app
  3. Envia email de recordatorio (`BusinessMailer.subscription_payment_reminder`)

#### NotifyAdminSubscriptionProofJob

- **Cola:** `default`
- **Disparado por:** `CheckoutController` cuando el negocio sube comprobante de pago de suscripcion
- **Hace:**
  1. Envia email al admin (`AdminMailer.subscription_proof_received`)
  2. Envia WhatsApp al admin si `SiteConfig.get("admin_whatsapp")` tiene valor
  3. Crea `AdminNotification` para el panel de ActiveAdmin

### Notificaciones post-completado

#### SendRatingRequestJob

- **Cola:** `notifications`
- **Disparado por:** `CompleteAppointmentsJob` al marcar una cita como `completed`
- **Hace:**
  1. Notifica al cliente via `MultiChannelService` (email + WhatsApp si aplica)
  2. Template: `:rating_request` — incluye link a la pagina publica del negocio con scroll a resenas

#### SendCashbackNotificationJob

- **Cola:** `notifications`
- **Disparado por:** `CompleteAppointmentsJob` si `Credits::CashbackService` otorgo creditos
- **Hace:**
  1. Envia email al cliente (`CustomerMailer.cashback_credited`) con el monto otorgado y balance actual
  2. No usa WhatsApp — el cashback se menciona en el mensaje de confirmacion de pago para evitar costos extra de conversacion

### Limpieza

#### CleanupExpiredTokensJob

- **Cola:** `low`
- **Disparado por:** schedule (recomendado: semanal domingo 3am — agregar a sidekiq_cron.rb si se necesita)
- **Hace:**
  1. Elimina `RefreshToken` expirados (`expires_at < Time.current`)
  2. Elimina entradas viejas del `JwtDenylist` (expiradas hace mas de 24 horas)

#### CleanupOldRequestLogsJob

- **Cola:** `low`
- **Disparado por:** schedule (recomendado: diario)
- **Hace:**
  1. Elimina `RequestLog` con `status_code < 400` mas antiguos de 30 dias
  2. Elimina `RequestLog` con `status_code >= 400` mas antiguos de 90 dias

---

## Jobs recurrentes — tabla completa

| Job | Cola | Schedule (cron) | Disparado desde |
|-----|------|-----------------|-----------------|
| `CompleteAppointmentsJob` | default | `*/15 * * * *` | sidekiq-cron |
| `TrialExpiryAlertJob` | default | `0 8 * * *` | sidekiq-cron |
| `SubscriptionExpiryAlertJob` | default | `0 8 * * *` | sidekiq-cron |
| `BirthdayCampaignJob` | default | `0 8 * * *` | sidekiq-cron |
| `Intelligence::PricingSuggestionJob` | intelligence | `0 8 1,15 * *` | sidekiq-cron |
| `AppointmentReminderSchedulerJob` | default | `0 8 * * *` (recomendado) | manual / legacy |
| `CleanupExpiredTokensJob` | low | `0 3 * * 0` (recomendado) | manual / legacy |
| `CleanupOldRequestLogsJob` | low | `0 2 * * *` (recomendado) | manual / legacy |

---

## Jobs disparados por eventos — tabla completa

| Job | Cola | Disparado cuando | Destinatario principal |
|-----|------|-----------------|------------------------|
| `SendNewBookingNotificationJob` | default | Nueva reserva creada | Negocio |
| `SendBookingConfirmedJob` | default | Pago aprobado | Cliente (usuario final) |
| `SendBookingCancelledJob` | default | Cita cancelada | Negocio + Cliente |
| `SendReminderJob` | default | Encola el scheduler (24h antes) | Cliente |
| `SendPaymentSubmittedJob` | default | Cliente sube comprobante | Negocio |
| `NotifyAdminSubscriptionProofJob` | default | Negocio sube comprobante de suscripcion | Admin |
| `GenerateSubscriptionPaymentOrdersJob` | default | Schedule diario | — (crea ordenes) |
| `SendSubscriptionReminderJob` | default | Schedule diario | Negocio |
| `SendRatingRequestJob` | notifications | Cita completada | Cliente |
| `SendCashbackNotificationJob` | notifications | Cita completada + cashback otorgado | Cliente |
| `CleanupExpiredTokensJob` | low | Schedule semanal | — (limpieza DB) |
| `CleanupOldRequestLogsJob` | low | Schedule diario | — (limpieza DB) |

---

## Archivos clave

```
agendity-api/config/sidekiq.yml
agendity-api/config/initializers/sidekiq_cron.rb
agendity-api/app/jobs/application_job.rb
agendity-api/app/jobs/complete_appointments_job.rb
agendity-api/app/jobs/trial_expiry_alert_job.rb
agendity-api/app/jobs/subscription_expiry_alert_job.rb
agendity-api/app/jobs/birthday_campaign_job.rb
agendity-api/app/jobs/intelligence/pricing_suggestion_job.rb
agendity-api/app/jobs/send_new_booking_notification_job.rb
agendity-api/app/jobs/send_booking_confirmed_job.rb
agendity-api/app/jobs/send_booking_cancelled_job.rb
agendity-api/app/jobs/send_reminder_job.rb
agendity-api/app/jobs/appointment_reminder_scheduler_job.rb
agendity-api/app/jobs/send_payment_submitted_job.rb
agendity-api/app/jobs/notify_admin_subscription_proof_job.rb
agendity-api/app/jobs/generate_subscription_payment_orders_job.rb
agendity-api/app/jobs/send_subscription_reminder_job.rb
agendity-api/app/jobs/send_rating_request_job.rb
agendity-api/app/jobs/send_cashback_notification_job.rb
agendity-api/app/jobs/cleanup_expired_tokens_job.rb
agendity-api/app/jobs/cleanup_old_request_logs_job.rb
```
