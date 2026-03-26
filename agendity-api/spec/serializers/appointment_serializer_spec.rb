require "rails_helper"

RSpec.describe AppointmentSerializer do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let(:appointment) do
    create(:appointment, business: business, employee: employee, customer: customer, service: service)
  end

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(appointment)) }

  it "renders expected keys" do
    expect(result).to include("id", "status", "price", "ticket_code", "date", "start_time", "end_time")
  end

  it "formats date as ISO8601" do
    expect(result["date"]).to eq(appointment.appointment_date.iso8601)
  end

  it "formats start_time as HH:MM" do
    expect(result["start_time"]).to match(/\A\d{2}:\d{2}\z/)
  end

  describe "calendar view" do
    subject(:calendar_result) { JSON.parse(described_class.render(appointment, view: :calendar)) }

    it "renders service, customer, and employee names" do
      expect(calendar_result["service"]).to eq({ "name" => service.name })
      expect(calendar_result["customer"]).to eq({ "name" => customer.name })
      expect(calendar_result["employee"]).to eq({ "name" => employee.name })
    end
  end
end
