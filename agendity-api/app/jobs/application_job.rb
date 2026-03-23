# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  include ConfigurableJob

  # Automatically retry jobs that encountered a deadlock.
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available.
  discard_on ActiveJob::DeserializationError

  # Track execution in JobConfig after every perform
  after_perform do |job|
    record_success!("OK") unless @_already_recorded
  end

  rescue_from(StandardError) do |exception|
    record_error!(exception.message)
    raise # re-raise so Sidekiq handles retries
  end
end
