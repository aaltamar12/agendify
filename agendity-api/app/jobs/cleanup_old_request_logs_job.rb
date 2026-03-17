# frozen_string_literal: true

# Periodically removes old request logs to prevent unbounded table growth.
# Keeps error logs (status >= 400) for 90 days, everything else for 30 days.
class CleanupOldRequestLogsJob < ApplicationJob
  queue_as :low

  def perform
    # Delete successful request logs older than 30 days
    deleted_ok = RequestLog.where("status_code < 400 AND created_at < ?", 30.days.ago).delete_all

    # Delete error logs older than 90 days
    deleted_errors = RequestLog.where("status_code >= 400 AND created_at < ?", 90.days.ago).delete_all

    Rails.logger.info(
      "[CleanupOldRequestLogsJob] Deleted #{deleted_ok} old request logs " \
      "and #{deleted_errors} old error logs."
    )
  end
end
