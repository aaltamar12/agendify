require "rails_helper"

RSpec.describe CashRegister::ReconciliationService do
  let(:business) { create(:business) }
  let(:user) { create(:user) }
  let(:employee) { create(:employee, business: business, pending_balance: 0) }

  let(:close) do
    create(:cash_register_close,
      business: business,
      closed_by_user: user,
      date: Date.current,
      status: :closed)
  end

  describe "when balances are consistent" do
    before do
      # Employee was owed 40,000, paid 30,000 => remaining 10,000
      create(:employee_payment,
        cash_register_close: close,
        employee: employee,
        total_owed: 40_000,
        amount_paid: 30_000)

      employee.update!(pending_balance: 10_000)
    end

    it "returns success with no discrepancies" do
      result = described_class.call(business: business)
      expect(result).to be_success
      expect(result.data).to be_empty
    end
  end

  describe "detects discrepancy when pending_balance doesn't match payments ledger" do
    before do
      # Payment 1: owed 40,000, paid 30,000 => remaining 10,000
      create(:employee_payment,
        cash_register_close: close,
        employee: employee,
        total_owed: 40_000,
        amount_paid: 30_000)

      # Payment 2: owed 20,000, paid 15,000 => remaining 5,000
      create(:employee_payment,
        cash_register_close: close,
        employee: employee,
        total_owed: 20_000,
        amount_paid: 15_000)

      # Expected pending_balance = 10,000 + 5,000 = 15,000
      # But we set it to something wrong
      employee.update_column(:pending_balance, 8_000)
    end

    it "reports the discrepancy with correct values" do
      result = described_class.call(business: business)
      expect(result).to be_success
      expect(result.data.size).to eq(1)

      disc = result.data.first
      expect(disc[:employee_id]).to eq(employee.id)
      expect(disc[:employee_name]).to eq(employee.name)
      expect(disc[:expected]).to eq(15_000.0)
      expect(disc[:actual]).to eq(8_000.0)
      expect(disc[:difference]).to eq(7_000.0)
      expect(disc[:fixed]).to be false
    end

    it "does not modify the employee balance without fix: true" do
      described_class.call(business: business)
      expect(employee.reload.pending_balance).to eq(8_000)
    end
  end

  describe "auto-correct with fix: true" do
    before do
      create(:employee_payment,
        cash_register_close: close,
        employee: employee,
        total_owed: 50_000,
        amount_paid: 35_000)

      # Expected = 15,000, actual = 0 (wrong)
      employee.update_column(:pending_balance, 0)
    end

    it "corrects the employee pending_balance to the expected value" do
      result = described_class.call(business: business, fix: true)
      expect(result).to be_success
      expect(result.data.size).to eq(1)
      expect(result.data.first[:fixed]).to be true

      expect(employee.reload.pending_balance).to eq(15_000)
    end
  end

  describe "with multiple employees" do
    let(:employee2) { create(:employee, business: business, pending_balance: 0) }

    before do
      # Employee 1: correct balance
      create(:employee_payment,
        cash_register_close: close,
        employee: employee,
        total_owed: 20_000,
        amount_paid: 20_000)
      employee.update!(pending_balance: 0)

      # Employee 2: incorrect balance
      create(:employee_payment,
        cash_register_close: close,
        employee: employee2,
        total_owed: 30_000,
        amount_paid: 10_000)
      # Expected = 20,000 but set to 5,000
      employee2.update_column(:pending_balance, 5_000)
    end

    it "only reports the employee with a discrepancy" do
      result = described_class.call(business: business)
      expect(result.data.size).to eq(1)
      expect(result.data.first[:employee_id]).to eq(employee2.id)
    end
  end
end
