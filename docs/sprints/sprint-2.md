# Sprint 2 — Features pequeñas (2-3 días)

- [x] **2.1** Trial de 7 → 25 días
  - `agendity-api/app/services/auth/register_service.rb` — `25.days.from_now`
  - `agendity-api/app/jobs/trial_expiry_alert_job.rb` — Stage 1: 5d antes, Stage 4: +10d
  - `agendity-api/app/views/business_mailer/trial_expiry_alert_stage_1.html.erb`
  - `desarrollo.md` + `docs/tech/alertas-suscripcion.md` actualizados
  - Specs: 33 passing (register_service + trial_expiry_alert_job)

- [x] **2.2** Actualizar precios de planes (Básico $9, Pro $22, Inteligente $27)
  - Precios en DB + seeds actualizados
  - TRM 3,667 en SiteConfig + auto-cálculo en ActiveAdmin
  - Features (jsonb) editables desde ActiveAdmin
  - Componente compartido PlanCard + endpoint público /api/v1/public/plans

- [x] **2.3** Bre-B en métodos de pago del negocio
  - `agendity-api/` migration + encrypts + serializer + controller
  - `agendity-web/` settings + onboarding + booking confirmation + ticket page
  - Specs: 34 passing (business_spec con encriptación de breb_key)

- [x] **2.4** Profesional independiente: foto de perfil (no logo/cover)
  - `agendity-web/src/app/dashboard/settings/page.tsx` — "Foto de perfil" circular cuando independent
  - CoverSection oculta para independientes
  - Explore ya excluye independientes (scope `.establishments`)

- [x] **2.5** Planes detallados en banner de suscripción expirada / TrialBlockScreen
  - TrialBlockScreen usa PlanCard compartido con features del API

- [x] **2.6** Planes detallados en checkout (features en PlanCard)
  - Checkout usa PlanCard compartido
