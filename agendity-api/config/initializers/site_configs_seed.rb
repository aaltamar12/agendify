# frozen_string_literal: true

# Auto-creates SiteConfig keys on Rails boot.
# Keys are fixed — admin can only edit values, not create/delete keys.
# Safe to run multiple times (find_or_create_by).

Rails.application.config.after_initialize do
  next if Rails.env.test?
  next unless ActiveRecord::Base.connection.table_exists?("site_configs")

  [
    # --- Visible al usuario final (frontend + emails) ---
    { key: "company_name",       value: "Agendity",              description: "Nombre de la empresa. Visible en: frontend (API publica), emails, footer" },
    { key: "support_email",      value: "soporte@agendity.com",  description: "Email de soporte. Visible en: frontend (help button via API), emails de trial/cancelacion/bienvenida al negocio" },
    { key: "support_whatsapp",   value: "+573001234567",         description: "WhatsApp de soporte. Visible en: frontend (help button via API), emails de trial/cancelacion/bienvenida al negocio" },

    # --- Datos de pago de Agendity (checkout de suscripcion) ---
    { key: "payment_nequi",      value: "3001234567",            description: "Nequi de Agendity. Visible en: checkout de suscripcion (frontend via API). Los negocios transfieren aqui para pagar su plan" },
    { key: "payment_bancolombia", value: "12345678901",          description: "Cuenta Bancolombia de Agendity. Visible en: checkout de suscripcion (frontend via API)" },
    { key: "payment_daviplata",  value: "3001234567",            description: "Daviplata de Agendity. Visible en: checkout de suscripcion (frontend via API)" },

    # --- Solo para el equipo Agendity (no visible al usuario) ---
    { key: "admin_email",        value: "admin@agendity.com",    description: "Email del admin. Uso interno: destinatario de AdminMailer (notificacion cuando suben comprobante de suscripcion)" },
    { key: "admin_whatsapp",     value: "+573001234567",         description: "WhatsApp del admin. Uso interno: NotifyAdminSubscriptionProofJob envia mensaje cuando suben comprobante" },

    # --- URLs del sistema (usadas en emails, no en frontend) ---
    { key: "app_url",            value: "http://localhost:3000", description: "URL del frontend. Uso interno: genera links en emails (Ver ticket, Ir al dashboard, Reservar). Cambiar a https://agendity.co en produccion" },
    { key: "admin_url",          value: "http://localhost:3001", description: "URL del backend/admin. Uso interno: genera links en emails al admin (Ver comprobante en ActiveAdmin). Cambiar a https://api.agendity.co en produccion" },
  ].each do |attrs|
    SiteConfig.find_or_create_by!(key: attrs[:key]) do |c|
      c.value = attrs[:value]
      c.description = attrs[:description]
    end
  end
rescue ActiveRecord::StatementInvalid
  # Table doesn't exist yet (before migrations)
end
