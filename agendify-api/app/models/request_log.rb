# frozen_string_literal: true

# Tracks every API request for debugging, auditing, and tracing
# the full lifecycle of appointments (booking → payment → check-in).
class RequestLog < ApplicationRecord
  belongs_to :business, optional: true

  scope :errors, -> { where("status_code >= 400") }
  scope :server_errors, -> { where("status_code >= 500") }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :slow_requests, ->(threshold_ms = 1000) { where("duration_ms > ?", threshold_ms) }

  def error? = status_code.to_i >= 400
  def server_error? = status_code.to_i >= 500

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[method path controller_action status_code duration_ms ip_address
       request_id resource_type resource_id error_message created_at business_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business]
  end
end
