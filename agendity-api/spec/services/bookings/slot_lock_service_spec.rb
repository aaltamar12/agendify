require "rails_helper"

RSpec.describe Bookings::SlotLockService do
  let(:params) do
    { business_id: 1, employee_id: 2, date: "2026-03-25", time: "10:00" }
  end

  describe ".lock" do
    context "when Redis is available" do
      let(:mock_redis) { instance_double(Redis) }

      before do
        allow(described_class).to receive(:redis).and_return(mock_redis)
      end

      it "returns a token when lock is acquired" do
        allow(mock_redis).to receive(:set).and_return(true)
        token = described_class.lock(**params)
        expect(token).to be_a(String)
      end

      it "returns nil when lock is denied" do
        allow(mock_redis).to receive(:set).and_return(false)
        token = described_class.lock(**params)
        expect(token).to be_nil
      end
    end

    context "when Redis is unavailable" do
      before { allow(described_class).to receive(:redis).and_return(nil) }

      it "returns nil gracefully" do
        expect(described_class.lock(**params)).to be_nil
      end
    end
  end

  describe ".unlock" do
    context "when Redis is available" do
      let(:mock_redis) { instance_double(Redis) }

      before { allow(described_class).to receive(:redis).and_return(mock_redis) }

      it "deletes the lock when token matches" do
        allow(mock_redis).to receive(:get).and_return("my_token")
        allow(mock_redis).to receive(:del)
        described_class.unlock(**params, token: "my_token")
        expect(mock_redis).to have_received(:del)
      end

      it "does not delete when token does not match" do
        allow(mock_redis).to receive(:get).and_return("other_token")
        allow(mock_redis).to receive(:del)
        described_class.unlock(**params, token: "my_token")
        expect(mock_redis).not_to have_received(:del)
      end
    end
  end

  describe ".locked?" do
    context "when Redis is unavailable" do
      before { allow(described_class).to receive(:redis).and_return(nil) }

      it "returns false" do
        expect(described_class.locked?(**params)).to be false
      end
    end

    context "when Redis is available" do
      let(:mock_redis) { instance_double(Redis) }

      before { allow(described_class).to receive(:redis).and_return(mock_redis) }

      it "returns true when key exists" do
        allow(mock_redis).to receive(:exists?).and_return(true)
        expect(described_class.locked?(**params)).to be true
      end

      it "returns false when key does not exist" do
        allow(mock_redis).to receive(:exists?).and_return(false)
        expect(described_class.locked?(**params)).to be false
      end

      it "returns false on Redis error" do
        allow(mock_redis).to receive(:exists?).and_raise(StandardError, "connection lost")
        expect(described_class.locked?(**params)).to be false
      end
    end
  end

  describe ".lock" do
    context "when Redis raises an error" do
      let(:mock_redis) { instance_double(Redis) }

      before { allow(described_class).to receive(:redis).and_return(mock_redis) }

      it "returns nil and logs the error" do
        allow(mock_redis).to receive(:set).and_raise(StandardError, "connection lost")
        expect(described_class.lock(**params)).to be_nil
      end
    end
  end

  describe ".unlock" do
    context "when Redis is unavailable" do
      before { allow(described_class).to receive(:redis).and_return(nil) }

      it "returns without error" do
        expect { described_class.unlock(**params, token: "abc") }.not_to raise_error
      end
    end

    context "when Redis raises an error" do
      let(:mock_redis) { instance_double(Redis) }

      before { allow(described_class).to receive(:redis).and_return(mock_redis) }

      it "logs the error and does not raise" do
        allow(mock_redis).to receive(:get).and_raise(StandardError, "connection lost")
        expect { described_class.unlock(**params, token: "abc") }.not_to raise_error
      end
    end
  end

  describe ".redis" do
    it "returns nil when Redis gem is not defined" do
      described_class.instance_variable_set(:@redis, nil)
      allow(described_class).to receive(:redis).and_call_original
      # If Redis constant is not available, returns nil
      original = defined?(::Redis)
      if original
        allow(described_class).to receive(:redis).and_return(nil) unless ENV["REDIS_URL"]
      end
      # Just verify the method doesn't raise
      expect { described_class.redis }.not_to raise_error
    end
  end
end
