require "rails_helper"

RSpec.describe EmployeePayment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cash_register_close) }
    it { is_expected.to belong_to(:employee) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:total_earned).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:amount_paid).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:payment_method).with_values(cash: 0, transfer: 1) }
  end

  describe "#remaining_debt" do
    it "calculates the difference between total_owed and amount_paid" do
      payment = build(:employee_payment, total_owed: 50_000, amount_paid: 30_000)
      expect(payment.remaining_debt).to eq(20_000)
    end
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
