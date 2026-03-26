# Sprint 3 — Features medianas (3-4 días)

- [ ] **3.1** Check-in mejorado: saludo + última visita
  - `agendity-api/` respuesta de check-in: `last_visit`, `visit_count`
  - `agendity-web/src/app/dashboard/checkin/page.tsx`

- [ ] **3.2** Smart dynamic pricing (regla del 60%)
  - `agendity-web/src/components/booking/` — lógica de agrupación de tarifas dinámicas
  - Constante `DYNAMIC_PRICING_GROUP_THRESHOLD = 0.6`

- [ ] **3.3** Términos y Condiciones + Política de Privacidad (estructura)
  - `agendity-web/src/app/terms/page.tsx` (nueva)
  - `agendity-web/src/app/privacy/page.tsx` (nueva)
  - `agendity-api/` migration: `add_column :users, :terms_accepted_at, :datetime`
  - Checkbox en registro, texto en checkout, links en footer
  - **Dep:** contenido real se redacta en Sprint 6.3

- [ ] **3.4** Bre-B y cuenta bancaria en referido
  - `agendity-api/` migration: `bank_account`, `bank_name`, `breb_key` en `referral_codes`
  - `agendity-api/app/admin/referral_codes.rb`
  - **Dep:** prerequisito de 3.5

- [ ] **3.5** Unificar panel de referidos en SuperAdmin
  - `agendity-api/app/admin/referral_codes.rb` — vista show mejorada
  - Tabla de usos, resumen de comisiones, batch action "Marcar como pagado"
  - **Dep:** requiere 3.4

- [ ] **3.6** Habilitar programa de referidos al público
  - `agendity-web/src/app/referral/page.tsx` (nueva)
  - `agendity-api/` endpoint: `POST /api/v1/public/referral_codes`
  - Auto-generación inmediata de código (sin aprobación admin)
  - Link en footer de landing
