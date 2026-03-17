# frozen_string_literal: true

# Generates payment orders for subscriptions approaching renewal (within 7 days).
# Runs daily at 1am via solid_queue recurring schedule.
class GenerateSubscriptionPaymentOrdersJob < ApplicationJob
  queue_as :default

  def perform
    # Find active subscriptions ending within 7 days
    subscriptions = Subscription.active
      .where(end_date: ..7.days.from_now.to_date)
      .includes(:plan, :business)

    subscriptions.find_each do |subscription|
      next_period_start = subscription.end_date + 1.day
      next_period_end = next_period_start + 1.month - 1.day

      # Skip if a pending/paid order already exists for the next period
      existing = subscription.subscription_payment_orders
        .where(period_start: next_period_start)
        .where(status: %w[pending paid])

      next if existing.exists?

      order = SubscriptionPaymentOrder.create!(
        subscription: subscription,
        business: subscription.business,
        amount: subscription.plan.price_monthly,
        due_date: subscription.end_date,
        period_start: next_period_start,
        period_end: next_period_end,
        status: "pending"
      )

      # In-app notification
      Notification.create!(
        business: subscription.business,
        title: "Renovación de suscripción",
        body: "Tu suscripción se renueva el #{subscription.end_date.strftime('%d/%m/%Y')}. Realiza tu pago.",
        notification_type: "reminder",
        link: "/dashboard/settings"
      )

      # Activity log
      ActivityLog.log(
        business: subscription.business,
        action: "payment_order_created",
        description: "Orden de pago generada por $#{order.amount.to_i} — vence #{order.due_date.strftime('%d/%m/%Y')}",
        actor_type: "system",
        resource: order
      )
    end
  end
end
