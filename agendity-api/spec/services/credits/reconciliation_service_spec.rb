require "rails_helper"

RSpec.describe Credits::ReconciliationService do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business) }

  let(:credit_account) do
    create(:credit_account, business: business, customer: customer, balance: 0)
  end

  describe "when balances are consistent" do
    before do
      create(:credit_transaction,
        credit_account: credit_account,
        amount: 10_000,
        transaction_type: :cashback)
      create(:credit_transaction,
        credit_account: credit_account,
        amount: -3_000,
        transaction_type: :redemption)

      credit_account.update!(balance: 7_000)
    end

    it "returns success with no discrepancies" do
      result = described_class.call(business: business)
      expect(result).to be_success
      expect(result.data).to be_empty
    end
  end

  describe "detects discrepancy when balance doesn't match sum of transactions" do
    before do
      create(:credit_transaction,
        credit_account: credit_account,
        amount: 15_000,
        transaction_type: :cashback)
      create(:credit_transaction,
        credit_account: credit_account,
        amount: 5_000,
        transaction_type: :cancellation_refund)
      create(:credit_transaction,
        credit_account: credit_account,
        amount: -8_000,
        transaction_type: :redemption)

      # Expected balance = 15,000 + 5,000 - 8,000 = 12,000
      # But we set it to something wrong
      credit_account.update_column(:balance, 20_000)
    end

    it "reports the discrepancy with correct values" do
      result = described_class.call(business: business)
      expect(result).to be_success
      expect(result.data.size).to eq(1)

      disc = result.data.first
      expect(disc[:credit_account_id]).to eq(credit_account.id)
      expect(disc[:customer_id]).to eq(customer.id)
      expect(disc[:customer_name]).to eq(customer.name)
      expect(disc[:expected]).to eq(12_000.0)
      expect(disc[:actual]).to eq(20_000.0)
      expect(disc[:difference]).to eq(-8_000.0)
      expect(disc[:fixed]).to be false
    end

    it "does not modify the account balance without fix: true" do
      described_class.call(business: business)
      expect(credit_account.reload.balance).to eq(20_000)
    end
  end

  describe "auto-correct with fix: true" do
    before do
      create(:credit_transaction,
        credit_account: credit_account,
        amount: 10_000,
        transaction_type: :cashback)

      # Expected = 10,000, actual = 3,000 (wrong)
      credit_account.update_column(:balance, 3_000)
    end

    it "corrects the account balance to the expected value" do
      result = described_class.call(business: business, fix: true)
      expect(result).to be_success
      expect(result.data.size).to eq(1)
      expect(result.data.first[:fixed]).to be true

      expect(credit_account.reload.balance).to eq(10_000)
    end
  end

  describe "floors expected balance at zero" do
    before do
      # Transactions that net negative (shouldn't happen normally, but edge case)
      create(:credit_transaction,
        credit_account: credit_account,
        amount: -5_000,
        transaction_type: :redemption)

      # Expected = max(-5000, 0) = 0, actual = 1000 (wrong)
      credit_account.update_column(:balance, 1_000)
    end

    it "treats expected as 0 and reports the discrepancy" do
      result = described_class.call(business: business)
      expect(result.data.size).to eq(1)
      expect(result.data.first[:expected]).to eq(0.0)
      expect(result.data.first[:actual]).to eq(1_000.0)
    end

    it "corrects balance to 0 with fix: true" do
      described_class.call(business: business, fix: true)
      expect(credit_account.reload.balance).to eq(0)
    end
  end

  describe "with multiple accounts" do
    let(:customer2) { create(:customer, business: business) }
    let(:credit_account2) do
      create(:credit_account, business: business, customer: customer2, balance: 0)
    end

    before do
      # Account 1: consistent
      create(:credit_transaction,
        credit_account: credit_account,
        amount: 5_000,
        transaction_type: :cashback)
      credit_account.update!(balance: 5_000)

      # Account 2: inconsistent
      create(:credit_transaction,
        credit_account: credit_account2,
        amount: 8_000,
        transaction_type: :cashback)
      credit_account2.update_column(:balance, 2_000)
    end

    it "only reports the account with a discrepancy" do
      result = described_class.call(business: business)
      expect(result.data.size).to eq(1)
      expect(result.data.first[:credit_account_id]).to eq(credit_account2.id)
    end
  end
end
