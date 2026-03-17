# frozen_string_literal: true

# Stores refresh tokens for JWT token rotation.
class RefreshToken < ApplicationRecord
  # -- Associations --
  belongs_to :user

  # -- Validations --
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # -- Scopes --
  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
end
