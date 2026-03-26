require "rails_helper"

RSpec.describe Payment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:appointment) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:payment_method) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:payment_method).with_values(cash: 0, transfer: 1) }
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, submitted: 1, approved: 2, rejected: 3) }
  end

  describe "validations edge cases" do
    it "is invalid with zero amount" do
      payment = build(:payment, amount: 0)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to be_present
    end

    it "is invalid with negative amount" do
      payment = build(:payment, amount: -100)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to be_present
    end
  end

  describe "enum behavior" do
    it "can transition between statuses" do
      payment = create(:payment, status: :pending)
      payment.submitted!
      expect(payment.reload).to be_submitted

      payment.approved!
      expect(payment.reload).to be_approved
    end

    it "supports cash and transfer payment methods" do
      payment = create(:payment, payment_method: :cash)
      expect(payment).to be_cash

      payment.transfer!
      expect(payment.reload).to be_transfer
    end
  end
end
