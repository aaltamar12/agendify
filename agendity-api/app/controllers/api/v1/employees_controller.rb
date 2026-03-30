# frozen_string_literal: true

module Api
  module V1
    # Full CRUD for employees scoped to the current business.
    # SRP: Only handles HTTP concerns for employee resources.
    class EmployeesController < BaseController
      before_action :set_employee, only: %i[show update destroy upload_avatar invite adjust_balance balance_history]
      before_action :require_intelligent_plan!, only: %i[adjust_balance balance_history]

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

        employee = current_business.employees.build(employee_params.except(:service_ids, :schedules))
        authorize employee

        if employee.save
          employee.service_ids = employee_params[:service_ids] if employee_params[:service_ids].present?
          sync_schedules!(employee)

          # Auto-create from business hours if no schedules were sent
          if employee.employee_schedules.empty?
            current_business.business_hours.where(closed: false).each do |bh|
              employee.employee_schedules.find_or_create_by!(day_of_week: bh.day_of_week) do |es|
                es.start_time = bh.open_time.strftime("%H:%M")
                es.end_time = bh.close_time.strftime("%H:%M")
              end
            end
          end

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

        if @employee.update(employee_params.except(:service_ids, :schedules))
          @employee.service_ids = employee_params[:service_ids] if employee_params.key?(:service_ids)
          sync_schedules!(@employee)
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

      # POST /api/v1/employees/:id/invite
      def invite
        email = params[:email] || @employee.email
        return render_error("Email requerido", status: :unprocessable_entity) if email.blank?

        send_email = params[:send_email] != false && params[:send_email] != "false"
        result = Employees::InviteService.call(employee: @employee, email: email, send_email: send_email)

        if result.success?
          invitation = result.data
          register_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/employee/register?token=#{invitation.token}"
          render_success({ message: "Invitacion enviada", invitation_id: invitation.id, register_url: register_url })
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # POST /api/v1/employees/:id/adjust_balance
      # Manual balance adjustment (Plan Inteligente only)
      def adjust_balance
        result = CashRegister::AdjustBalanceService.call(
          employee: @employee,
          amount: params[:amount],
          reason: params[:reason],
          performed_by: current_user,
          notes: params[:notes]
        )

        if result.success?
          render_success(EmployeeBalanceAdjustmentSerializer.render_as_hash(result.data))
        else
          render_error(result.error, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/employees/:id/balance_history
      # Unified timeline of payments + adjustments (Plan Inteligente only)
      def balance_history
        payments = @employee.employee_payments
          .includes(:cash_register_close)
          .order(created_at: :asc)
          .map do |p|
            {
              type: "payment",
              id: p.id,
              date: p.created_at,
              total_owed: p.total_owed.to_f,
              amount_paid: p.amount_paid.to_f,
              remaining_debt: p.remaining_debt.to_f,
              payment_method: p.payment_method,
              notes: p.notes
            }
          end

        adjustments = @employee.employee_balance_adjustments
          .includes(:performed_by_user)
          .order(created_at: :asc)
          .map do |a|
            {
              type: "adjustment",
              id: a.id,
              date: a.created_at,
              amount: a.amount.to_f,
              balance_before: a.balance_before.to_f,
              balance_after: a.balance_after.to_f,
              reason: a.reason,
              notes: a.notes,
              performed_by: a.performed_by_user&.name
            }
          end

        timeline = (payments + adjustments).sort_by { |entry| entry[:date] }

        render_success({
          employee_id: @employee.id,
          employee_name: @employee.name,
          current_balance: @employee.pending_balance.to_f,
          timeline: timeline
        })
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
        params.require(:employee).permit(
          :name, :phone, :email, :photo_url, :active,
          :payment_type, :commission_percentage, :fixed_daily_pay,
          service_ids: [],
          schedules: [:day_of_week, :start_time, :end_time, :active]
        )
      end

      def sync_schedules!(employee)
        return unless params.dig(:employee, :schedules).present?

        schedules = params[:employee][:schedules]
        schedules.each do |sched|
          day = sched[:day_of_week].to_i
          es = employee.employee_schedules.find_or_initialize_by(day_of_week: day)
          if sched[:active] == false || sched[:active] == "false"
            es.destroy if es.persisted?
          else
            es.start_time = parse_time(sched[:start_time])
            es.end_time = parse_time(sched[:end_time])
            es.save!
          end
        end
      end

      def parse_time(value)
        return value if value.blank?
        return value if value.to_s.match?(/\A\d{2}:\d{2}\z/)
        Time.parse(value.to_s).strftime("%H:%M")
      rescue ArgumentError
        value
      end

      def require_intelligent_plan!
        unless current_business.has_feature?(:ai_features)
          render_error(
            "Esta funcionalidad requiere Plan Inteligente.",
            status: :forbidden
          )
        end
      end
    end
  end
end
