require "rails_helper"

RSpec.describe CustomerSerializer do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(customer)) }

  it "renders expected keys" do
    expect(result).to include("id", "name", "phone", "email", "total_visits", "last_visit_at")
  end

  it "handles customer with no appointments" do
    expect(result["total_visits"]).to eq(0)
    expect(result["last_visit_at"]).to be_nil
  end
end
