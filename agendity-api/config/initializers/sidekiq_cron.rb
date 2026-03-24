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
    "trial_expiry_alerts" => {
      "class" => "TrialExpiryAlertJob",
      "cron" => "0 8 * * *",           # Daily at 8:00 AM
      "queue" => "default",
      "description" => "Alertas de trial por vencer (2d antes, dia de, +2d suspension)"
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
    "pricing_suggestions" => {
      "class" => "Intelligence::PricingSuggestionJob",
      "cron" => "0 8 1,15 * *",        # 1st and 15th of each month at 8:00 AM
      "queue" => "intelligence",
      "description" => "Analiza demanda y genera sugerencias de tarifas (Plan Inteligente)"
    }
  )
end
