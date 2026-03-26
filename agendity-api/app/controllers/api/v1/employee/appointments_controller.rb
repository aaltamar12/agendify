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

        # POST /api/v1/employee/checkin_by_code
        def checkin_by_code
          appointment = current_employee.business.appointments
            .includes(:service, :employee, :customer)
            .find_by!(ticket_code: params[:ticket_code])

          result = Appointments::CheckinService.call(
            appointment: appointment,
            actor: current_user,
            confirmed: params[:confirmed] == true || params[:confirmed] == "true",
            substitute_reason: params[:substitute_reason]
          )

          if result.success?
            render_checkin_success(result.data)
          elsif result.data.is_a?(Hash) && result.data[:requires_confirmation]
            render json: {
              error: result.error,
              requires_confirmation: true,
              assigned_employee: result.data[:assigned_employee]
            }, status: :conflict
          else
            render_error(result.error, status: :unprocessable_entity)
          end
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
            render_checkin_success(result.data)
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

        private

        def render_checkin_success(checkin_data)
          render json: {
            data: AppointmentSerializer.render_as_hash(checkin_data[:appointment], view: :detailed),
            customer_name: checkin_data[:customer_name],
            last_visit: checkin_data[:last_visit],
            visit_count: checkin_data[:visit_count]
          }, status: :ok
        end
      end
    end
  end
end
