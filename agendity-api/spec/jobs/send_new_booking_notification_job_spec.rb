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

    it "sends AppointmentMailer.new_booking email" do
      mail_double = double(deliver_now: true)
      allow(AppointmentMailer).to receive(:new_booking).and_return(mail_double)

      described_class.perform_now(appointment.id)
      expect(AppointmentMailer).to have_received(:new_booking)
    end

    it "includes correct notification data" do
      described_class.perform_now(appointment.id)
      notification = Notification.last
      expect(notification.title).to include(customer.name)
      expect(notification.notification_type).to eq("new_booking")
      expect(notification.link).to include(appointment.appointment_date.to_s)
    end

    it "includes correct NATS event data" do
      described_class.perform_now(appointment.id)
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(
          business_id: business.id,
          data: hash_including(
            appointment_id: appointment.id,
            customer_name: customer.name,
            service_name: service.name
          )
        )
      )
    end

    it "raises ActiveRecord::RecordNotFound for non-existent appointment" do
      expect { described_class.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
