# frozen_string_literal: true

# Authenticated user of the platform (business owner or admin).
# Uses JWT for stateless API authentication with denylist revocation.
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # -- Enums --
  enum :role, { owner: 0, admin: 1, employee: 2 }

  # -- Associations --
  has_many :businesses, foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  has_many :refresh_tokens, dependent: :destroy

  # -- Validations --
  validates :name, presence: true
  validates :role, presence: true

  # Returns the first (primary) business for this user.
  def business
    businesses.first
  end

  # Virtual attribute for frontend compatibility.
  def business_id
    business&.id
  end

  # avatar_url is a DB column (added via migration)

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[name email role phone created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[businesses]
  end
end
