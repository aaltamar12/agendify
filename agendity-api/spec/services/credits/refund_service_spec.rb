require "rails_helper"

RSpec.describe Credits::RefundService do
  let(:business) { create(:business, cancellation_policy_pct: 20) }
  let(:customer) { create(:customer, business: business) }
  let(:employee) { create(:employee, business: business) }
  let(:service)  { create(:service, business: business, name: "Corte premium", price: 50_000) }

  let(:appointment) do
    create(:appointment,
      business: business,
      customer: customer,
      employee: employee,
      service: service,
      price: 50_000,
      status: :cancelled)
  end

  let(:plan_with_cashback) do
    create(:plan, name: "Profesional", cashback_enabled: true, cashback_percentage: 5)
  end

  let(:plan_without_cashback) do
    create(:plan, name: "Básico", cashback_enabled: false, cashback_percentage: 0)
  end

  subject { described_class.call(appointment: appointment) }

  context "when plan has cashback enabled" do
    before do
      create(:subscription,
        business: business,
        plan: plan_with_cashback,
        status: :active,
        start_date: Date.current,
        end_date: 30.days.from_now)
    end

    it "refunds the appointment price minus penalty as credits" do
      result = subject
      expect(result).to be_success
      # penalty = 50,000 * 20% = 10,000; refund = 50,000 - 10,000 = 40,000
      expect(result.data[:refund]).to eq(40_000)
      expect(result.data[:penalty]).to eq(10_000)
    end

    it "creates a CreditAccount if it doesn't exist" do
      expect { subject }.to change(CreditAccount, :count).by(1)
    end

    it "credits the correct refund amount to the account" do
      subject
      account = CreditAccount.find_by(customer: customer, business: business)
      expect(account.balance).to eq(40_000)
    end

    it "creates a CreditTransaction with type cancellation_refund" do
      expect { subject }.to change(CreditTransaction, :count).by(1)
      tx = CreditTransaction.last
      expect(tx.transaction_type).to eq("cancellation_refund")
      expect(tx.amount).to eq(40_000)
      expect(tx.appointment).to eq(appointment)
      expect(tx.description).to include("Reembolso por cancelacion")
    end

    context "when cancellation_policy_pct is 0" do
      let(:business) { create(:business, cancellation_policy_pct: 0) }

      it "refunds the full price" do
        result = subject
        expect(result.data[:refund]).to eq(50_000)
        expect(result.data[:penalty]).to eq(0)
      end
    end

    context "when cancellation_policy_pct is 100" do
      let(:business) { create(:business, cancellation_policy_pct: 100) }

      it "refunds zero (full penalty)" do
        result = subject
        expect(result.data[:refund]).to eq(0)
        expect(result.data[:penalty]).to eq(50_000)
      end

      it "does not create a credit transaction" do
        expect { subject }.not_to change(CreditTransaction, :count)
      end
    end
  end

  context "when plan has no cashback" do
    before do
      create(:subscription,
        business: business,
        plan: plan_without_cashback,
        status: :active,
        start_date: Date.current,
        end_date: 30.days.from_now)
    end

    it "returns success with nil" do
      result = subject
      expect(result).to be_success
      expect(result.data).to be_nil
    end

    it "does not create credits" do
      expect { subject }.not_to change(CreditTransaction, :count)
    end
  end

  context "when business has no subscription" do
    it "returns success with nil" do
      result = subject
      expect(result).to be_success
      expect(result.data).to be_nil
    end
  end
end
