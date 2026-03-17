# frozen_string_literal: true

module Appointments
  # Marks an appointment as completed after the service has been rendered.
  class CompleteService < BaseService
    def initialize(appointment:)
      @appointment = appointment
    end

    def call
      unless @appointment.checked_in?
        return failure("Only checked-in appointments can be completed (status: #{@appointment.status})")
      end

      if @appointment.update(status: :completed)
        ActivityLog.log(
          business: @appointment.business,
          action: "appointment_completed",
          description: "Servicio completado: #{@appointment.customer&.name}",
          actor_type: "business",
          resource: @appointment
        )
        success(@appointment)
      else
        failure("Could not complete appointment", details: @appointment.errors.full_messages)
      end
    end
  end
end
