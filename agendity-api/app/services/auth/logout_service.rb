# frozen_string_literal: true

module Auth
  # Invalidates the current session by denylisting the JWT and
  # deleting all refresh tokens for the user.
  class LogoutService < BaseService
    def initialize(user:, token:)
      @user  = user
      @token = token
    end

    def call
      payload = TokenGenerator.decode(@token)
      return failure("Invalid token") unless payload

      ActiveRecord::Base.transaction do
        JwtDenylist.create!(jti: payload[:jti], exp: Time.at(payload[:exp]))
        @user.refresh_tokens.destroy_all
      end

      success
    end
  end
end
