# frozen_string_literal: true

class AddPendingBalanceToEmployeesAndProofToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :pending_balance, :decimal, precision: 12, scale: 2, default: 0
    add_column :employee_payments, :pending_from_previous, :decimal, precision: 12, scale: 2, default: 0
    add_column :employee_payments, :total_owed, :decimal, precision: 12, scale: 2, default: 0
  end
end
