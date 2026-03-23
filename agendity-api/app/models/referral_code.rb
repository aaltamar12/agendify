# frozen_string_literal: true

# A referral code issued to a referrer (ambassador, partner, etc.).
# Tracks commission percentage and links to businesses that signed up with it.
class ReferralCode < ApplicationRecord
  enum :status, { active: 0, inactive: 1 }

  has_many :referrals, dependent: :restrict_with_error
  has_many :businesses, dependent: :nullify

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :referrer_name, presence: true
  validates :commission_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  before_validation :generate_code, on: :create, if: -> { code.blank? }

  scope :active, -> { where(status: :active) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[code referrer_name referrer_email status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[referrals businesses]
  end

  private

  def generate_code
    self.code = SecureRandom.alphanumeric(8).upcase
  end
end
