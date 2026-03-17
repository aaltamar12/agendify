# frozen_string_literal: true

module Auth
  # Encapsulates JWT encoding and decoding so that no other class
  # needs to know about the secret key or token structure.
  class TokenGenerator
    ALGORITHM  = "HS256"
    EXPIRATION = 1.day

    class << self
      def encode(user)
        payload = {
          sub: user.id,
          jti: SecureRandom.uuid,
          exp: EXPIRATION.from_now.to_i
        }
        JWT.encode(payload, secret_key, ALGORITHM)
      end

      def decode(token)
        decoded = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
        decoded.first.with_indifferent_access
      rescue JWT::DecodeError, JWT::ExpiredSignature => e
        nil
      end

      private

      def secret_key
        Rails.application.credentials.devise_jwt_secret_key ||
          ENV["DEVISE_JWT_SECRET_KEY"] ||
          "dev-secret-key"
      end
    end
  end
end
