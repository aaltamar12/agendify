# frozen_string_literal: true

module Payments
  # Rejects a submitted payment and reverts the appointment
  # back to pending_payment so the customer can retry.
  # Sends a notification email to the customer with the rejection reason.
  class RejectPaymentService < BaseService
    def initialize(payment:, reason: nil)
      @payment = payment
      @reason = reason
    end

    def call
      ActiveRecord::Base.transaction do
        unless @payment.update(status: :rejected, rejection_reason: @reason, rejected_at: Time.current)
          return failure("Could not reject payment", details: @payment.errors.full_messages)
        end

        unless @payment.appointment.update(status: :pending_payment)
          return failure("Could not update appointment status", details: @payment.appointment.errors.full_messages)
        end

        appointment = @payment.appointment
        ActivityLog.log(
          business: appointment.business,
          action: "payment_rejected",
          description: "Pago rechazado: #{appointment.customer&.name}",
          actor_type: "business",
          resource: appointment,
          metadata: { payment_id: @payment.id, amount: @payment.amount, rejection_reason: @reason }
        )

        # Notify the customer via email about the rejection
        if appointment.customer&.email.present?
          AppointmentMailer.payment_rejected(appointment, @reason).deliver_later
        end

        success(@payment)
      end
    end
  end
end
