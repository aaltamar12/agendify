# frozen_string_literal: true

# A professional (barber, stylist) who works at a business.
class Employee < ApplicationRecord
  include BusinessScoped

  # -- Attachments --
  has_one_attached :avatar

  # -- Associations --
  belongs_to :user, optional: true
  has_many :employee_invitations, dependent: :destroy
  has_many :employee_services, dependent: :destroy
  has_many :services, through: :employee_services
  has_many :employee_schedules, dependent: :destroy
  has_many :appointments, dependent: :restrict_with_error
  has_many :blocked_slots, dependent: :destroy

  # -- Validations --
  validates :name, presence: true

  # -- Scopes --
  scope :active, -> { where(active: true) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[name active business_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business services appointments]
  end
end
