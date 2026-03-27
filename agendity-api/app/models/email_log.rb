# frozen_string_literal: true

class EmailLog < ApplicationRecord
  validates :recipient, :subject, presence: true

  scope :recent, -> { order(created_at: :desc).limit(100) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[recipient subject mailer_class mailer_action status created_at]
  end
end
