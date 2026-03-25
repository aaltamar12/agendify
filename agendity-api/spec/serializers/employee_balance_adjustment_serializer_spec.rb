require "rails_helper"

RSpec.describe EmployeeBalanceAdjustmentSerializer do
  let(:adjustment) { create(:employee_balance_adjustment) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(adjustment)) }

  it "renders expected keys" do
    expect(result).to include("id", "amount", "balance_before", "balance_after", "reason", "employee_name")
  end
end
