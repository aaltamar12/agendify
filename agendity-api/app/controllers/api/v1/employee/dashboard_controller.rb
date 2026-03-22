# frozen_string_literal: true

module Api
  module V1
    module Employee
      class DashboardController < BaseController
        # GET /api/v1/employee/dashboard
        def show
          employee = current_employee
          return render_error("Empleado no encontrado", status: :not_found) unless employee

          today_appointments = employee.appointments
            .includes(:service, :customer)
            .where(appointment_date: Date.current)
            .order(:start_time)

          month_completed = employee.appointments
            .where(status: :completed)
            .where("appointment_date >= ?", Date.current.beginning_of_month)

          render_success({
            employee: EmployeeSerializer.render_as_hash(employee),
            business: employee.business ? { name: employee.business.name, logo_url: employee.business.logo_url } : nil,
            today: AppointmentSerializer.render_as_hash(today_appointments, view: :detailed),
            stats: {
              today_count: today_appointments.size,
              month_completed: month_completed.count,
              month_revenue: month_completed.sum(:price).to_f
            }
          })
        end

        # GET /api/v1/employee/score
        def score
          employee = current_employee
          return render_error("Empleado no encontrado", status: :not_found) unless employee

          result = Employees::ScoreService.call(employee: employee)
          if result.success?
            render_success(result.data)
          else
            render_error(result.error)
          end
        end
      end
    end
  end
end
