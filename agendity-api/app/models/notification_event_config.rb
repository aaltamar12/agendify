# frozen_string_literal: true

# Global configuration for notification events.
# Each record defines how a specific event type behaves
# (browser push, sound, in-app display).
class NotificationEventConfig < ApplicationRecord
  # -- Validations --
  validates :event_key, presence: true, uniqueness: true
  validates :title, presence: true

  # -- Scopes --
  scope :active, -> { where(active: true) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[event_key title body_template browser_notification sound_enabled in_app_notification active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
