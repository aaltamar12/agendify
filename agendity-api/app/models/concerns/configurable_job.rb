# frozen_string_literal: true

# Include in scheduled jobs to check if they're enabled via JobConfig.
# Usage: include ConfigurableJob in your job class, then call
# return unless job_enabled? at the start of perform.
module ConfigurableJob
  extend ActiveSupport::Concern

  private

  def job_enabled?
    JobConfig.enabled?(self.class.name)
  end

  def record_success!(message = nil)
    JobConfig.record_run!(self.class.name, status: "success", message: message)
  end

  def record_error!(message)
    JobConfig.record_run!(self.class.name, status: "error", message: message)
  end
end
