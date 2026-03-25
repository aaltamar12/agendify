require "rails_helper"

RSpec.describe PaymentSerializer do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let(:appointment) do
    create(:appointment, business: business, employee: employee, customer: customer, service: service)
  end
  let(:payment) { create(:payment, appointment: appointment) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(payment)) }

  it "renders expected keys" do
    expect(result).to include("id", "appointment_id", "payment_method", "amount", "status", "proof_url")
  end
end
