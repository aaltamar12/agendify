# frozen_string_literal: true

module Api
  module V1
    module Employee
      class AppointmentsController < BaseController
        # GET /api/v1/employee/appointments
        def index
          appointments = current_employee.appointments
            .includes(:service, :customer, :business, appointment_services: :service)
          appointments = appointments.where(appointment_date: params[:date]) if params[:date].present?
          appointments = appointments.where(status: params[:status]) if params[:status].present?
          appointments = appointments.order(appointment_date: :desc, start_time: :desc)

          render_success(AppointmentSerializer.render_as_hash(appointments, view: :detailed))
        end

        # POST /api/v1/employee/appointments/:id/checkin
        def checkin
          appointment = current_employee.business.appointments
            .includes(:service, :employee, :customer)
            .find(params[:id])

          result = Appointments::CheckinService.call(
            appointment: appointment,
            actor: current_user,
            confirmed: params[:confirmed] == true || params[:confirmed] == "true",
            substitute_reason: params[:substitute_reason]
          )

          if result.success?
            render_success(AppointmentSerializer.render_as_hash(result.data, view: :detailed))
          else
            # Check if it requires confirmation (substitute check-in)
            if result.data.is_a?(Hash) && result.data[:requires_confirmation]
              render json: {
                error: result.error,
                requires_confirmation: true,
                assigned_employee: result.data[:assigned_employee]
              }, status: :conflict
            else
              render_error(result.error, status: :unprocessable_entity)
            end
          end
        end
      end
    end
  end
end
