require "rails_helper"

RSpec.describe CreditTransactionSerializer do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business) }
  let(:credit_account) { create(:credit_account, customer: customer, business: business) }
  let(:credit_transaction) { create(:credit_transaction, credit_account: credit_account) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(credit_transaction)) }

  it "renders expected keys" do
    expect(result).to include("id", "amount", "transaction_type", "description", "created_at")
  end
end
