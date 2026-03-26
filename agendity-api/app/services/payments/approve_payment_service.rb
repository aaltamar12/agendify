# frozen_string_literal: true

module Payments
  # Approves a submitted payment: marks the payment as approved,
  # confirms the appointment, and generates a ticket code.
  class ApprovePaymentService < BaseService
    def initialize(payment:)
      @payment = payment
    end

    def call
      ActiveRecord::Base.transaction do
        unless @payment.update(status: :approved)
          return failure("Could not approve payment", details: @payment.errors.full_messages)
        end

        appointment = @payment.appointment
        business = appointment.business
        appointment.ticket_code ||= generate_ticket_code if business.has_feature?(:ticket_digital)

        unless appointment.update(status: :confirmed)
          return failure("Could not confirm appointment", details: appointment.errors.full_messages)
        end

        ::SendBookingConfirmedJob.perform_later(appointment.id)
        schedule_30min_reminder(appointment)

        ActivityLog.log(
          business: appointment.business,
          action: "payment_approved",
          description: "Pago aprobado: #{appointment.customer&.name}",
          actor_type: "business",
          resource: appointment,
          metadata: { payment_id: @payment.id, amount: @payment.amount }
        )

        success(@payment)
      end
    end

    private

    def schedule_30min_reminder(appointment)
      reminder_time = appointment.appointment_date.in_time_zone(appointment.business.timezone || "America/Bogota")
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
