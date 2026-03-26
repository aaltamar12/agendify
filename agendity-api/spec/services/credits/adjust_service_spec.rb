require "rails_helper"

RSpec.describe Credits::AdjustService do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business) }
  let(:user)     { create(:user) }

  subject do
    described_class.call(
      customer: customer,
      business: business,
      amount: amount,
      description: description,
      performed_by: user
    )
  end

  let(:description) { "Ajuste de cortesía" }

  context "with a positive adjustment" do
    let(:amount) { 10_000 }

    it "returns success" do
      expect(subject).to be_success
    end

    it "creates a CreditAccount if it doesn't exist" do
      expect { subject }.to change(CreditAccount, :count).by(1)
    end

    it "increments the balance" do
      subject
      account = CreditAccount.find_by(customer: customer, business: business)
      expect(account.balance).to eq(10_000)
    end

    it "creates a CreditTransaction with type manual_adjustment" do
      expect { subject }.to change(CreditTransaction, :count).by(1)
      tx = CreditTransaction.last
      expect(tx.transaction_type).to eq("manual_adjustment")
      expect(tx.amount).to eq(10_000)
      expect(tx.description).to eq("Ajuste de cortesía")
      expect(tx.performed_by_user).to eq(user)
    end

    it "accumulates multiple adjustments" do
      described_class.call(customer: customer, business: business, amount: 5_000, description: "1", performed_by: user)
      described_class.call(customer: customer, business: business, amount: 3_000, description: "2", performed_by: user)
      account = CreditAccount.find_by(customer: customer, business: business)
      expect(account.balance).to eq(8_000)
    end
  end

  context "with a negative adjustment" do
    let(:amount) { -5_000 }

    before do
      CreditAccount.create!(customer: customer, business: business, balance: 10_000)
    end

    it "decrements the balance" do
      subject
      account = CreditAccount.find_by(customer: customer, business: business)
      expect(account.balance).to eq(5_000)
    end

    it "creates a CreditTransaction with negative amount" do
      subject
      tx = CreditTransaction.last
      expect(tx.amount).to eq(-5_000)
      expect(tx.transaction_type).to eq("manual_adjustment")
    end
  end

  context "when negative adjustment exceeds balance" do
    let(:amount) { -15_000 }

    before do
      CreditAccount.create!(customer: customer, business: business, balance: 10_000)
    end

    it "raises an error" do
      expect { subject }.to raise_error(RuntimeError, "Saldo insuficiente")
    end
  end

  context "when amount is zero" do
    let(:amount) { 0 }

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("El monto no puede ser cero")
    end
  end

  context "with nil description" do
    let(:amount) { 1_000 }
    let(:description) { nil }

    it "uses default description" do
      subject
      tx = CreditTransaction.last
      expect(tx.description).to eq("Ajuste manual")
    end
  end

  describe "email notification" do
    let(:amount) { 5_000 }

    context "when customer has an email and adjustment is positive" do
      before { customer.update!(email: "cliente@test.com") }

      it "sends a credits_adjusted email" do
        expect { subject }.to have_enqueued_mail(CustomerMailer, :credits_adjusted)
      end
    end

    context "when adjustment is negative" do
      let(:amount) { -1_000 }

      before do
        customer.update!(email: "cliente@test.com")
        CreditAccount.create!(customer: customer, business: business, balance: 10_000)
      end

      it "does not send an email" do
        expect { subject }.not_to have_enqueued_mail(CustomerMailer, :credits_adjusted)
      end
    end

    context "when customer has no email" do
      before { customer.update!(email: nil) }

      it "does not send an email" do
        expect { subject }.not_to have_enqueued_mail(CustomerMailer, :credits_adjusted)
      end
    end
  end
end
