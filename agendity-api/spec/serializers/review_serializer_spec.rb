require "rails_helper"

RSpec.describe ReviewSerializer do
  let(:review) { create(:review) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(review)) }

  it "renders expected keys" do
    expect(result).to include("id", "rating", "comment", "customer_id", "business_id")
  end
end
