require "rails_helper"

RSpec.describe CreditTransaction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:credit_account) }
    it { is_expected.to belong_to(:appointment).optional }
    it { is_expected.to belong_to(:performed_by_user).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:amount).is_other_than(0) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:transaction_type).with_values(
        cashback: 0,
        cancellation_refund: 1,
        penalty_deduction: 2,
        manual_adjustment: 3,
        redemption: 4
      )
    }
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to be_an(Array)
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to be_an(Array)
    end
  end

end
