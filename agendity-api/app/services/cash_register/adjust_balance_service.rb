# frozen_string_literal: true

module CashRegister
  # Creates a manual adjustment to an employee's pending_balance.
  # Records the before/after values and logs the activity.
  class AdjustBalanceService < BaseService
    def initialize(employee:, amount:, reason:, performed_by:, notes: nil)
      @employee = employee
      @amount = amount.to_d
      @reason = reason
      @performed_by = performed_by
      @notes = notes
    end

    def call
      return failure("El monto no puede ser cero") if @amount.zero?
      return failure("La razon es obligatoria") if @reason.blank?

      balance_before = @employee.pending_balance || 0
      balance_after = balance_before + @amount

      ActiveRecord::Base.transaction do
        adjustment = EmployeeBalanceAdjustment.create!(
          business: @employee.business,
          employee: @employee,
          performed_by_user: @performed_by,
          amount: @amount,
          balance_before: balance_before,
          balance_after: balance_after,
          reason: @reason,
          notes: @notes
        )

        @employee.update!(pending_balance: balance_after)

        ActivityLog.log(
          business: @employee.business,
          action: "employee_balance_adjusted",
          description: "Ajuste de saldo de #{@employee.name}: #{format_amount(balance_before)} -> #{format_amount(balance_after)} (#{@reason})",
          actor_type: "business",
          actor_name: @performed_by.name,
          resource: adjustment
        )

        success(adjustment)
      end
    end

    private

    def format_amount(amount)
      "$#{amount.to_i}"
    end
  end
end
