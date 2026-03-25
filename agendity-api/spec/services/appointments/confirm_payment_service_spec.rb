require "rails_helper"

RSpec.describe Appointments::ConfirmPaymentService do
  let(:business) { create(:business) }
  let(:appointment) { create(:appointment, business: business, status: :pending_payment, ticket_code: nil) }

  describe "#call" do
    context "when appointment is pending_payment" do
      it "confirms the appointment" do
        result = described_class.call(appointment: appointment)
        expect(result).to be_success
        expect(appointment.reload.status).to eq("confirmed")
      end
    end

    context "when appointment is payment_sent" do
      before { appointment.update_column(:status, :payment_sent) }

      it "confirms the appointment" do
        result = described_class.call(appointment: appointment)
        expect(result).to be_success
        expect(appointment.reload.status).to eq("confirmed")
      end
    end

    context "when appointment is already confirmed" do
      before { appointment.update_column(:status, :confirmed) }

      it "returns failure" do
        result = described_class.call(appointment: appointment)
        expect(result).to be_failure
        expect(result.error_code).to eq("INVALID_STATUS_FOR_CONFIRM")
      end
    end

    context "when business has ticket_digital feature" do
      before do
        allow(business).to receive(:has_feature?).with(:ticket_digital).and_return(true)
      end

      it "generates a ticket code" do
        result = described_class.call(appointment: appointment)
        expect(result).to be_success
        expect(appointment.reload.ticket_code).to be_present
      end
    end
  end
end
