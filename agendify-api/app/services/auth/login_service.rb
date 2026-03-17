# frozen_string_literal: true

module Auth
  # Authenticates an existing user by email + password and returns
  # a fresh JWT token pair.
  class LoginService < BaseService
    def initialize(email:, password:)
      @email    = email
      @password = password
    end

    def call
      user = User.find_by(email: @email)
      return failure("Credenciales invalidas") unless user&.valid_password?(@password)

      token         = TokenGenerator.encode(user)
      refresh_token = create_refresh_token(user)

      success({ token: token, refresh_token: refresh_token.token, user: UserSerializer.render_as_hash(user) })
    end

    private

    def create_refresh_token(user)
      user.refresh_tokens.create!(
        token:      SecureRandom.hex(32),
        expires_at: 30.days.from_now
      )
    end
  end
end
