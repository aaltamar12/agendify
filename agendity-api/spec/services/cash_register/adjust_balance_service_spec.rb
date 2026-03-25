require "rails_helper"

RSpec.describe CashRegister::AdjustBalanceService do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business, pending_balance: 50_000) }
  let(:user)     { business.owner }

  describe "#call" do
    context "with valid positive adjustment" do
      it "increases employee balance" do
        result = described_class.call(
          employee: employee, amount: 10_000, reason: "Bonus", performed_by: user
        )
        expect(result).to be_success
        expect(employee.reload.pending_balance).to eq(60_000)
      end

      it "creates an EmployeeBalanceAdjustment record" do
        expect {
          described_class.call(employee: employee, amount: 10_000, reason: "Bonus", performed_by: user)
        }.to change(EmployeeBalanceAdjustment, :count).by(1)
      end

      it "records before/after values" do
        result = described_class.call(employee: employee, amount: 10_000, reason: "Bonus", performed_by: user)
        adj = result.data
        expect(adj.balance_before).to eq(50_000)
        expect(adj.balance_after).to eq(60_000)
      end
    end

    context "with negative adjustment" do
      it "decreases employee balance" do
        result = described_class.call(
          employee: employee, amount: -20_000, reason: "Deduction", performed_by: user
        )
        expect(result).to be_success
        expect(employee.reload.pending_balance).to eq(30_000)
      end
    end

    context "when amount is zero" do
      it "returns failure" do
        result = described_class.call(employee: employee, amount: 0, reason: "Zero", performed_by: user)
        expect(result).to be_failure
        expect(result.error).to include("cero")
      end
    end

    context "when reason is blank" do
      it "returns failure" do
        result = described_class.call(employee: employee, amount: 10_000, reason: "", performed_by: user)
        expect(result).to be_failure
        expect(result.error).to include("razon")
      end
    end
  end
end
