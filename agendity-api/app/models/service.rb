# frozen_string_literal: true

# A service offered by a business (e.g., haircut, beard trim).
class Service < ApplicationRecord
  include BusinessScoped

  # -- Associations --
  has_many :employee_services, dependent: :destroy
  has_many :employees, through: :employee_services
  has_many :appointments, dependent: :restrict_with_error

  # -- Validations --
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }

  # -- Scopes --
  scope :active, -> { where(active: true) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[name price duration_minutes active business_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business employees appointments]
  end
end
