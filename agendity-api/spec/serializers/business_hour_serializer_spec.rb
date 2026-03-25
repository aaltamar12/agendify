require "rails_helper"

RSpec.describe BusinessHourSerializer do
  let(:business_hour) { create(:business_hour) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(business_hour)) }

  it "renders expected keys" do
    expect(result).to include("id", "business_id", "day_of_week", "closed", "open_time", "close_time")
  end

  it "formats times as HH:MM" do
    expect(result["open_time"]).to match(/\A\d{2}:\d{2}\z/)
  end
end
