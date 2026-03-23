# frozen_string_literal: true

class BusinessGoal < ApplicationRecord
  belongs_to :business

  GOAL_TYPES = %w[break_even monthly_sales daily_average custom].freeze

  validates :goal_type, presence: true, inclusion: { in: GOAL_TYPES }
  validates :target_value, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[goal_type active business_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business]
  end
end
