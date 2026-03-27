# frozen_string_literal: true

# Tracks a business that signed up via a referral code.
# Moves from pending -> activated (when subscription starts) -> paid (commission disbursed).
class Referral < ApplicationRecord
  enum :status, { pending: 0, activated: 1, paid: 2 }

  belongs_to :referral_code
  belongs_to :business
  belongs_to :subscription, optional: true

  has_one_attached :disbursement_proof_file

  validates :business_id, uniqueness: { scope: :referral_code_id }

  def activate!(subscription)
    update!(
      status: :activated,
      subscription: subscription,
      activated_at: Date.current,
      commission_amount: subscription.plan.price_monthly * (referral_code.commission_percentage / 100.0)
    )
  end

  def mark_paid!(notes: nil, proof_file: nil)
    self.status = :paid
    self.paid_at = Date.current
    self.disbursement_paid_at = Time.current
    self.disbursement_notes = notes if notes.present?
    self.disbursement_proof_file.attach(proof_file) if proof_file.present?
    save!
  end

  def disbursement_proof_url
    return nil unless disbursement_proof_file.attached?

    Rails.application.routes.url_helpers.rails_blob_url(disbursement_proof_file, only_path: false,
      host: SiteConfig.get("api_url") || "http://localhost:4000")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[status referral_code_id business_id created_at activated_at paid_at disbursement_requested_at disbursement_paid_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[referral_code business subscription]
  end
end
