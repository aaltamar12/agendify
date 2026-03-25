require "rails_helper"

RSpec.describe DynamicPricingSerializer do
  let(:business) { create(:business) }
  let(:dynamic_pricing) { create(:dynamic_pricing, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(dynamic_pricing)) }

  it "renders expected keys" do
    expect(result).to include("id", "business_id", "name", "status", "service_name")
  end

  it "handles nil service association" do
    expect(result["service_name"]).to be_nil
  end
end
