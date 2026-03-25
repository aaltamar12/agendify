require "rails_helper"

RSpec.describe CashRegisterCloseSerializer do
  let(:cash_register_close) { create(:cash_register_close) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(cash_register_close)) }

  it "renders expected keys" do
    expect(result).to include("id", "date", "total_revenue", "total_appointments", "status")
  end
end
