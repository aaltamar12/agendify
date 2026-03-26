# Sprint 4 — Features grandes parte 1 (3-4 días)

- [x] **4.1** Notificación confirmación + recordatorio 30 min antes
  - Job: `SendAppointmentReminder30minJob` — se programa al confirmar pago
  - Mailer: `AppointmentMailer#reminder_30min` + template HTML
  - Se programa con `set(wait_until:)` al confirmar (ConfirmPaymentService, ApprovePaymentService, CreateAppointmentService)
  - Email + WhatsApp via MultiChannelService
  - Specs: 7 passing

- [x] **4.2** Countdown timer en ticket
  - Componente: `countdown-timer.tsx` con actualización cada segundo
  - Integrado en ticket page (básico y VIP) cuando status = confirmed
  - Muestra "Xh XXm XXs para tu cita" → "¡Tu cita es ahora!" al llegar a 0
  - Soporte dark theme para ticket VIP

- [x] **4.3** Rating: nombre profesional en email + página dedicada + WhatsApp
  - Job: employee_name agregado a datos de notificación
  - Email: "¿Cómo fue tu experiencia con {employee} en {business}?"
  - URL: `/{slug}/rate?appointment={id}` (ya no #reviews)
  - Página `/rate`: estrellas clickeables, comentario, datos de la cita
  - Endpoint público: `GET /api/v1/public/:slug/rate` + `POST /api/v1/public/:slug/reviews`
  - Hooks: `useRatingPage()`, `useCreateReview()`

- [x] **4.4** Puntuación de profesional y negocio (scores separados)
  - Migration: `rating_average` + `total_reviews` en employees (cached)
  - Review model: callback `after_create/destroy :update_employee_rating`
  - EmployeeSerializer: campos cacheados + `rating_avg` calculado (backward compat)
  - Employee selector en booking: muestra estrellas + conteo de reviews
  - Specs: 3 nuevos (13 total passing)
