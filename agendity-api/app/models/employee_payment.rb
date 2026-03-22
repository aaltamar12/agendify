# frozen_string_literal: true

class EmployeePayment < ApplicationRecord
  belongs_to :cash_register_close
  belongs_to :employee

  enum :payment_method, { cash: 0, transfer: 1 }

  validates :total_earned, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid, numericality: { greater_than_or_equal_to: 0 }
end
