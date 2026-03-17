# frozen_string_literal: true

# Sends reminder notifications for payment orders due in 3 days.
# Runs daily at 9am via solid_queue recurring schedule.
class SendSubscriptionReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Find pending payment orders due in exactly 3 days
    due_date = 3.days.from_now.to_date
    orders = SubscriptionPaymentOrder.pending
      .where(due_date: due_date)
      .includes(:business, subscription: :plan)

    orders.find_each do |order|
      # In-app notification
      Notification.create!(
        business: order.business,
        title: "Recordatorio de pago",
        body: "Tu pago de suscripción vence en 3 días (#{order.due_date.strftime('%d/%m/%Y')})",
        notification_type: "reminder",
        link: "/dashboard/settings"
      )

      # Email reminder
      BusinessMailer.subscription_payment_reminder(order).deliver_later

      # Activity log
      ActivityLog.log(
        business: order.business,
        action: "payment_reminder_sent",
        description: "Recordatorio de pago enviado — vence #{order.due_date.strftime('%d/%m/%Y')}",
        actor_type: "system",
        resource: order
      )
    end
  end
end
