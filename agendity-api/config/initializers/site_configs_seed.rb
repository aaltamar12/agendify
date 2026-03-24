# frozen_string_literal: true

# Auto-creates SiteConfig keys on Rails boot.
# Keys are fixed — admin can only edit values, not create/delete keys.
# Safe to run multiple times (find_or_create_by).

Rails.application.config.after_initialize do
  next unless ActiveRecord::Base.connection.table_exists?("site_configs")

  [
    { key: "company_name",       value: "Agendity",           description: "Nombre de la empresa" },
    { key: "support_email",      value: "soporte@agendity.com", description: "Email de soporte (visible en emails y help button)" },
    { key: "support_whatsapp",   value: "+573001234567",      description: "WhatsApp de soporte (visible en emails y help button)" },
    { key: "admin_email",        value: "admin@agendity.com", description: "Email del admin (recibe notificaciones de comprobantes)" },
    { key: "admin_whatsapp",     value: "+573001234567",      description: "WhatsApp del admin (recibe notificaciones de comprobantes)" },
    { key: "payment_nequi",      value: "3001234567",         description: "Nequi de Agendity (donde los negocios pagan suscripcion)" },
    { key: "payment_bancolombia", value: "12345678901",       description: "Cuenta Bancolombia de Agendity" },
    { key: "payment_daviplata",  value: "3001234567",         description: "Daviplata de Agendity" },
    { key: "app_url",            value: "http://localhost:3000", description: "URL del frontend (usada en links de emails)" },
    { key: "admin_url",          value: "http://localhost:3001", description: "URL del backend/admin (usada en links de admin)" },
  ].each do |attrs|
    SiteConfig.find_or_create_by!(key: attrs[:key]) do |c|
      c.value = attrs[:value]
      c.description = attrs[:description]
    end
  end
rescue ActiveRecord::StatementInvalid
  # Table doesn't exist yet (before migrations)
end
