# frozen_string_literal: true

# Production seeds — minimal data required for the platform to function.
# Run with: RAILS_ENV=production rails db:seed
# Idempotent: safe to run multiple times.

puts "=" * 60
puts "🌱 Seeding Agendity production database..."
puts "=" * 60

# ============================================================================
# 1. PLANS
# ============================================================================
puts "\n📋 Creating plans..."

Plan.find_or_initialize_by(name: "Básico").tap do |p|
  p.update!(
    price_monthly: 33_000,
    price_monthly_usd: 9,
    max_employees: 3,
    max_services: 5,
    max_reservations_month: nil,
    max_customers: nil,
    ai_features: false,
    ticket_digital: false,
    advanced_reports: false,
    brand_customization: false,
    featured_listing: false,
    priority_support: false,
    whatsapp_notifications: false,
    cashback_enabled: false,
    cashback_percentage: 0,
    features: [
      "Agenda y calendario",
      "Hasta 3 empleados",
      "Hasta 5 servicios",
      "Página pública",
      "QR de reservas",
      "Notificaciones por email",
      "Reportes básicos"
    ]
  )
end

Plan.find_or_initialize_by(name: "Profesional").tap do |p|
  p.update!(
    price_monthly: 82_000,
    price_monthly_usd: 22,
    max_employees: 10,
    max_services: nil,
    max_reservations_month: nil,
    max_customers: nil,
    ai_features: false,
    ticket_digital: true,
    advanced_reports: true,
    brand_customization: true,
    featured_listing: true,
    priority_support: false,
    whatsapp_notifications: true,
    cashback_enabled: true,
    cashback_percentage: 5,
    features: [
      "Todo del plan Básico",
      "Hasta 10 empleados",
      "Servicios ilimitados",
      "Notificaciones WhatsApp",
      "Ticket digital VIP con QR",
      "Reportes avanzados",
      "Personalización de marca",
      "Negocio destacado",
      "Cierre de caja",
      "Tarifas dinámicas",
      "Créditos / Cashback"
    ]
  )
end

Plan.find_or_initialize_by(name: "Inteligente").tap do |p|
  p.update!(
    price_monthly: 99_000,
    price_monthly_usd: 27,
    max_employees: nil,
    max_services: nil,
    max_reservations_month: nil,
    max_customers: nil,
    ai_features: true,
    ticket_digital: true,
    advanced_reports: true,
    brand_customization: true,
    featured_listing: true,
    priority_support: true,
    whatsapp_notifications: true,
    cashback_enabled: true,
    cashback_percentage: 5,
    features: [
      "Todo del plan Profesional",
      "Empleados ilimitados",
      "Análisis inteligente con IA",
      "Predicción de ingresos",
      "Recomendaciones de precios",
      "Alertas de clientes inactivos",
      "Tarifas dinámicas automáticas",
      "Metas financieras",
      "Reconciliación contable",
      "Badge verificado",
      "Soporte prioritario"
    ]
  )
end

puts "  ✅ Plans: #{Plan.count}"

# ============================================================================
# 2. ADMIN USER
# ============================================================================
puts "\n👤 Creating admin user..."

admin = User.find_or_initialize_by(email: "admin@agendity.com")
admin.update!(
  name: "Admin Agendity",
  password: ENV.fetch("ADMIN_PASSWORD", "AgendityAdmin2026!"),
  role: :admin
)

puts "  ✅ Admin: #{admin.email}"

# ============================================================================
# 3. SITE CONFIG (values set via initializer, but ensure they exist)
# ============================================================================
puts "\n⚙️  Site configs created via initializer on boot"

# Override production-specific values
{
  "app_url" => ENV.fetch("AGENDITY_WEB_URL", "https://agendity.co"),
  "admin_url" => ENV.fetch("API_HOST", "https://api.agendity.co"),
  "support_email" => "soporte@agendity.com",
  "support_whatsapp" => "+573001234567",
  "trm_rate" => "3667"
}.each do |key, value|
  config = SiteConfig.find_by(key: key)
  config&.update!(value: value) if config
end

puts "  ✅ Site configs updated for production"

# ============================================================================
# 4. JOB CONFIGS
# ============================================================================
puts "\n🔧 Job configs created via initializer on boot"

puts ""
puts "=" * 60
puts "✅ Production seed complete!"
puts ""
puts "Admin login: #{admin.email}"
puts "Admin password: #{ENV.fetch('ADMIN_PASSWORD', 'AgendityAdmin2026!')}"
puts "=" * 60
