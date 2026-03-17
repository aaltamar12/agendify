# frozen_string_literal: true

# Sends transactional emails to business owners.
class BusinessMailer < ApplicationMailer
  # Notify the business that a customer uploaded a payment proof.
  def payment_submitted(payment)
    @payment     = payment
    @appointment = payment.appointment
    @business    = @appointment.business
    @customer    = @appointment.customer
    @service     = @appointment.service

    mail(
      to: @business.owner.email,
      subject: "Comprobante de pago recibido — #{@customer.name} / #{@service.name}"
    )
  end

  # Notify the business that their subscription has expired.
  def subscription_expired(business, subscription)
    @business     = business
    @subscription = subscription
    @plan_name    = subscription.plan.name

    mail(
      to: @business.owner.email,
      subject: "Tu suscripción ha expirado — Agendify"
    )
  end

  # Remind the business about an upcoming subscription payment.
  def subscription_payment_reminder(payment_order)
    @order    = payment_order
    @business = payment_order.business
    @plan     = payment_order.subscription.plan

    mail(
      to: @business.owner.email,
      subject: "Recordatorio: tu pago de suscripción vence el #{@order.due_date.strftime('%d/%m/%Y')}"
    )
  end
end
