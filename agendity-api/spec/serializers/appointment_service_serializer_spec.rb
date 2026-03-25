require "rails_helper"

RSpec.describe AppointmentServiceSerializer do
  let(:business) { create(:business) }
  let(:service)  { create(:service, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) do
    # Build an AppointmentService manually since it needs an appointment
    employee = create(:employee, business: business)
    customer = create(:customer, business: business)
    appointment = create(:appointment, business: business, employee: employee, customer: customer, service: service)
    appt_service = AppointmentService.create!(appointment: appointment, service: service, price: 25_000, duration_minutes: 30)
    JSON.parse(described_class.render(appt_service))
  end

  it "renders expected keys" do
    expect(result).to include("id", "service_id", "price", "duration_minutes", "service_name")
  end
end
