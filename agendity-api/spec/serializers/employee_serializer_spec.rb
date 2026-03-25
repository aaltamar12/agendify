require "rails_helper"

RSpec.describe EmployeeSerializer do
  let(:business)  { create(:business) }
  let(:employee)  { create(:employee, business: business) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Employees::ScoreService).to receive(:call)
      .and_return(ServiceResult.new(success: true, data: { overall: 4.5 }))
  end

  subject(:result) { JSON.parse(described_class.render(employee)) }

  it "renders expected keys" do
    expect(result).to include("id", "name", "phone", "email", "active", "avatar_url", "score", "service_ids")
  end

  it "returns score from ScoreService" do
    expect(result["score"]).to eq(4.5)
  end

  it "handles employee with no services" do
    expect(result["service_ids"]).to eq([])
  end
end
