require "rails_helper"

RSpec.describe SubscriptionSerializer do
  let(:plan) { create(:plan) }
  let(:subscription) { create(:subscription, plan: plan) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(subscription)) }

  it "renders expected keys" do
    expect(result).to include("id", "business_id", "plan_id", "start_date", "end_date", "status", "plan")
  end

  it "includes plan association" do
    expect(result["plan"]).to include("id", "name", "price_monthly")
  end
end
