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
      subject: "Tu suscripción ha expirado — Agendity"
    )
  end

  # Alert the business about subscription expiration.
  # Stage 1: 5 days before, Stage 2: day of, Stage 3: grace period over.
  def subscription_expiry_alert(business, subscription, stage)
    @business     = business
    @subscription = subscription
    @plan_name    = subscription.plan.name
    @end_date     = subscription.end_date
    @stage        = stage

    subject = case stage
              when 1 then "Tu suscripción vence en 5 días — Agendity"
              when 2 then "Tu suscripción vence hoy — Agendity"
              when 3 then "Tu cuenta ha sido suspendida — Agendity"
              end

    mail(
      to: @business.owner.email,
      subject: subject,
      template_name: "subscription_expiry_alert_stage_#{stage}"
    )
  end

  # Confirm subscription renewal to the business.
  def subscription_renewed(business, subscription)
    @business     = business
    @subscription = subscription
    @plan_name    = subscription.plan.name
    @end_date     = subscription.end_date

    mail(
      to: @business.owner.email,
      subject: "Suscripción renovada exitosamente — Agendity"
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
