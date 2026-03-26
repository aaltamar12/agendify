# Sprint 2 — Features pequeñas (2-3 días)

- [ ] **2.1** Trial de 7 → 25 días
  - `agendity-api/app/services/register_service.rb`
  - `agendity-api/app/jobs/trial_expiry_alert_job.rb`
  - `agendity-web/src/app/page.tsx` (landing: "7 días" → "25 días")
  - Email templates de trial

- [ ] **2.2** Actualizar precios de planes (Básico $9.9, Pro $19, Inteligente $27)
  - `agendity-api/db/seeds.rb` (precios USD en tabla `plans`)
  - Agregar `trm_rate` a SiteConfig
  - COP calculado dinámicamente: USD * TRM
  - `agendity-web/` landing + checkout muestran COP

- [ ] **2.3** Bre-B en métodos de pago del negocio
  - `agendity-api/` migration: `add_column :businesses, :breb_key, :string`
  - `agendity-api/app/models/business.rb` — `encrypts :breb_key`
  - `agendity-web/src/app/dashboard/settings/page.tsx`
  - `agendity-web/` onboarding step payment + booking confirmation + ticket

- [ ] **2.4** Profesional independiente: foto de perfil (no logo/cover)
  - `agendity-web/src/app/dashboard/settings/page.tsx` — upload circular cuando `isIndependent=true`

- [ ] **2.5** Planes detallados en banner de suscripción expirada / TrialBlockScreen *(en progreso)*
  - `agendity-web/src/components/layout/subscription-banner.tsx`
  - Botón "Comparar planes" → checkout

- [x] **2.6** Planes detallados en checkout (features en PlanCard)
  - `agendity-web/src/app/dashboard/subscription/checkout/page.tsx`
  - `agendity-web/src/lib/constants.ts` — `PLAN_FEATURES_COMPARISON`
