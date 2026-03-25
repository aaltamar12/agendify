require "rails_helper"

RSpec.describe NotifyAdminSubscriptionProofJob, type: :job do
  let(:business) { create(:business) }
  let(:plan)     { create(:plan) }
  let!(:subscription) { create(:subscription, business: business, plan: plan) }
  let!(:order) do
    create(:subscription_payment_order, subscription: subscription, business: business, plan: plan)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  describe "#perform" do
    it "sends an admin email" do
      expect { described_class.perform_now(order.id) }
        .to have_enqueued_mail(AdminMailer, :subscription_proof_received)
    end

    context "when admin_whatsapp is configured" do
      before do
        require "ostruct"
        allow(SiteConfig).to receive(:get).with("admin_whatsapp").and_return("+573001234567")
      end

      it "sends a WhatsApp notification" do
        described_class.perform_now(order.id)
        expect(Notifications::WhatsAppChannel).to have_received(:deliver).with(
          hash_including(template: :subscription_proof_received)
        )
      end
    end

    context "when admin_whatsapp is not configured" do
      it "does not send a WhatsApp notification" do
        described_class.perform_now(order.id)
        expect(Notifications::WhatsAppChannel).not_to have_received(:deliver)
      end
    end
  end
end
