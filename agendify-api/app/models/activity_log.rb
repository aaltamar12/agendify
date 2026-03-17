# frozen_string_literal: true

# Records business activity events (bookings, payments, cancellations, etc.)
# for an auditable history visible in the dashboard.
class ActivityLog < ApplicationRecord
  belongs_to :business

  validates :action, presence: true
  validates :description, presence: true

  scope :recent, -> { order(created_at: :desc).limit(50) }

  # Convenience class method to log an activity in a fire-and-forget style.
  # Falls back silently on errors so it never breaks the main flow.
  def self.log(business:, action:, description:, actor_type: "system", actor_name: nil, resource: nil, metadata: {}, ip_address: nil, request_id: nil)
    merged_metadata = metadata.dup
    merged_metadata[:request_id] = request_id if request_id

    create!(
      business: business,
      action: action,
      description: description,
      actor_type: actor_type,
      actor_name: actor_name,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      metadata: merged_metadata,
      ip_address: ip_address
    )
  rescue StandardError => e
    Rails.logger.error("[ActivityLog] Failed to log activity: #{e.message}")
  end

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[business_id action actor_type actor_name description resource_type resource_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business]
  end
end
