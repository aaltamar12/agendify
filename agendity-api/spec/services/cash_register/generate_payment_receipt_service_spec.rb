# frozen_string_literal: true

require "rails_helper"

RSpec.describe CashRegister::GeneratePaymentReceiptService, type: :service do
  let(:business) { create(:business) }
  let(:close) { create(:cash_register_close, business: business, closed_by_user: business.owner, status: :closed) }
  let(:employee) { create(:employee, business: business, email: "barber@example.com") }
  let(:payment) do
    create(:employee_payment,
      cash_register_close: close,
      employee: employee,
      appointments_count: 8,
      total_earned: 200_000,
      commission_pct: 40,
      commission_amount: 80_000,
      total_owed: 80_000,
      amount_paid: 80_000
    )
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
  end

  describe ".call" do
    it "returns a successful result with PDF data" do
      result = described_class.call(employee_payment: payment)
      expect(result).to be_success
      expect(result.data).to be_a(String)
      expect(result.data.length).to be > 0
    end

    it "generates valid PDF binary starting with PDF header" do
      result = described_class.call(employee_payment: payment)
      expect(result.data[0..3]).to eq("%PDF")
    end
  end
end
