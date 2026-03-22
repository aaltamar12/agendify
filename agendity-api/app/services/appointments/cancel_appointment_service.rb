# frozen_string_literal: true

module Appointments
  # Cancels an appointment that has not already been cancelled or completed.
  # Supports differentiated cancellation by business or customer.
  # Customer cancellations past the deadline incur a penalty.
  class CancelAppointmentService < BaseService
    def initialize(appointment:, cancelled_by: nil, reason: nil)
      @appointment  = appointment
      @cancelled_by = cancelled_by
      @reason       = reason
    end

    def call
      if @appointment.cancelled? || @appointment.completed?
        return failure("Appointment cannot be cancelled (status: #{@appointment.status})")
      end

      ActiveRecord::Base.transaction do
        penalty_amount = 0

        if @cancelled_by == "customer"
          penalty_amount = calculate_penalty
          business = @appointment.business

          if business.cancellation_refund_as_credit? && @appointment.customer.present?
            # Refund as credits (minus penalty)
            Credits::RefundService.call(appointment: @appointment)
          elsif penalty_amount.positive?
            # Legacy: add to pending_penalty
            @appointment.customer.increment!(:pending_penalty, penalty_amount)
          end
        end

        unless @appointment.update(
          status: :cancelled,
          cancellation_reason: @reason,
          cancelled_by: @cancelled_by
        )
          raise ActiveRecord::Rollback
          return failure("Could not cancel appointment", details: @appointment.errors.full_messages)
        end

        enqueue_notification

        actor = @cancelled_by == "customer" ? "el cliente" : "el negocio"
        ActivityLog.log(
          business: @appointment.business,
          action: "appointment_cancelled",
          description: "Cita cancelada por #{actor}: #{@appointment.customer&.name}",
          actor_type: @cancelled_by || "system",
          actor_name: @cancelled_by == "customer" ? @appointment.customer&.name : nil,
          resource: @appointment,
          metadata: { reason: @reason, penalty_applied: penalty_amount.positive?, penalty_amount: penalty_amount }
        )

        success({
          appointment: @appointment,
          penalty_applied: penalty_amount.positive?,
          penalty_amount: penalty_amount
        })
      end
    end

    private

    # Check if the cancellation is past the deadline and calculate penalty
    def calculate_penalty
      business = @appointment.business
      deadline_hours = business.cancellation_deadline_hours
      policy_pct = business.cancellation_policy_pct

      return 0 if policy_pct.zero?

      appointment_time = Time.zone.parse(
        "#{@appointment.appointment_date} #{@appointment.start_time.strftime('%H:%M')}"
      ).in_time_zone(business.timezone || "America/Bogota")

      now = Time.current.in_time_zone(business.timezone || "America/Bogota")
      hours_until_appointment = (appointment_time - now) / 1.hour

      if hours_until_appointment < deadline_hours
        # Past deadline — apply penalty
        (@appointment.price * policy_pct / 100.0).round(2)
      else
        0
      end
    end

    def enqueue_notification
      ::SendBookingCancelledJob.perform_later(@appointment.id)
    end
  end
end
