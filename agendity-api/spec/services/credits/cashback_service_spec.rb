require "rails_helper"

RSpec.describe Credits::CashbackService do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business) }
  let(:employee) { create(:employee, business: business) }
  let(:service)  { create(:service, business: business, name: "Corte clásico", price: 30_000) }

  let(:appointment) do
    create(:appointment,
      business: business,
      customer: customer,
      employee: employee,
      service: service,
      price: 30_000,
      status: :completed)
  end

  let(:plan_with_cashback) do
    create(:plan,
      name: "Profesional",
      cashback_enabled: true,
      cashback_percentage: 5)
  end

  let(:plan_without_cashback) do
    create(:plan,
      name: "Básico",
      cashback_enabled: false,
      cashback_percentage: 0)
  end

  subject { described_class.call(appointment: appointment) }

  context "when plan has cashback_enabled and percentage > 0" do
    before do
      create(:subscription,
        business: business,
        plan: plan_with_cashback,
        status: :active,
        start_date: Date.current,
        end_date: 30.days.from_now)
    end

    it "returns success with the cashback amount" do
      result = subject
      expect(result).to be_success
      expect(result.data).to eq(1_500) # 5% of 30,000
    end

    it "creates a CreditAccount for the customer if it doesn't exist" do
      expect { subject }.to change(CreditAccount, :count).by(1)
      account = CreditAccount.find_by(customer: customer, business: business)
      expect(account).to be_present
    end

    it "updates the CreditAccount balance correctly" do
      subject
      account = CreditAccount.find_by(customer: customer, business: business)
      expect(account.balance).to eq(1_500)
    end

    it "creates a CreditTransaction with correct amount and type" do
      expect { subject }.to change(CreditTransaction, :count).by(1)
      tx = CreditTransaction.last
      expect(tx.amount).to eq(1_500)
      expect(tx.transaction_type).to eq("cashback")
      expect(tx.appointment).to eq(appointment)
      expect(tx.description).to include("Cashback 5%")
      expect(tx.description).to include("Corte clásico")
    end

    it "uses existing CreditAccount if one already exists" do
      existing = CreditAccount.create!(customer: customer, business: business, balance: 10_000)
      subject
      expect(CreditAccount.where(customer: customer, business: business).count).to eq(1)
      expect(existing.reload.balance).to eq(11_500)
    end
  end

  context "when plan has cashback_enabled false" do
    before do
      create(:subscription,
        business: business,
        plan: plan_without_cashback,
        status: :active,
        start_date: Date.current,
        end_date: 30.days.from_now)
    end

    it "returns success with nil (no cashback)" do
      result = subject
      expect(result).to be_success
      expect(result.data).to be_nil
    end

    it "does not create a CreditAccount" do
      expect { subject }.not_to change(CreditAccount, :count)
    end

    it "does not create a CreditTransaction" do
      expect { subject }.not_to change(CreditTransaction, :count)
    end
  end

  context "when cashback_percentage is 0" do
    before do
      plan = create(:plan, cashback_enabled: true, cashback_percentage: 0)
      create(:subscription,
        business: business,
        plan: plan,
        status: :active,
        start_date: Date.current,
        end_date: 30.days.from_now)
    end

    it "returns success with nil" do
      result = subject
      expect(result).to be_success
      expect(result.data).to be_nil
    end

    it "does not create any credits" do
      expect { subject }.not_to change(CreditTransaction, :count)
    end
  end

  context "when business has no active subscription" do
    it "returns success with nil" do
      result = subject
      expect(result).to be_success
      expect(result.data).to be_nil
    end
  end

  context "when appointment has no customer" do
    before do
      create(:subscription,
        business: business,
        plan: plan_with_cashback,
        status: :active,
        start_date: Date.current,
        end_date: 30.days.from_now)
      allow(appointment).to receive(:customer).and_return(nil)
    end

    it "returns success with nil" do
      result = subject
      expect(result).to be_success
      expect(result.data).to be_nil
    end
  end
end
