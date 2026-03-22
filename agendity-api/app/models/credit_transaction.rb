# frozen_string_literal: true

class CreditTransaction < ApplicationRecord
  belongs_to :credit_account
  belongs_to :appointment, optional: true
  belongs_to :performed_by_user, class_name: "User", optional: true

  enum :transaction_type, {
    cashback: 0,
    cancellation_refund: 1,
    penalty_deduction: 2,
    manual_adjustment: 3,
    redemption: 4
  }

  validates :amount, numericality: { other_than: 0 }
end
