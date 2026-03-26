# frozen_string_literal: true

# Sends trial expiry alerts at four stages:
#   Stage 1: 5 days before trial ends — reminder to subscribe
#   Stage 2: Day trial ends — thank you + plans info
#   Stage 3: 2 days after trial ends — suspend business
#   Stage 4: 10 days after trial ends — deactivate business
#
# Uses trial_alert_stage on business to avoid duplicate sends.
# Skips businesses that already have an active subscription.
# Runs daily at 8am via solid_queue recurring schedule.
class TrialExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    return record_success!("Skipped — disabled") unless job_enabled?

    counts = { stage_1: 0, stage_2: 0, stage_3: 0 }

    # Stage 1: 5 days before trial ends
    Business.trial_expiring_in(5).where(trial_alert_stage: 0)
      .includes(:owner, :subscriptions).find_each do |business|
      next if has_active_subscription?(business)

      send_alert(business, stage: 1)
      counts[:stage_1] += 1
    end

    # Stage 2: Day trial ends (trial_ends_at::date == today)
    Business.trial_expiring_in(0).where(trial_alert_stage: 1)
      .includes(:owner, :subscriptions).find_each do |business|
      next if has_active_subscription?(business)

      send_alert(business, stage: 2)
      counts[:stage_2] += 1
    end

    # Stage 3: 2 days after trial ends — suspend business
    Business.trial_expired_since(2).where(trial_alert_stage: 2)
      .includes(:owner, :subscriptions).find_each do |business|
      next if has_active_subscription?(business)

      send_alert(business, stage: 3)
      suspend_business!(business)
      counts[:stage_3] += 1
    end

    # Stage 4: 10 days after trial ends — deactivate (full block)
    Business.trial_expired_since(10).where(trial_alert_stage: 3)
      .includes(:owner, :subscriptions).find_each do |business|
      next if has_active_subscription?(business)

      deactivate_business!(business)
      counts[:stage_4] = (counts[:stage_4] || 0) + 1
    end

    record_success!(
      "Alerts sent — 5-day-before: #{counts[:stage_1]}, trial-end: #{counts[:stage_2]}, suspended: #{counts[:stage_3]}, deactivated: #{counts[:stage_4] || 0}"
    )
  rescue StandardError => e
    record_error!(e.message)
    raise
  end

  private

  def has_active_subscription?(business)
    business.subscriptions.active.where("end_date >= ?", Date.current).exists?
  end

  def send_alert(business, stage:)
    owner = business.owner

    # Update stage to prevent duplicates
    business.update!(trial_alert_stage: stage)

    # Email
    if stage == 2
      BusinessMailer.trial_ended_thank_you(business).deliver_later
    else
      BusinessMailer.trial_expiry_alert(business, stage).deliver_later
    end

    # In-app notification
    notification = Notification.create!(
      business: business,
      title: alert_title(stage),
      body: alert_body(business, stage),
      notification_type: "subscription_expiry",
      link: "/dashboard/subscription"
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: business.id,
      event: "trial_expiry",
      data: {
        notification_id: notification.id,
        stage: stage,
        trial_ends_at: business.trial_ends_at&.iso8601
      }
    )

    # WhatsApp to business owner
    if owner.phone.present?
      Notifications::WhatsAppChannel.deliver(
        recipient: owner,
        template: :"trial_expiry_stage_#{stage}",
        data: {
          business_name: business.name,
          trial_ends_at: business.trial_ends_at&.strftime("%d/%m/%Y"),
          support_whatsapp: SiteConfig.get("support_whatsapp") || ""
        }
      )
    end

    # Activity log
    ActivityLog.log(
      business: business,
      action: "trial_expiry_alert",
      description: alert_log_description(business, stage),
      actor_type: "system",
      resource: business,
      metadata: { stage: stage, trial_ends_at: business.trial_ends_at&.iso8601 }
    )
  end

  def suspend_business!(business)
    business.suspended!

    AdminNotification.notify!(
      title: "Negocio suspendido por trial vencido",
      body: "#{business.name} fue suspendido automaticamente",
      notification_type: "trial_expired",
      link: "/admin/businesses/#{business.id}",
      icon: "⚠️"
    )

    ActivityLog.log(
      business: business,
      action: "business_suspended",
      description: "Negocio suspendido por trial vencido (gracia de 2 dias agotada)",
      actor_type: "system",
      resource: business
    )
  end

  def deactivate_business!(business)
    business.update!(trial_alert_stage: 4)
    business.inactive!

    AdminNotification.notify!(
      title: "Negocio desactivado por trial vencido",
      body: "#{business.name} fue desactivado (10 dias sin suscribirse)",
      notification_type: "business_deactivated",
      link: "/admin/businesses/#{business.id}",
      icon: "⛔"
    )

    ActivityLog.log(
      business: business,
      action: "business_deactivated",
      description: "Negocio desactivado por trial vencido (10 dias sin suscribirse)",
      actor_type: "system",
      resource: business
    )
  end

  def alert_title(stage)
    case stage
    when 1 then "Tu periodo de prueba termina en 5 dias"
    when 2 then "Tu periodo de prueba termina hoy"
    when 3 then "Tu cuenta ha sido suspendida"
    end
  end

  def alert_body(business, stage)
    trial_date = business.trial_ends_at&.strftime("%d/%m/%Y")

    case stage
    when 1
      "Tu periodo de prueba gratuito termina el #{trial_date}. Suscribete para seguir usando Agendity."
    when 2
      "Gracias por probar Agendity. Tu periodo de prueba termina hoy. Elige un plan para continuar."
    when 3
      "Tu cuenta ha sido suspendida porque tu periodo de prueba vencio y no se activo una suscripcion."
    end
  end

  def alert_log_description(business, stage)
    case stage
    when 1 then "Alerta de trial enviada (5 dias antes) — #{business.name}"
    when 2 then "Alerta de trial enviada (dia de vencimiento) — #{business.name}"
    when 3 then "Alerta final enviada + negocio suspendido — #{business.name}"
    end
  end
end
