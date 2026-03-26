# Sprint 5 — Features grandes parte 2 (2-3 días)

- [ ] **5.1** Comprobante de pago para empleado al cierre del día
  - `agendity-api/app/mailers/employee_mailer.rb` — `#payment_receipt`
  - `agendity-api/app/services/cash_register/generate_payment_receipt_service.rb` (nuevo)
  - `agendity-api/app/jobs/send_employee_payment_receipt_job.rb` (nuevo)
  - Endpoint: `GET /api/v1/cash_register/:id/employee_payments/:id/receipt.pdf`
  - `agendity-web/` botón "Descargar recibo" en history + employee portal

- [ ] **5.2** Birthday: notificación al negocio + one-click send (Plan Inteligente)
  - `agendity-api/app/jobs/birthday_campaign_job.rb` — notificación in-app al owner
  - Endpoint: `POST /api/v1/customers/:id/send_birthday_greeting`
  - Plan enforcement: solo Plan Inteligente
  - `agendity-web/` botón "Enviar saludo" en notificaciones

- [ ] **5.3** Info adicional al confirmar comprobante + flag virtual business
  - `agendity-api/` migrations: `virtual_business` en businesses, `additional_info` en payments
  - `agendity-api/app/mailers/` incluir `additional_info` en email de comprobante
  - `agendity-web/` campo de texto en upload de comprobante (si `virtual_business`)
  - ActiveAdmin: checkbox "Negocio virtual"
