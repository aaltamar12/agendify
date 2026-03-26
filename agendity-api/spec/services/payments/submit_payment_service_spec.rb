require "rails_helper"

RSpec.describe Payments::SubmitPaymentService do
  let(:business)    { create(:business) }
  let(:customer)    { create(:customer, business: business) }
  let(:appointment) { create(:appointment, business: business, customer: customer, status: :pending_payment) }

  describe "#call" do
    context "with valid params" do
      it "creates a payment and updates appointment status" do
        result = described_class.call(
          appointment: appointment,
          payment_method: "transfer",
          amount: 25_000,
          proof_image_url: "https://example.com/proof.jpg"
        )
        expect(result).to be_success
        expect(result.data).to be_a(Payment)
        expect(result.data.status).to eq("submitted")
        expect(result.data.amount).to eq(25_000)
        expect(appointment.reload.status).to eq("payment_sent")
      end

      it "enqueues payment submitted job" do
        described_class.call(
          appointment: appointment,
          payment_method: "transfer",
          amount: 25_000
        )
        expect(SendPaymentSubmittedJob).to have_been_enqueued
      end
    end

    context "with additional_info" do
      it "saves additional_info on the payment" do
        result = described_class.call(
          appointment: appointment,
          payment_method: "transfer",
          amount: 25_000,
          additional_info: "Nombre: Juan Pérez, Dirección: Calle 50 #20"
        )
        expect(result).to be_success
        expect(result.data.additional_info).to eq("Nombre: Juan Pérez, Dirección: Calle 50 #20")
      end

      it "works without additional_info" do
        result = described_class.call(
          appointment: appointment,
          payment_method: "transfer",
          amount: 25_000
        )
        expect(result).to be_success
        expect(result.data.additional_info).to be_nil
      end
    end

    context "with invalid payment data" do
      it "returns failure when amount is invalid" do
        result = described_class.call(
          appointment: appointment,
          payment_method: "transfer",
          amount: -1
        )
        expect(result).to be_failure
      end
    end
  end
end
