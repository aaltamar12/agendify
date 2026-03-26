# Sprint 3 — Features medianas (3-4 días)

- [x] **3.1** Check-in mejorado: saludo + última visita
  - Backend: CheckinService retorna `customer_name`, `last_visit`, `visit_count`
  - Frontend: saludo personalizado, badge visita #N, "Salúdalo por su nombre", última visita
  - Specs: 11 passing (6 nuevos)

- [x] **3.2** Smart dynamic pricing (regla del 60%)
  - `usePricePreviewMulti` hook para múltiples servicios en paralelo
  - Si ≥60% servicios comparten pricing → mensaje agrupado arriba
  - Constante `DYNAMIC_PRICING_GROUP_THRESHOLD = 0.6`

- [x] **3.3** Términos y Condiciones + Política de Privacidad
  - Páginas: `/terms` y `/privacy` con contenido basado en Ley 1581/2012
  - Registro: checkbox obligatorio + `terms_accepted_at` en User
  - Checkout: texto recordatorio "Al pagar aceptas nuestros T&C"
  - Footer: columna Legal con links
  - Specs: 23 passing (2 nuevos para terms validation)

- [x] **3.4** Bre-B y cuenta bancaria en referido
  - Migration: `bank_account`, `bank_name`, `breb_key` en referral_codes
  - ActiveAdmin: campos editables + panel "Datos de Pago" en show

- [x] **3.5** Unificar panel de referidos en SuperAdmin
  - Panel "Resumen de Referidos" con métricas (total, activados, comisión pendiente/pagada)
  - Batch action "Marcar como pagados" en referrals
  - Show de referral muestra datos de pago del referidor

- [x] **3.6** Habilitar programa de referidos al público
  - Endpoint: `POST /api/v1/public/referral_codes` (auto-generación inmediata)
  - Página pública `/referral` con explicación + formulario
  - Link en footer de landing
  - Specs: 5 passing (referral signup endpoint)
