require "rails_helper"

RSpec.describe Realtime::NatsPublisher do
  after { described_class.reset! }

  describe ".client" do
    it "returns nil when connection fails" do
      allow(described_class).to receive(:require).with("nats/client").and_raise(StandardError, "no nats")
      described_class.reset!
      expect(described_class.client).to be_nil
    end
  end

  describe ".publish" do
    context "when client is nil" do
      before { allow(described_class).to receive(:client).and_return(nil) }

      it "returns without publishing" do
        expect { described_class.publish(business_id: 1, event: "test", data: {}) }.not_to raise_error
      end
    end

    context "when client is available" do
      let(:mock_client) { double("NatsClient") }

      before { allow(described_class).to receive(:client).and_return(mock_client) }

      it "publishes a JSON payload to the correct subject" do
        expect(mock_client).to receive(:publish).with("business.42.appointment_created", anything)
        described_class.publish(business_id: 42, event: "appointment_created", data: { id: 1 })
      end

      it "logs the published event" do
        allow(mock_client).to receive(:publish)
        expect(Rails.logger).to receive(:info).with(/Published business\.42\.test/)
        described_class.publish(business_id: 42, event: "test", data: {})
      end
    end

    context "when publish raises an error" do
      let(:mock_client) { double("NatsClient") }

      before { allow(described_class).to receive(:client).and_return(mock_client) }

      it "logs the error and does not raise" do
        allow(mock_client).to receive(:publish).and_raise(StandardError, "publish fail")
        expect(Rails.logger).to receive(:error).with(/Publish failed/)
        expect { described_class.publish(business_id: 1, event: "test") }.not_to raise_error
      end
    end
  end

  describe ".reset!" do
    it "sets client to nil" do
      allow(described_class).to receive(:client).and_return(nil)
      described_class.reset!
      # After reset, instance variable should be nil
      expect(described_class.instance_variable_get(:@client)).to be_nil
    end

    it "closes existing client and ignores errors" do
      mock_client = double("NatsClient")
      described_class.instance_variable_set(:@client, mock_client)
      allow(mock_client).to receive(:close).and_raise(StandardError, "close fail")

      expect { described_class.reset! }.not_to raise_error
      expect(described_class.instance_variable_get(:@client)).to be_nil
    end
  end
end
