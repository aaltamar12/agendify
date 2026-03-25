require "rails_helper"

RSpec.describe SendNewBookingNotificationJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment,
      business: business, employee: employee, customer: customer, service: service)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "creates an in-app notification" do
      expect { described_class.perform_now(appointment.id) }.to change(Notification, :count).by(1)
    end

    it "creates an activity log" do
      expect { described_class.perform_now(appointment.id) }.to change(ActivityLog, :count).by(1)
    end

    it "publishes a NATS event" do
      described_class.perform_now(appointment.id)
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(event: "new_booking")
      )
    end
  end
end
