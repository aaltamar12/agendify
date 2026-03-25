require "rails_helper"

RSpec.describe BusinessSerializer do
  let(:business) { create(:business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(business)) }

  it "renders expected keys" do
    expect(result).to include("id", "name", "slug", "phone", "city", "status", "logo_url", "cover_url")
  end

  it "handles business without subscriptions" do
    expect(result["current_subscription"]).to be_nil
    expect(result["featured"]).to eq(false)
  end
end
