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

  # Alert the business about trial expiry (stages 1 and 3).
  def trial_expiry_alert(business, stage)
    @business = business
    @stage    = stage
    @trial_ends_at = business.trial_ends_at
    @support_whatsapp = SiteConfig.get("support_whatsapp")
    @support_email = SiteConfig.get("support_email")

    subject = case stage
              when 1 then "Tu periodo de prueba termina en 2 dias — Agendity"
              when 3 then "Tu cuenta ha sido suspendida — Agendity"
              end

    mail(
      to: @business.owner.email,
      subject: subject,
      template_name: "trial_expiry_alert_stage_#{stage}"
    )
  end

  # Special thank-you message when trial ends (stage 2) — includes plans + CTA.
  def trial_ended_thank_you(business)
    @business = business
    @plans = Plan.order(:price_monthly)
    @support_whatsapp = SiteConfig.get("support_whatsapp")
    @support_email = SiteConfig.get("support_email")
    @app_url = SiteConfig.get("app_url")
    @payment_nequi = SiteConfig.get("payment_nequi")
    @payment_bancolombia = SiteConfig.get("payment_bancolombia")
    @payment_daviplata = SiteConfig.get("payment_daviplata")

    mail(
      to: @business.owner.email,
      subject: "Gracias por probar Agendity — Elige tu plan"
    )
  end

  # Confirm subscription activation after payment approval.
  def subscription_activated(business, subscription)
    @business     = business
    @subscription = subscription
    @plan_name    = subscription.plan.name
    @end_date     = subscription.end_date

    mail(
      to: @business.owner.email,
      subject: "Suscripcion activada — #{@plan_name} — Agendity"
    )
  end

  # Welcome email sent right after registration.
  def welcome(business)
    @business          = business
    @owner             = business.owner
    @trial_ends_at     = business.trial_ends_at
    @support_email     = SiteConfig.get("support_email")
    @support_whatsapp  = SiteConfig.get("support_whatsapp")
    @app_url           = SiteConfig.get("app_url")

    mail(
      to: @owner.email,
      subject: "¡Bienvenido a Agendity, #{@owner.name}! Tu negocio está listo"
    )
  end

  # Notify the business about upcoming price changes.
  def price_change_notification(business, old_prices, new_prices, effective_date)
    @business       = business
    @old_prices     = old_prices
    @new_prices     = new_prices
    @effective_date = effective_date

    mail(
      to: @business.owner.email,
      subject: "Cambio de precios en Agendity — Efectivo desde el #{@effective_date.strftime('%d/%m/%Y')}"
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
