# frozen_string_literal: true

# A booked appointment linking a customer, employee, and service.
class Appointment < ApplicationRecord
  include BusinessScoped
  include AttachmentValidations

  # -- Enums --
  enum :status, {
    pending_payment: 0,
    payment_sent: 1,
    confirmed: 2,
    checked_in: 3,
    cancelled: 4,
    completed: 5
  }

  # -- Associations --
  belongs_to :employee
  belongs_to :service
  belongs_to :customer
  belongs_to :discount_code, optional: true
  has_one :payment, dependent: :destroy
  has_one_attached :proof_image
  has_many :appointment_services, dependent: :destroy
  has_many :additional_services, through: :appointment_services, source: :service

  # -- Attachment validations --
  validate_attachment :proof_image, max_size: 2.megabytes

  # -- Validations --
  validates :appointment_date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :ticket_code, uniqueness: true, allow_nil: true

  # -- Scopes --
  scope :upcoming, -> { where("appointment_date >= ?", Date.current).order(:appointment_date, :start_time) }
  scope :on_date, ->(date) { where(appointment_date: date) }
  scope :for_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :active, -> { where.not(status: [:cancelled, :completed]) }

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[status appointment_date business_id employee_id service_id customer_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business employee service customer payment]
  end
end
