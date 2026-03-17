# frozen_string_literal: true

# Stores revoked JWT tokens to prevent reuse after logout.
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylists"
end
