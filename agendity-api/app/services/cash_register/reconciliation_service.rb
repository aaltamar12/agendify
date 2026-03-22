# frozen_string_literal: true

module CashRegister
  # Reconciles employee pending_balance values against the historical ledger.
  # For each employee: expected = SUM(total_owed - amount_paid) from EmployeePayments
  #                              + SUM(amount) from EmployeeBalanceAdjustments
  # Compares with the current employee.pending_balance and reports discrepancies.
  class ReconciliationService < BaseService
    def initialize(business:, fix: false)
      @business = business
      @fix = fix
    end

    def call
      discrepancies = []

      @business.employees.find_each do |employee|
        # Sum of remaining debt from all employee payments
        payments_balance = employee.employee_payments
          .sum("total_owed - amount_paid")

        # Sum of manual adjustments
        adjustments_balance = employee.employee_balance_adjustments
          .sum(:amount)

        expected = payments_balance + adjustments_balance
        actual = employee.pending_balance || 0

        difference = (expected - actual).round(2)
        next if difference.zero?

        if @fix
          employee.update!(pending_balance: expected)
        end

        discrepancies << {
          employee_id: employee.id,
          employee_name: employee.name,
          expected: expected.to_f,
          actual: actual.to_f,
          difference: difference.to_f,
          fixed: @fix
        }
      end

      success(discrepancies)
    end
  end
end
