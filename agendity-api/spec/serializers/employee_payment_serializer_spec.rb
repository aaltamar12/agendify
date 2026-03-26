require "rails_helper"

RSpec.describe EmployeePaymentSerializer do
  let(:employee_payment) { create(:employee_payment) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(employee_payment)) }

  it "renders expected keys" do
    expect(result).to include("id", "employee_id", "total_earned", "commission_amount", "remaining_debt", "employee_name")
  end

  it "calculates remaining_debt" do
    expect(result["remaining_debt"]).to eq(0.0)
  end

  it "returns proof_url when proof is attached" do
    file = fixture_file_upload(Rails.root.join("spec/fixtures/files/proof.png"), "image/png")
    employee_payment.proof.attach(file)
    result = JSON.parse(described_class.render(employee_payment))
    expect(result["proof_url"]).to include("rails/active_storage")
  end

  it "returns nil proof_url when no proof attached" do
    expect(result["proof_url"]).to be_nil
  end
end
