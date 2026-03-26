require "rails_helper"

RSpec.describe Notifications::MultiChannelService do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business, email: "test@example.com") }

  before do
    allow(Notifications::EmailChannel).to receive(:deliver).and_return(true)
    allow(Notifications::WhatsappChannel).to receive(:deliver).and_return(true)
  end

  describe "#call" do
    context "without WhatsApp plan" do
      before do
        allow(business).to receive_message_chain(:current_plan, :whatsapp_notifications?).and_return(false)
      end

      it "sends only via email" do
        result = described_class.call(recipient: customer, template: :rating_request, data: {}, business: business)
        expect(result).to be_success
        expect(Notifications::EmailChannel).to have_received(:deliver)
        expect(Notifications::WhatsappChannel).not_to have_received(:deliver)
      end
    end

    context "with WhatsApp plan" do
      let(:plan) { create(:plan, whatsapp_notifications: true) }
      let!(:subscription) { create(:subscription, business: business, plan: plan, status: :active, end_date: 30.days.from_now) }

      it "sends via both email and WhatsApp" do
        result = described_class.call(recipient: customer, template: :rating_request, data: {}, business: business)
        expect(result).to be_success
        expect(result.data[:email]).to be true
        expect(result.data[:whatsapp]).to be true
      end
    end

    context "when a channel raises an error" do
      before do
        allow(business).to receive_message_chain(:current_plan, :whatsapp_notifications?).and_return(false)
        allow(Notifications::EmailChannel).to receive(:deliver).and_raise(StandardError, "SMTP error")
      end

      it "catches the error and returns false for that channel" do
        result = described_class.call(recipient: customer, template: :rating_request, data: {}, business: business)
        expect(result).to be_success
        expect(result.data[:email]).to be false
      end
    end
  end
end
