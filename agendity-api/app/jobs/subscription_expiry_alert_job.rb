# frozen_string_literal: true

# Sends subscription expiry alerts at three stages:
#   Stage 1: 5 days before expiration — warning notification
#   Stage 2: Day of expiration — urgency notification
#   Stage 3: 2 days after expiration — final notice + business suspended
#
# Uses expiry_alert_stage on subscription to avoid duplicate sends.
# Runs daily at 8am via solid_queue recurring schedule.
class SubscriptionExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    return record_success!("Skipped — disabled") unless job_enabled?

    counts = { stage_1: 0, stage_2: 0, stage_3: 0 }

    # Stage 1: 5 days before expiration
    Subscription.expiring_in(5).where(expiry_alert_stage: 0)
      .includes(:plan, business: :owner).find_each do |subscription|
      send_alert(subscription, stage: 1)
      counts[:stage_1] += 1
    end

    # Stage 2: Day of expiration (end_date == today)
    Subscription.active.where(end_date: Date.current, expiry_alert_stage: 1)
      .includes(:plan, business: :owner).find_each do |subscription|
      send_alert(subscription, stage: 2)
      counts[:stage_2] += 1
    end

    # Stage 3: 2 days after expiration (grace period ended) — suspend
    Subscription.expired_since(2).where(expiry_alert_stage: 2)
      .includes(:plan, business: :owner).find_each do |subscription|
      send_alert(subscription, stage: 3)
      suspend_business!(subscription)
      counts[:stage_3] += 1
    end

    # Stage 4: 7 days after expiration — deactivate (full block)
    Subscription.expired_since(7).where(expiry_alert_stage: 3)
      .includes(:plan, business: :owner).find_each do |subscription|
      deactivate_business!(subscription)
      counts[:stage_4] = (counts[:stage_4] || 0) + 1
    end

    record_success!(
      "Alerts sent — 5-day: #{counts[:stage_1]}, expiry-day: #{counts[:stage_2]}, suspended: #{counts[:stage_3]}, deactivated: #{counts[:stage_4] || 0}"
    )
  rescue StandardError => e
    record_error!(e.message)
    raise
  end

  private

  def send_alert(subscription, stage:)
    business = subscription.business
    owner = business.owner

    # Update stage to prevent duplicates
    subscription.update!(expiry_alert_stage: stage)

    # Email
    BusinessMailer.subscription_expiry_alert(business, subscription, stage).deliver_later

    # In-app notification
    notification = Notification.create!(
      business: business,
      title: alert_title(stage),
      body: alert_body(subscription, stage),
      notification_type: "subscription_expiry",
      link: "/dashboard/settings"
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: business.id,
      event: "subscription_expiry",
      data: {
        notification_id: notification.id,
        stage: stage,
        end_date: subscription.end_date.iso8601,
        plan_name: subscription.plan.name
      }
    )

    # WhatsApp (if plan includes it)
    if business.current_plan&.whatsapp_notifications? && owner.phone.present?
      Notifications::WhatsAppChannel.deliver(
        recipient: owner,
        template: :"subscription_expiry_stage_#{stage}",
        data: {
          business_name: business.name,
          plan_name: subscription.plan.name,
          end_date: subscription.end_date.strftime("%d/%m/%Y")
        }
      )
    end

    # Activity log
    ActivityLog.log(
      business: business,
      action: "subscription_expiry_alert",
      description: alert_log_description(subscription, stage),
      actor_type: "system",
      resource: subscription,
      metadata: { stage: stage, end_date: subscription.end_date.iso8601 }
    )
  end

  def suspend_business!(subscription)
    business = subscription.business
    business.suspended!

    AdminNotification.notify!(
      title: "Negocio suspendido por suscripcion vencida",
      body: "#{business.name} fue suspendido automaticamente",
      notification_type: "subscription_expired",
      link: "/admin/businesses/#{business.id}",
      icon: "🔴"
    )

    ActivityLog.log(
      business: business,
      action: "business_suspended",
      description: "Negocio suspendido por suscripción vencida (gracia de 2 días agotada)",
      actor_type: "system",
      resource: subscription
    )
  end

  def deactivate_business!(subscription)
    business = subscription.business
    subscription.update!(expiry_alert_stage: 4)
    business.inactive!

    AdminNotification.notify!(
      title: "Negocio desactivado por suscripcion vencida",
      body: "#{business.name} fue desactivado automaticamente (7 dias sin renovar)",
      notification_type: "business_deactivated",
      link: "/admin/businesses/#{business.id}",
      icon: "⛔"
    )

    ActivityLog.log(
      business: business,
      action: "business_deactivated",
      description: "Negocio desactivado por suscripcion vencida (7 dias sin renovar)",
      actor_type: "system",
      resource: subscription
    )
  end

  def alert_title(stage)
    case stage
    when 1 then "Tu suscripción vence en 5 días"
    when 2 then "Tu suscripción vence hoy"
    when 3 then "Tu cuenta ha sido suspendida"
    end
  end

  def alert_body(subscription, stage)
    plan_name = subscription.plan.name
    end_date = subscription.end_date.strftime("%d/%m/%Y")

    case stage
    when 1
      "Tu plan #{plan_name} vence el #{end_date}. Renueva para no perder acceso a tus funcionalidades."
    when 2
      "Tu plan #{plan_name} vence hoy. Si no renuevas, tu cuenta será suspendida en 2 días."
    when 3
      "Tu cuenta ha sido suspendida porque tu plan #{plan_name} venció el #{end_date} y no fue renovado."
    end
  end

  def alert_log_description(subscription, stage)
    case stage
    when 1 then "Alerta de expiración enviada (5 días antes) — Plan #{subscription.plan.name}"
    when 2 then "Alerta de expiración enviada (día de vencimiento) — Plan #{subscription.plan.name}"
    when 3 then "Alerta final enviada + negocio suspendido — Plan #{subscription.plan.name}"
    end
  end
end
