# frozen_string_literal: true

# A subscription plan available on the platform.
# Managed by admin users via ActiveAdmin.
class Plan < ApplicationRecord
  # -- Associations --
  has_many :subscriptions, dependent: :restrict_with_error

  # -- Validations --
  validates :name, presence: true, uniqueness: true
  validates :price_monthly, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[name ai_features ticket_digital created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[subscriptions]
  end
end
