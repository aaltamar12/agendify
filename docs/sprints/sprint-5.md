# Sprint 5 — Features grandes parte 2 (2-3 días)

- [x] **5.1** Comprobante de pago para empleado al cierre del día
  - EmployeeMailer#payment_receipt + template HTML estilo recibo
  - PDF via Grover (HTML→PDF) con layout dedicado
  - SendEmployeePaymentReceiptJob — se enqueue al cerrar caja
  - Endpoint: `GET /api/v1/cash_register/:id/employee_payments/:id/receipt` (PDF)
  - Frontend: botón "Descargar recibo" en historial de cierres
  - Specs: 9 passing (mailer + job + PDF service)

- [x] **5.2** Birthday: notificación al negocio + one-click send (Plan Inteligente)
  - BirthdayCampaignJob: crea notificación in-app al owner con metadata {customer_id}
  - Endpoint: `POST /api/v1/customers/:id/send_birthday_greeting`
  - Plan enforcement: solo ai_features? (Plan Inteligente + trial)
  - Frontend: botón "Enviar saludo" en notificaciones tipo birthday
  - Icono torta (Cake) + color rosa en notification bell
  - NATS event + browser notification para birthday
  - Specs: 4 passing (endpoint con/sin plan + trial + 404)

- [x] **5.3** Info adicional al confirmar comprobante + flag virtual business
  - Migrations: `virtual_business` (boolean) en businesses, `additional_info` (text) en payments
  - SubmitPaymentService acepta y guarda additional_info
  - Email de comprobante incluye additional_info si presente
  - ActiveAdmin: checkbox "Negocio virtual" en businesses
  - Frontend: textarea "Información adicional" solo cuando business.virtual_business
  - Serializer: virtual_business excluido de vistas public/explore
  - Specs: 5 passing (service + mailer)
