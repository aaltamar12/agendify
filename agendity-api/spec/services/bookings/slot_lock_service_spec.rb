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
  end
end
