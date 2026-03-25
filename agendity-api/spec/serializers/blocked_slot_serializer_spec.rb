require "rails_helper"

RSpec.describe BlockedSlotSerializer do
  let(:blocked_slot) { create(:blocked_slot) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(blocked_slot)) }

  it "renders expected keys" do
    expect(result).to include("id", "business_id", "date", "reason", "start_time", "end_time")
  end

  it "formats times as HH:MM" do
    expect(result["start_time"]).to match(/\A\d{2}:\d{2}\z/)
  end
end
