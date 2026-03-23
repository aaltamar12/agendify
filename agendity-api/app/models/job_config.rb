# frozen_string_literal: true

# Tracks job configuration: enabled/disabled + last execution status.
# Jobs check JobConfig.enabled?(self.class.name) before executing.
class JobConfig < ApplicationRecord
  validates :job_class, presence: true, uniqueness: true
  validates :name, presence: true

  scope :enabled, -> { where(enabled: true) }

  # Check if a job class is enabled (defaults to true if no config exists)
  def self.enabled?(job_class_name)
    config = find_by(job_class: job_class_name)
    config.nil? || config.enabled?
  end

  # Record execution result
  def self.record_run!(job_class_name, status:, message: nil)
    config = find_by(job_class: job_class_name)
    return unless config

    config.update!(
      last_run_at: Time.current,
      last_run_status: status,
      last_run_message: message
    )
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[job_class name enabled last_run_at last_run_status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
