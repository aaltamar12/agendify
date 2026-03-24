require "rails_helper"

RSpec.describe Subscriptions::CheckoutService do
  let(:business) { create(:business) }
  let(:plan)     { create(:plan, name: "Profesional", price_monthly: 49_900) }
  let(:proof)    { fixture_file_upload("spec/fixtures/files/proof.png", "image/png") }

  before do
    # Stub external side effects
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
  end

  describe "#call" do
    subject { described_class.call(business: business, plan_id: plan.id, proof: proof) }

    context "with valid params" do
      it "creates a SubscriptionPaymentOrder with status proof_submitted" do
        result = subject

        expect(result).to be_success
        order = SubscriptionPaymentOrder.last
        expect(order.status).to eq("proof_submitted")
        expect(order.business).to eq(business)
        expect(order.plan).to eq(plan)
        expect(order.amount).to eq(49_900)
        expect(order.proof_submitted_at).to be_present
      end

      it "associates the correct plan" do
        result = subject
        order = SubscriptionPaymentOrder.find(result.data[:order_id])

        expect(order.plan).to eq(plan)
        expect(order.amount).to eq(plan.price_monthly)
      end

      it "attaches the proof of payment" do
        subject
        order = SubscriptionPaymentOrder.last

        expect(order.proof).to be_attached
      end

      it "enqueues NotifyAdminSubscriptionProofJob" do
        expect { subject }.to have_enqueued_job(NotifyAdminSubscriptionProofJob)
      end

      it "creates an AdminNotification" do
        expect { subject }.to change(AdminNotification, :count).by(1)

        notification = AdminNotification.last
        expect(notification.title).to eq("Nuevo comprobante de pago")
        expect(notification.notification_type).to eq("subscription_proof")
      end

      it "returns order_id and status in the result data" do
        result = subject

        expect(result.data[:order_id]).to be_present
        expect(result.data[:status]).to eq("proof_submitted")
      end
    end

    context "when plan does not exist" do
      subject { described_class.call(business: business, plan_id: -1, proof: proof) }

      it "returns failure with PLAN_NOT_FOUND" do
        result = subject

        expect(result).to be_failure
        expect(result.error_code).to eq("PLAN_NOT_FOUND")
      end

      it "does not create a payment order" do
        expect { subject }.not_to change(SubscriptionPaymentOrder, :count)
      end
    end

    context "when proof is blank" do
      subject { described_class.call(business: business, plan_id: plan.id, proof: nil) }

      it "returns failure with PROOF_REQUIRED" do
        result = subject

        expect(result).to be_failure
        expect(result.error_code).to eq("PROOF_REQUIRED")
      end

      it "does not create a payment order" do
        expect { subject }.not_to change(SubscriptionPaymentOrder, :count)
      end
    end
  end
end
