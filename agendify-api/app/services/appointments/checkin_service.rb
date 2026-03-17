# frozen_string_literal: true

module Appointments
  # Records the customer's arrival at the business.
  class CheckinService < BaseService
    def initialize(appointment:)
      @appointment = appointment
    end

    def call
      unless @appointment.confirmed?
        return failure("Only confirmed appointments can be checked in (status: #{@appointment.status})")
      end

      if @appointment.update(status: :checked_in, checked_in_at: Time.current)
        ActivityLog.log(
          business: @appointment.business,
          action: "appointment_checked_in",
          description: "Check-in: #{@appointment.customer&.name}",
          actor_type: "business",
          resource: @appointment
        )
        success(@appointment)
      else
        failure("Could not check in appointment", details: @appointment.errors.full_messages)
      end
    end
  end
end
