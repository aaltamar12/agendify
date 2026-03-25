require "rails_helper"

RSpec.describe AdminMailer, type: :mailer do
  let(:business) { create(:business) }
  let(:plan)     { create(:plan, name: "Profesional") }
  let!(:subscription) { create(:subscription, business: business, plan: plan) }
  let(:order) do
    create(:subscription_payment_order, subscription: subscription, business: business, plan: plan, amount: 49_900)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(SiteConfig).to receive(:get).and_return(nil)
    allow(SiteConfig).to receive(:get).with("admin_email").and_return("admin@agendity.com")
  end

  describe "#subscription_proof_received" do
    let(:mail) { described_class.subscription_proof_received(order) }

    it "renders without error" do
      expect(mail.to).to eq(["admin@agendity.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("Comprobante de pago")
      expect(mail.subject).to include(business.name)
    end
  end
end
