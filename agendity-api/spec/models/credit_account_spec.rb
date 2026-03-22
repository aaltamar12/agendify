require "rails_helper"

RSpec.describe CreditAccount, type: :model do
  describe "associations" do
    it { should belong_to(:customer) }
    it { should belong_to(:business) }
    it { should have_many(:credit_transactions).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_numericality_of(:balance).is_greater_than_or_equal_to(0) }

    it "validates uniqueness of customer_id scoped to business_id" do
      business = create(:business)
      customer = create(:customer, business: business)
      create(:credit_account, customer: customer, business: business)

      duplicate = build(:credit_account, customer: customer, business: business)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:customer_id]).to be_present
    end
  end

  describe "#credit!" do
    let(:account) { create(:credit_account, balance: 0) }

    it "increments balance by the given amount" do
      account.credit!(5_000, transaction_type: :cashback, description: "Test")
      expect(account.balance).to eq(5_000)
    end

    it "creates a CreditTransaction with positive amount" do
      expect {
        account.credit!(5_000, transaction_type: :cashback, description: "Test")
      }.to change(account.credit_transactions, :count).by(1)

      tx = account.credit_transactions.last
      expect(tx.amount).to eq(5_000)
      expect(tx.transaction_type).to eq("cashback")
      expect(tx.description).to eq("Test")
    end

    it "accepts an optional appointment" do
      appointment = create(:appointment)
      account.credit!(1_000, transaction_type: :cashback, description: "Test", appointment: appointment)
      expect(account.credit_transactions.last.appointment).to eq(appointment)
    end

    it "accepts an optional performed_by user" do
      user = create(:user)
      account.credit!(1_000, transaction_type: :manual_adjustment, description: "Test", performed_by: user)
      expect(account.credit_transactions.last.performed_by_user).to eq(user)
    end

    it "accumulates multiple credits" do
      account.credit!(3_000, transaction_type: :cashback, description: "1")
      account.credit!(2_000, transaction_type: :cashback, description: "2")
      expect(account.balance).to eq(5_000)
    end
  end

  describe "#debit!" do
    let(:account) { create(:credit_account, balance: 10_000) }

    it "decrements balance by the given amount" do
      account.debit!(3_000, transaction_type: :redemption, description: "Redeem")
      expect(account.balance).to eq(7_000)
    end

    it "creates a CreditTransaction with negative amount" do
      account.debit!(3_000, transaction_type: :redemption, description: "Redeem")
      tx = account.credit_transactions.last
      expect(tx.amount).to eq(-3_000)
      expect(tx.transaction_type).to eq("redemption")
    end

    it "raises error when balance is insufficient" do
      expect {
        account.debit!(15_000, transaction_type: :redemption, description: "Too much")
      }.to raise_error(RuntimeError, "Saldo insuficiente")
    end

    it "does not create a transaction when balance is insufficient" do
      expect {
        account.debit!(15_000, transaction_type: :redemption, description: "Too much") rescue nil
      }.not_to change(CreditTransaction, :count)
    end

    it "allows debiting the exact balance" do
      account.debit!(10_000, transaction_type: :redemption, description: "All")
      expect(account.balance).to eq(0)
    end
  end
end
