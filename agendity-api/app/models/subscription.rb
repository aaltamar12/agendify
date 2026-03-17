# frozen_string_literal: true

# A business subscription to a plan.
class Subscription < ApplicationRecord
  include BusinessScoped

  # -- Enums --
  enum :status, { active: 0, expired: 1, cancelled: 2 }

  # -- Associations --
  belongs_to :plan
  has_many :subscription_payment_orders, dependent: :destroy

  # -- Validations --
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true

  # -- Scopes --
  scope :active, -> { where(status: :active) }
  scope :current, -> { active.where("end_date >= ?", Date.current) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[status start_date end_date business_id plan_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business plan]
  end
end
