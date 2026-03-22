# frozen_string_literal: true

module Appointments
  # Records the customer's arrival at the business.
  # Supports check-in by business owner or employee, with substitute detection.
  SUBSTITUTE_REASONS = [
    "Cambio de turno",
    "Empleado ausente",
    "Reasignacion",
    "Solicitud del cliente",
    "Otro"
  ].freeze

  class CheckinService < BaseService
    def initialize(appointment:, actor: nil, confirmed: false, substitute_reason: nil)
      @appointment = appointment
      @actor = actor
      @confirmed = confirmed
      @substitute_reason = substitute_reason
    end

    def call
      unless @appointment.confirmed?
        return failure("Only confirmed appointments can be checked in (status: #{@appointment.status})")
      end

      actor_type = determine_actor_type
      is_substitute = actor_type == "employee" && !is_assigned_employee?

      # If employee is doing check-in for another employee's appointment, require confirmation
      if is_substitute && !@confirmed
        return ServiceResult.new(
          success: false,
          error: "Este check-in no corresponde al empleado agendado",
          data: { requires_confirmation: true, assigned_employee: @appointment.employee.name }
        )
      end

      attrs = {
        status: :checked_in,
        checked_in_at: Time.current,
        checked_in_by_type: actor_type,
        checked_in_by_id: @actor&.id,
        checkin_substitute: is_substitute,
        checkin_substitute_reason: is_substitute ? @substitute_reason : nil
      }

      if @appointment.update(attrs)
        ActivityLog.log(
          business: @appointment.business,
          action: "appointment_checked_in",
          description: "Check-in: #{@appointment.customer&.name}#{is_substitute ? ' (sustituto)' : ''}",
          actor_type: actor_type,
          resource: @appointment
        )
        success(@appointment)
      else
        failure("Could not check in appointment", details: @appointment.errors.full_messages)
      end
    end

    private

    def determine_actor_type
      return "business" unless @actor
      @actor.employee? ? "employee" : "business"
    end

    def is_assigned_employee?
      return true unless @actor&.employee?
      employee = ::Employee.find_by(user_id: @actor.id)
      employee&.id == @appointment.employee_id
    end
  end
end
