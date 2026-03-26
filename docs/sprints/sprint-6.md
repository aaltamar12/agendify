# Sprint 6 — Features complejas (3-4 días)

- [ ] **6.1** Mensaje de bienvenida via link/QR compartido
  - `agendity-web/src/components/shared/welcome-modal.tsx` (nuevo)
  - Detectar `?ref=shared` en URL pública
  - localStorage para mostrar una sola vez por slug
  - Dashboard: agregar `?ref=shared` al copiar URL/QR

- [ ] **6.2** Cambio inmediato de precios (notificación)
  - Job/mailer para notificar negocios con suscripción activa del cambio
  - No requiere migration adicional
  - **Dep:** requiere 2.2 (precios actualizados)

- [ ] **6.3** Contenido legal completo de T&C y Privacy Policy
  - `agendity-web/src/app/terms/page.tsx` — contenido real
  - `agendity-web/src/app/privacy/page.tsx` — contenido real
  - Ley 1581/2012, Ley 1266/2008, WhatsApp Business API compliance
  - Revisión posterior con abogado colombiano
  - **Dep:** requiere 3.3 (páginas placeholder)
