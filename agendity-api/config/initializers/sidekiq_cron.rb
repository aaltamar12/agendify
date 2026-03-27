# frozen_string_literal: true

# Schedule recurring jobs via sidekiq-cron.
# These run automatically while Sidekiq is running.
# Manageable from /admin/sidekiq/cron

if Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash!(
    "complete_appointments" => {
      "class" => "CompleteAppointmentsJob",
      "cron" => "*/15 * * * *",        # Every 15 minutes
      "queue" => "default",
      "description" => "Marca como completadas las citas checked_in cuya hora ya paso"
    },
    "appointment_reminder_scheduler" => {
      "class" => "AppointmentReminderSchedulerJob",
      "cron" => "0 8 * * *",           # Daily at 8:00 AM
      "queue" => "default",
      "description" => "Envia recordatorios a clientes con citas del dia siguiente"
    },
    "trial_expiry_alerts" => {
      "class" => "TrialExpiryAlertJob",
      "cron" => "0 8 * * *",           # Daily at 8:00 AM
      "queue" => "default",
      "description" => "Alertas de trial por vencer (5d antes, dia de, +2d suspension, +10d inactivar)"
    },
    "subscription_expiry_alerts" => {
      "class" => "SubscriptionExpiryAlertJob",
      "cron" => "0 8 * * *",           # Daily at 8:00 AM
      "queue" => "default",
      "description" => "Alertas de suscripcion por vencer (5d antes, dia de, +2d suspension)"
    },
    "birthday_campaign" => {
      "class" => "BirthdayCampaignJob",
      "cron" => "0 8 * * *",           # Daily at 8:00 AM
      "queue" => "default",
      "description" => "Genera codigos de cumpleanos y envia felicitaciones"
    },
    "generate_payment_orders" => {
      "class" => "GenerateSubscriptionPaymentOrdersJob",
      "cron" => "0 1 * * *",           # Daily at 1:00 AM
      "queue" => "default",
      "description" => "Genera ordenes de pago mensuales de suscripciones"
    },
    "check_expired_subscriptions" => {
      "class" => "CheckExpiredSubscriptionsJob",
      "cron" => "5 0 * * *",           # Daily at 12:05 AM
      "queue" => "default",
      "description" => "Marca suscripciones vencidas"
    },
    "subscription_reminder" => {
      "class" => "SendSubscriptionReminderJob",
      "cron" => "0 9 * * *",           # Daily at 9:00 AM
      "queue" => "default",
      "description" => "Recuerda pago de suscripcion a negocios"
    },
    "cleanup_expired_tokens" => {
      "class" => "CleanupExpiredTokensJob",
      "cron" => "0 3 * * 0",           # Sundays at 3:00 AM
      "queue" => "low",
      "description" => "Elimina refresh tokens expirados"
    },
    "cleanup_request_logs" => {
      "class" => "CleanupOldRequestLogsJob",
      "cron" => "0 4 * * 0",           # Sundays at 4:00 AM
      "queue" => "low",
      "description" => "Elimina logs de requests antiguos"
    },
    "pricing_suggestions" => {
      "class" => "Intelligence::PricingSuggestionJob",
      "cron" => "0 8 1,15 * *",        # 1st and 15th of each month at 8:00 AM
      "queue" => "intelligence",
      "description" => "Analiza demanda y genera sugerencias de tarifas (Plan Inteligente)"
    }
  )
end
