# frozen_string_literal: true

# An in-app notification delivered to a business.
class Notification < ApplicationRecord
  belongs_to :business

  # -- Validations --
  validates :title, presence: true
  validates :notification_type, presence: true,
    inclusion: { in: %w[new_booking payment_submitted payment_approved booking_cancelled reminder ai_suggestion subscription_expiry] }

  # -- Scopes --
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[title notification_type read business_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business]
  end
end
