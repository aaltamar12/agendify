# frozen_string_literal: true

# A discount code that can be applied to an appointment.
# Created manually by the business, or automatically by birthday campaigns.
class DiscountCode < ApplicationRecord
  include BusinessScoped

  belongs_to :customer, optional: true
  has_many :appointments, dependent: :nullify

  validates :code, presence: true, uniqueness: { scope: :business_id, case_sensitive: false }
  validates :discount_type, inclusion: { in: %w[percentage fixed] }
  validates :discount_value, numericality: { greater_than: 0 }
  validates :discount_value, numericality: { less_than_or_equal_to: 100 }, if: -> { percentage? }

  before_validation :generate_code, on: :create, if: -> { code.blank? }
  before_validation :upcase_code

  scope :active, -> { where(active: true) }
  scope :valid_now, -> { active.where("(valid_from IS NULL OR valid_from <= ?) AND (valid_until IS NULL OR valid_until >= ?)", Date.current, Date.current) }
  scope :available, -> { valid_now.where("max_uses IS NULL OR current_uses < max_uses") }

  def percentage? = discount_type == "percentage"
  def fixed? = discount_type == "fixed"

  def usable?
    active? && !expired? && !exhausted?
  end

  def expired?
    valid_until.present? && valid_until < Date.current
  end

  def exhausted?
    max_uses.present? && current_uses >= max_uses
  end

  def apply_to(price)
    discount = percentage? ? (price * discount_value / 100.0).round(0) : discount_value
    [discount, price].min # Can't discount more than the price
  end

  def record_use!
    increment!(:current_uses)
  end

  def self.ransackable_attributes(...)
    %w[code name discount_type active source valid_from valid_until business_id customer_id created_at]
  end

  def self.ransackable_associations(...)
    %w[business customer]
  end

  private

  def generate_code
    self.code = SecureRandom.alphanumeric(8).upcase
  end

  def upcase_code
    self.code = code&.upcase
  end
end
