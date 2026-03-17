# frozen_string_literal: true

# Deletes expired refresh tokens and old JWT denylist entries.
class CleanupExpiredTokensJob < ApplicationJob
  queue_as :low

  def perform
    # Remove expired refresh tokens
    RefreshToken.where("expires_at < ?", Time.current).delete_all

    # Remove old JWT denylist entries (tokens expired more than 24 hours ago)
    JwtDenylist.where("exp < ?", 24.hours.ago).delete_all
  end
end
