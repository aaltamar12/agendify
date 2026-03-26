require "rails_helper"

RSpec.describe SendBookingConfirmedJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment, :confirmed,
      business: business, employee: employee, customer: customer, service: service)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    allow(Notifications::MultiChannelService).to receive(:call)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "notifies the customer via MultiChannelService" do
      described_class.perform_now(appointment.id)
      expect(Notifications::MultiChannelService).to have_received(:call).with(
        hash_including(recipient: customer, template: :booking_confirmed)
      )
    end

    it "creates an activity log" do
      expect { described_class.perform_now(appointment.id) }.to change(ActivityLog, :count).by(1)
    end

    it "publishes a NATS event" do
      described_class.perform_now(appointment.id)
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(event: "booking_confirmed")
      )
    end

    it "raises ActiveRecord::RecordNotFound for non-existent appointment" do
      expect { described_class.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "includes correct data in the MultiChannelService call" do
      described_class.perform_now(appointment.id)
      expect(Notifications::MultiChannelService).to have_received(:call).with(
        hash_including(
          business: business,
          data: hash_including(
            business_name: business.name,
            service_name: service.name,
            employee_name: employee.name
          )
        )
      )
    end

    it "includes correct data in the NATS event" do
      described_class.perform_now(appointment.id)
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(
          business_id: business.id,
          event: "booking_confirmed",
          data: hash_including(
            appointment_id: appointment.id,
            customer_name: customer.name
          )
        )
      )
    end
  end
end
