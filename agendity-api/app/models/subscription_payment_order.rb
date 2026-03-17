# frozen_string_literal: true

# A payment order generated for an upcoming subscription renewal.
# Tracks whether the business has paid for the next billing period.
class SubscriptionPaymentOrder < ApplicationRecord
  include BusinessScoped

  # -- Associations --
  belongs_to :subscription

  # -- Validations --
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending paid overdue cancelled] }

  # -- Scopes --
  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :overdue, -> { where(status: "overdue") }
  scope :due_within, ->(days) { where(due_date: ..days.days.from_now.to_date) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[status due_date amount period_start period_end business_id subscription_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business subscription]
  end
end
