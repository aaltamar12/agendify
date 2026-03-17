# frozen_string_literal: true

module Auth
  # Rotates a refresh token: validates the current one, issues a new
  # JWT + refresh token pair, and deletes the old refresh token.
  class RefreshTokenService < BaseService
    def initialize(refresh_token:)
      @refresh_token_string = refresh_token
    end

    def call
      existing = RefreshToken.active.find_by(token: @refresh_token_string)
      return failure("Invalid or expired refresh token") unless existing

      user = existing.user

      ActiveRecord::Base.transaction do
        existing.destroy!

        token             = TokenGenerator.encode(user)
        new_refresh_token = user.refresh_tokens.create!(
          token:      SecureRandom.hex(32),
          expires_at: 30.days.from_now
        )

        success({ token: token, refresh_token: new_refresh_token.token, user: UserSerializer.render_as_hash(user) })
      end
    end
  end
end
