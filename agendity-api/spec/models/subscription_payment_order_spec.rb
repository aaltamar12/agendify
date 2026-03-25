require "rails_helper"

RSpec.describe SubscriptionPaymentOrder, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:subscription).optional }
    it { is_expected.to belong_to(:plan).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:due_date) }
    it { is_expected.to validate_presence_of(:period_start) }
    it { is_expected.to validate_presence_of(:period_end) }
    it { is_expected.to validate_presence_of(:status) }

    it "validates status inclusion" do
      order = build(:subscription_payment_order, business: business, status: "bogus")
      expect(order).not_to be_valid
    end

    it "accepts valid statuses" do
      %w[pending paid overdue cancelled proof_submitted rejected].each do |s|
        order = build(:subscription_payment_order, business: business, status: s)
        expect(order).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".pending" do
      let!(:pending) { create(:subscription_payment_order, business: business, status: "pending") }
      let!(:paid)    { create(:subscription_payment_order, business: business, status: "paid") }

      it "returns only pending orders" do
        expect(described_class.pending).to include(pending)
        expect(described_class.pending).not_to include(paid)
      end
    end

    describe ".paid" do
      let!(:paid) { create(:subscription_payment_order, business: business, status: "paid") }
      let!(:pending) { create(:subscription_payment_order, business: business, status: "pending") }

      it "returns only paid orders" do
        expect(described_class.paid).to include(paid)
        expect(described_class.paid).not_to include(pending)
      end
    end
  end
end
