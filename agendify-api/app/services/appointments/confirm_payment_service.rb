# frozen_string_literal: true

module Appointments
  # Confirms an appointment after its payment has been approved.
  class ConfirmPaymentService < BaseService
    def initialize(appointment:)
      @appointment = appointment
    end

    def call
      unless @appointment.pending_payment? || @appointment.payment_sent?
        return failure("Appointment cannot be confirmed (status: #{@appointment.status})")
      end

      business = @appointment.business
      @appointment.ticket_code ||= generate_ticket_code if business.has_feature?(:ticket_digital)

      if @appointment.update(status: :confirmed)
        success(@appointment)
      else
        failure("Could not confirm appointment", details: @appointment.errors.full_messages)
      end
    end

    private

    def generate_ticket_code
      loop do
        code = SecureRandom.hex(6).upcase
        return code unless Appointment.exists?(ticket_code: code)
      end
    end
  end
end
