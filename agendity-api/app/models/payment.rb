# frozen_string_literal: true

# A P2P payment record for an appointment (proof of transfer or cash).
class Payment < ApplicationRecord
  # -- Enums --
  enum :payment_method, { cash: 0, transfer: 1 }
  enum :status, { pending: 0, submitted: 1, approved: 2, rejected: 3 }

  # -- Associations --
  belongs_to :appointment

  # -- Validations --
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true
  validates :status, presence: true

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[status payment_method amount created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[appointment]
  end
end
