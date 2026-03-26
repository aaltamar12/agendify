# frozen_string_literal: true

# Notifies the admin when a business submits a subscription payment proof.
# Sends email + WhatsApp to admin.
class NotifyAdminSubscriptionProofJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = SubscriptionPaymentOrder.find(order_id)

    # Email to admin
    AdminMailer.subscription_proof_received(order).deliver_later

    # WhatsApp to admin phone
    admin_phone = SiteConfig.get("admin_whatsapp")
    if admin_phone.present?
      admin_recipient = OpenStruct.new(phone: admin_phone)
      Notifications::WhatsappChannel.deliver(
        recipient: admin_recipient,
        template: :subscription_proof_received,
        data: {
          business_name: order.business.name,
          plan_name: (order.plan || order.subscription&.plan)&.name,
          amount: order.amount.to_f,
          order_id: order.id
        }
      )
    end
  end
end
