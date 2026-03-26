require "rails_helper"

RSpec.describe Notifications::WhatsappChannel do
  let(:customer) { build(:customer, phone: "3001234567") }

  describe ".deliver" do
    context "when WhatsApp is not configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("WHATSAPP_API_TOKEN").and_return(nil)
        allow(ENV).to receive(:[]).with("WHATSAPP_PHONE_NUMBER_ID").and_return(nil)
        allow(ENV).to receive(:fetch).and_call_original
      end

      it "returns false" do
        result = described_class.deliver(recipient: customer, template: :booking_confirmed, data: {})
        expect(result).to be false
      end
    end

    context "when WhatsApp is configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("WHATSAPP_API_TOKEN").and_return("test_token")
        allow(ENV).to receive(:[]).with("WHATSAPP_PHONE_NUMBER_ID").and_return("12345")
        allow(ENV).to receive(:fetch).and_call_original
      end

      it "returns false (stub implementation)" do
        # Currently the WhatsApp channel is a stub that logs but returns false
        result = described_class.deliver(recipient: customer, template: :booking_confirmed, data: {})
        expect(result).to be false
      end
    end
  end
end
