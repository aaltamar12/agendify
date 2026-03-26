require "rails_helper"

RSpec.describe Payments::RejectPaymentService do
  let(:business)    { create(:business) }
  let(:customer)    { create(:customer, business: business, email: "test@example.com") }
  let(:appointment) { create(:appointment, business: business, customer: customer, status: :payment_sent) }
  let(:payment)     { create(:payment, appointment: appointment, status: :submitted) }

  before do
    allow(Notifications::MultiChannelService).to receive(:call).and_return(
      ServiceResult.new(success: true, data: { email: true })
    )
  end

  describe "#call" do
    context "with valid payment" do
      it "rejects the payment" do
        result = described_class.call(payment: payment, reason: "Monto incorrecto")
        expect(result).to be_success
        expect(payment.reload.status).to eq("rejected")
        expect(payment.rejection_reason).to eq("Monto incorrecto")
        expect(payment.rejected_at).to be_present
      end

      it "reverts appointment to pending_payment" do
        described_class.call(payment: payment, reason: "Invalid proof")
        expect(appointment.reload.status).to eq("pending_payment")
      end

      it "sends notification to customer" do
        described_class.call(payment: payment, reason: "Invalid proof")
        expect(Notifications::MultiChannelService).to have_received(:call)
      end

      it "creates an activity log" do
        expect { described_class.call(payment: payment, reason: "Invalid proof") }
          .to change(ActivityLog, :count).by(1)
        log = ActivityLog.last
        expect(log.action).to eq("payment_rejected")
      end
    end

  end
end
