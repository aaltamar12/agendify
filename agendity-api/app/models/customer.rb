# frozen_string_literal: true

# An end-user who books appointments at a business.
# Created automatically when a reservation is made.
class Customer < ApplicationRecord
  include BusinessScoped

  # -- Associations --
  has_many :appointments, dependent: :restrict_with_error
  has_many :reviews, dependent: :nullify

  # -- Validations --
  validates :email, uniqueness: { scope: :business_id, allow_blank: true }

  # -- Scopes --
  scope :with_email, -> { where.not(email: [nil, ""]) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[name email phone business_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business appointments reviews]
  end
end
