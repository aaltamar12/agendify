# frozen_string_literal: true

# Manual adjustment to an employee's pending_balance.
# Part of the reconciliation ledger alongside EmployeePayments.
class EmployeeBalanceAdjustment < ApplicationRecord
  belongs_to :business
  belongs_to :employee
  belongs_to :performed_by_user, class_name: "User"

  validates :amount, numericality: { other_than: 0 }
  validates :reason, presence: true

  scope :for_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :chronological, -> { order(created_at: :asc) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[business_id employee_id performed_by_user_id amount reason created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business employee performed_by_user]
  end
end
