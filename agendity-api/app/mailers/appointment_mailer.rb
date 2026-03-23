# frozen_string_literal: true

# Sends transactional emails related to appointment lifecycle events.
class AppointmentMailer < ApplicationMailer
  # Notify the business when a new booking is created.
  def new_booking(appointment)
    @appointment = appointment
    @business    = appointment.business
    @customer    = appointment.customer
    @service     = appointment.service
    @employee    = appointment.employee

    mail(
      to: @business.owner.email,
      subject: "Nueva reserva de #{@customer.name} — #{@service.name}"
    )
  end

  # Confirm the booking to the customer after payment is approved.
  def booking_confirmed(appointment)
    @appointment = appointment
    @business    = appointment.business
    @customer    = appointment.customer
    @service     = appointment.service
    @employee    = appointment.employee

    return unless @customer.email.present?

    mail(
      to: @customer.email,
      subject: "Tu cita en #{@business.name} está confirmada — #{@appointment.ticket_code}"
    )
  end

  # Notify the business when a booking is cancelled.
  def booking_cancelled(appointment)
    set_cancellation_vars(appointment)

    mail(
      to: @business.owner.email,
      subject: "Cita cancelada — #{@customer.name} / #{@service.name}"
    )
  end

  # Notify the customer when their booking is cancelled (used by MultiChannelService).
  def booking_cancelled_to_customer(appointment)
    set_cancellation_vars(appointment)
    return unless @customer.email.present?

    mail(
      to: @customer.email,
      subject: "Cita cancelada — #{@customer.name} / #{@service.name}"
    )
  end

  private

  def set_cancellation_vars(appointment)
    @appointment = appointment
    @business    = appointment.business
    @customer    = appointment.customer
    @service     = appointment.service
    @employee    = appointment.employee

    @has_paid = %w[payment_sent confirmed checked_in].include?(appointment.status_before_last_save || "")
    @cancelled_by_customer = appointment.cancelled_by == "customer"
    policy_pct = @business.cancellation_policy_pct || 0
    @penalty_amount = (appointment.price * policy_pct / 100.0).round(0)
    @refund_amount = (appointment.price - @penalty_amount).round(0)
    plan = @business.current_plan
    @refund_as_credit = plan&.cashback_enabled? || false
  end

  public

  # Send a payment reminder to the customer when the business requests it.
  def payment_reminder(appointment)
    @appointment = appointment
    @business    = appointment.business
    @customer    = appointment.customer
    @service     = appointment.service
    @employee    = appointment.employee

    return unless @customer.email.present?

    mail(
      to: @customer.email,
      subject: "Tu cita en #{@business.name} está pendiente de pago"
    )
  end

  # Notify the customer when their payment proof is rejected.
  # They can upload a new proof from the ticket page.
  def payment_rejected(appointment, reason = nil)
    @appointment = appointment
    @business    = appointment.business
    @customer    = appointment.customer
    @service     = appointment.service
    @employee    = appointment.employee
    @reason      = reason

    return unless @customer.email.present?

    mail(
      to: @customer.email,
      subject: "Tu comprobante fue rechazado — #{@business.name}"
    )
  end

  # Send a reminder to the customer 24 hours before the appointment.
  def reminder(appointment)
    @appointment = appointment
    @business    = appointment.business
    @customer    = appointment.customer
    @service     = appointment.service
    @employee    = appointment.employee

    return unless @customer.email.present?

    mail(
      to: @customer.email,
      subject: "Recordatorio: tu cita en #{@business.name} es mañana"
    )
  end
end
