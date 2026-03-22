# frozen_string_literal: true

class EmployeePayment < ApplicationRecord
  belongs_to :cash_register_close
  belongs_to :employee

  has_one_attached :proof

  enum :payment_method, { cash: 0, transfer: 1 }

  validates :total_earned, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid, numericality: { greater_than_or_equal_to: 0 }

  def remaining_debt
    total_owed - amount_paid
  end
end
