# frozen_string_literal: true

module Appointments
  # Confirms an appointment after its payment has been approved.
  class ConfirmPaymentService < BaseService
    def initialize(appointment:)
      @appointment = appointment
    end

    def call
      unless @appointment.pending_payment? || @appointment.payment_sent?
        return failure("Appointment cannot be confirmed (status: #{@appointment.status})", code: "INVALID_STATUS_FOR_CONFIRM")
      end

      business = @appointment.business
      @appointment.ticket_code ||= generate_ticket_code if business.has_feature?(:ticket_digital)

      if @appointment.update(status: :confirmed)
        schedule_30min_reminder(@appointment)
        success(@appointment)
      else
        failure("Could not confirm appointment", details: @appointment.errors.full_messages)
      end
    end

    private

    def schedule_30min_reminder(appointment)
      business = appointment.business
      reminder_time = appointment.appointment_date.in_time_zone(business.timezone || "America/Bogota")
                        .change(hour: appointment.start_time.hour, min: appointment.start_time.min) - 30.minutes
      return unless reminder_time > Time.current

      ::SendAppointmentReminder30minJob.set(wait_until: reminder_time).perform_later(appointment.id)
    end

    def generate_ticket_code
      loop do
        code = SecureRandom.hex(6).upcase
        return code unless Appointment.exists?(ticket_code: code)
      end
    end
  end
end
