# frozen_string_literal: true

# A professional (barber, stylist) who works at a business.
class Employee < ApplicationRecord
  include BusinessScoped
  include AttachmentValidations

  # -- Attachments --
  has_one_attached :avatar
  validate_attachment :avatar, max_size: 5.megabytes

  # -- Associations --
  belongs_to :user, optional: true
  has_many :employee_invitations, dependent: :destroy
  has_many :employee_services, dependent: :destroy
  has_many :services, through: :employee_services
  has_many :employee_schedules, dependent: :destroy
  has_many :appointments, dependent: :restrict_with_error
  has_many :blocked_slots, dependent: :destroy
  has_many :employee_payments, dependent: :restrict_with_error
  has_many :employee_balance_adjustments, dependent: :destroy

  # -- Enums --
  enum :payment_type, { manual: "none", commission: "commission", fixed_daily: "fixed_daily" }, default: :manual

  # -- Callbacks --
  before_save :clear_unused_payment_fields

  # -- Validations --
  validates :name, presence: true
  validates :payment_type, inclusion: { in: payment_types.keys }
  validates :commission_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, if: -> { commission? }
  validates :fixed_daily_pay, numericality: { greater_than: 0 }, if: -> { fixed_daily? }

  # -- Scopes --
  scope :active, -> { where(active: true) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[name active business_id document_number document_type fiscal_address payment_type created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business services appointments]
  end

  private

  def clear_unused_payment_fields
    self.commission_percentage = 0 unless commission?
    self.fixed_daily_pay = 0 unless fixed_daily?
  end
end
