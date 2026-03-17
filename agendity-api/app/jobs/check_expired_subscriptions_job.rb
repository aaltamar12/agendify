# frozen_string_literal: true

# Checks for expired subscriptions and either extends them (if paid) or
# downgrades to Plan Básico.
# Runs daily at 12:05am via solid_queue recurring schedule.
class CheckExpiredSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform
    # Find active subscriptions that have passed their end_date
    expired = Subscription.active
      .where("end_date < ?", Date.current)
      .includes(:plan, :business, :subscription_payment_orders)

    expired.find_each do |subscription|
      # Check if there's a paid payment order covering the next period
      paid_order = subscription.subscription_payment_orders
        .where(status: "paid")
        .where("period_start > ?", subscription.end_date)
        .first

      if paid_order
        extend_subscription(subscription, paid_order)
      else
        downgrade_to_basic(subscription)
      end
    end
  end

  private

  def extend_subscription(subscription, paid_order)
    subscription.update!(end_date: subscription.end_date + 1.month)

    ActivityLog.log(
      business: subscription.business,
      action: "subscription_renewed",
      description: "Suscripción renovada hasta #{subscription.end_date.strftime('%d/%m/%Y')}",
      actor_type: "system",
      resource: subscription
    )
  end

  def downgrade_to_basic(subscription)
    business = subscription.business

    # Mark current subscription as expired
    subscription.expired!

    # Mark any pending payment orders as overdue
    subscription.subscription_payment_orders.pending.update_all(status: "overdue")

    # Find or create the Básico plan
    basic_plan = Plan.find_by!(name: "Básico")

    # Create new subscription with Básico plan
    new_subscription = Subscription.create!(
      business: business,
      plan: basic_plan,
      status: :active,
      start_date: Date.current,
      end_date: Date.current + 1.month
    )

    # In-app notification
    Notification.create!(
      business: business,
      title: "Suscripción expirada",
      body: "Tu suscripción ha expirado. Tus servicios han sido limitados al Plan Básico.",
      notification_type: "reminder",
      link: "/dashboard/settings"
    )

    # Email notification
    BusinessMailer.subscription_expired(business, subscription).deliver_later

    # Activity log
    ActivityLog.log(
      business: business,
      action: "subscription_expired",
      description: "Suscripción expirada — downgrade a Plan Básico",
      actor_type: "system",
      resource: new_subscription
    )
  end
end
