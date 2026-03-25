require "rails_helper"

RSpec.describe PlanSerializer do
  let(:plan) { create(:plan) }

  subject(:result) { JSON.parse(described_class.render(plan)) }

  it "renders expected keys" do
    expect(result).to include("id", "name", "price_monthly", "max_employees", "ai_features")
  end
end
