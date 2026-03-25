require "rails_helper"

RSpec.describe ServiceSerializer do
  let(:service) { create(:service) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(service)) }

  it "renders expected keys" do
    expect(result).to include("id", "name", "price", "duration_minutes", "active", "category")
  end
end
