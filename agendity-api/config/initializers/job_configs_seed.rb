# frozen_string_literal: true

# Auto-create JobConfig records for all known scheduled jobs on boot.
# This ensures the admin can see and manage jobs without running seeds.
Rails.application.config.after_initialize do
  next unless JobConfig.table_exists?

  [
    { job_class: "CompleteAppointmentsJob", name: "Completar citas", description: "Marca citas checked_in como completed. Dispara cashback y calificacion.", schedule: "Cada 15 minutos" },
    { job_class: "AppointmentReminderSchedulerJob", name: "Recordatorios de citas", description: "Envia recordatorios a clientes con citas del dia siguiente.", schedule: "Diario a las 8am" },
    { job_class: "CleanupExpiredTokensJob", name: "Limpieza de tokens", description: "Elimina refresh tokens expirados.", schedule: "Domingos a las 3am" },
    { job_class: "GenerateSubscriptionPaymentOrdersJob", name: "Ordenes de pago", description: "Genera ordenes de pago mensuales.", schedule: "Diario a la 1am" },
    { job_class: "CheckExpiredSubscriptionsJob", name: "Suscripciones vencidas", description: "Marca suscripciones vencidas.", schedule: "Diario a las 12:05am" },
    { job_class: "SendSubscriptionReminderJob", name: "Recordatorio suscripcion", description: "Recuerda pago a negocios.", schedule: "Diario a las 9am" },
    { job_class: "CleanupOldRequestLogsJob", name: "Limpieza request logs", description: "Elimina logs antiguos.", schedule: "Domingos a las 4am" },
    { job_class: "Intelligence::PricingSuggestionJob", name: "Sugerencias IA", description: "Analiza demanda y sugiere tarifas dinamicas (Plan Inteligente).", schedule: "1ro y 15 de cada mes" },
  ].each do |attrs|
    JobConfig.find_or_create_by!(job_class: attrs[:job_class]) do |jc|
      jc.name = attrs[:name]
      jc.description = attrs[:description]
      jc.schedule = attrs[:schedule]
      jc.enabled = true
    end
  end
rescue StandardError => e
  Rails.logger.warn("[JobConfigsSeed] Could not auto-seed: #{e.message}")
end
