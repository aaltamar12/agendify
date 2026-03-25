require "rails_helper"

RSpec.describe CreditAccountSerializer do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business) }
  let(:credit_account) { create(:credit_account, customer: customer, business: business, balance: 5_000) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(credit_account)) }

  it "renders expected keys" do
    expect(result).to include("id", "customer_id", "business_id", "balance", "customer_name", "customer_email")
  end

  it "includes customer name" do
    expect(result["customer_name"]).to eq(customer.name)
  end
end
