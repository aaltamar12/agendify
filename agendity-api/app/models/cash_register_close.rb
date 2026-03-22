# frozen_string_literal: true

class CashRegisterClose < ApplicationRecord
  belongs_to :business
  belongs_to :closed_by_user, class_name: "User"
  has_many :employee_payments, dependent: :destroy

  accepts_nested_attributes_for :employee_payments

  enum :status, { draft: 0, closed: 1 }

  validates :date, presence: true, uniqueness: { scope: :business_id, message: "ya se cerró caja de este día" }

  scope :recent, -> { order(date: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[date status business_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business closed_by_user employee_payments]
  end
end
