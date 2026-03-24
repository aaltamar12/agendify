# frozen_string_literal: true

# Sends transactional emails to platform admins.
class AdminMailer < ApplicationMailer
  # Notify admin when a business submits a subscription payment proof.
  def subscription_proof_received(payment_order)
    @order    = payment_order
    @business = payment_order.business
    @plan     = payment_order.plan || payment_order.subscription&.plan
    @admin_url = SiteConfig.get("admin_url")

    admin_email = SiteConfig.get("admin_email") || "admin@agendity.com"

    mail(
      to: admin_email,
      subject: "[Suscripcion] Comprobante de pago — #{@business.name} — Plan #{@plan&.name} — $#{@order.amount.to_i}"
    )
  end
end
