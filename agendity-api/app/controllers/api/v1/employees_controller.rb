# frozen_string_literal: true

module Api
  module V1
    # Full CRUD for employees scoped to the current business.
    # SRP: Only handles HTTP concerns for employee resources.
    class EmployeesController < BaseController
      before_action :set_employee, only: %i[show update destroy upload_avatar]

      # GET /api/v1/employees
      def index
        employees = current_business.employees
        render_success(EmployeeSerializer.render_as_hash(employees))
      end

      # GET /api/v1/employees/:id
      def show
        render_success(EmployeeSerializer.render_as_hash(@employee, view: :with_services))
      end

      # POST /api/v1/employees
      def create
        unless current_business.can_create_employee?
          return render_error(
            "Has alcanzado el límite de empleados de tu plan. Mejora tu plan para agregar más.",
            status: :forbidden
          )
        end

        employee = current_business.employees.build(employee_params.except(:service_ids))
        authorize employee

        if employee.save
          employee.service_ids = employee_params[:service_ids] if employee_params[:service_ids].present?
          render_success(EmployeeSerializer.render_as_hash(employee, view: :with_services), status: :created)
        else
          render_error(
            employee.errors.full_messages.to_sentence,
            status: :unprocessable_entity,
            details: employee.errors.messages
          )
        end
      end

      # PATCH /api/v1/employees/:id
      def update
        authorize @employee

        if @employee.update(employee_params.except(:service_ids))
          @employee.service_ids = employee_params[:service_ids] if employee_params.key?(:service_ids)
          render_success(EmployeeSerializer.render_as_hash(@employee, view: :with_services))
        else
          render_error(
            @employee.errors.full_messages.to_sentence,
            status: :unprocessable_entity,
            details: @employee.errors.messages
          )
        end
      end

      # POST /api/v1/employees/:id/upload_avatar
      def upload_avatar
        unless params[:avatar].present?
          return render_error("No se envió ningún archivo", status: :unprocessable_entity)
        end

        @employee.avatar.attach(params[:avatar])

        if @employee.avatar.attached?
          render_success(EmployeeSerializer.render_as_hash(@employee))
        else
          render_error("Error al subir la foto", status: :unprocessable_entity)
        end
      end

      # DELETE /api/v1/employees/:id
      def destroy
        authorize @employee
        @employee.update!(active: false)
        render_success({ message: "Empleado desactivado exitosamente" })
      end

      private

      def set_employee
        @employee = current_business.employees.find(params[:id])
      end

      def employee_params
        params.require(:employee).permit(:name, :phone, :email, :photo_url, :active, :commission_percentage, service_ids: [])
      end
    end
  end
end
