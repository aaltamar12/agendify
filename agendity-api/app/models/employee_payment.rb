# frozen_string_literal: true

class EmployeePayment < ApplicationRecord
  include AttachmentValidations

  belongs_to :cash_register_close
  belongs_to :employee

  has_one_attached :proof
  validate_attachment :proof, max_size: 2.megabytes

  enum :payment_method, { cash: 0, transfer: 1 }

  validates :total_earned, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid, numericality: { greater_than_or_equal_to: 0 }

  def remaining_debt
    total_owed - amount_paid
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[payment_method cash_register_close_id employee_id amount_paid total_owed created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cash_register_close employee]
  end
end
