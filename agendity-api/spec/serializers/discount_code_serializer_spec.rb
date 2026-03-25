require "rails_helper"

RSpec.describe DiscountCodeSerializer do
  let(:discount_code) { create(:discount_code) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(discount_code)) }

  it "renders expected keys" do
    expect(result).to include("id", "code", "discount_type", "discount_value", "active")
  end
end
