require "rails_helper"

RSpec.describe Referral, type: :model do
  let(:referral_code) { create(:referral_code) }
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:referral_code) }
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:subscription).optional }
  end

  describe "validations" do
    subject { build(:referral, referral_code: referral_code, business: business) }

    it { is_expected.to validate_uniqueness_of(:business_id).scoped_to(:referral_code_id) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, activated: 1, paid: 2) }
  end

  describe "#activate!" do
    let(:plan) { create(:plan, price_monthly: 100_000) }
    let(:subscription) { create(:subscription, business: business, plan: plan) }
    let(:referral) { create(:referral, referral_code: referral_code, business: business) }

    it "activates with commission amount" do
      referral.activate!(subscription)
      referral.reload
      expect(referral.status).to eq("activated")
      expect(referral.subscription).to eq(subscription)
      expect(referral.activated_at).to be_present
      expect(referral.commission_amount).to eq(10_000.0) # 10% of 100,000
    end
  end

  describe "#mark_paid!" do
    let(:referral) { create(:referral, referral_code: referral_code, business: business, status: :activated) }

    it "marks as paid" do
      referral.mark_paid!
      expect(referral.reload.status).to eq("paid")
      expect(referral.paid_at).to be_present
    end
  end
end
