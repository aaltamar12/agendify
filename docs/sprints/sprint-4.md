# Sprint 4 — Features grandes parte 1 (3-4 días)

- [ ] **4.1** Notificación confirmación + recordatorio 30 min antes
  - `agendity-api/app/jobs/send_appointment_reminder_30min_job.rb` (nuevo)
  - Email template: "Tu cita es en 30 minutos"
  - Sidekiq scheduled job al confirmar cita
  - **Complementa:** 4.2 (countdown)

- [ ] **4.2** Countdown timer en ticket
  - `agendity-web/src/components/shared/countdown-timer.tsx` (nuevo)
  - `agendity-web/src/app/[slug]/ticket/[code]/page.tsx`
  - Muestra "Faltan X horas Y minutos", actualización cada segundo

- [ ] **4.3** Rating: nombre profesional en email + página dedicada + WhatsApp
  - `agendity-api/app/jobs/send_rating_request_job.rb` — agregar `employee_name`
  - `agendity-web/src/app/[slug]/rate/page.tsx` (nueva)
  - URL: `/{slug}/rate?appointment={id}`
  - Template WhatsApp con link a rating
  - **Dep:** prerequisito de 4.4

- [ ] **4.4** Puntuación de profesional y negocio (scores separados)
  - `agendity-api/` migration: `rating_average` + `total_reviews` en `employees`
  - `agendity-api/app/models/review.rb` — callback `after_save :update_employee_rating`
  - `agendity-web/` mostrar rating de empleado en página pública + employee portal
  - **Dep:** requiere 4.3
