# frozen_string_literal: true

# A payment order generated for an upcoming subscription renewal.
# Tracks whether the business has paid for the next billing period.
class SubscriptionPaymentOrder < ApplicationRecord
  include BusinessScoped
  include AttachmentValidations

  # -- Associations --
  belongs_to :subscription, optional: true
  belongs_to :plan, optional: true
  has_one_attached :proof
  validate_attachment :proof, max_size: 2.megabytes

  # -- Validations --
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending paid overdue cancelled proof_submitted rejected] }

  # -- Scopes --
  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :overdue, -> { where(status: "overdue") }
  scope :proof_submitted, -> { where(status: "proof_submitted") }
  scope :due_within, ->(days) { where(due_date: ..days.days.from_now.to_date) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[status due_date amount period_start period_end business_id subscription_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business subscription]
  end
end
