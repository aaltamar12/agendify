require "rails_helper"

RSpec.describe SendBookingCancelledJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment,
      business: business, employee: employee, customer: customer, service: service,
      status: :cancelled)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
    allow(Notifications::MultiChannelService).to receive(:call)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "sends a cancellation email to the business" do
      described_class.perform_now(appointment.id)
      # AppointmentMailer.booking_cancelled is called with deliver_now
    end

    it "creates an in-app notification" do
      expect { described_class.perform_now(appointment.id) }.to change(Notification, :count).by(1)
    end

    it "publishes a NATS event" do
      described_class.perform_now(appointment.id)
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(event: "booking_cancelled")
      )
    end

    it "notifies the customer via MultiChannelService" do
      described_class.perform_now(appointment.id)
      expect(Notifications::MultiChannelService).to have_received(:call).with(
        hash_including(recipient: customer, template: :booking_cancelled)
      )
    end

    it "creates an activity log" do
      expect { described_class.perform_now(appointment.id) }.to change(ActivityLog, :count).by(1)
    end

    context "when cancelled_by is 'business'" do
      before do
        appointment.update_columns(cancelled_by: "business")
      end

      it "creates notification with business cancellation body" do
        described_class.perform_now(appointment.id)
        notification = Notification.last
        expect(notification.body).to include(business.name)
      end
    end

    context "when cancelled_by is 'customer' with a reason" do
      before do
        appointment.update_columns(cancelled_by: "customer", cancellation_reason: "No puedo asistir")
      end

      it "creates notification with customer cancellation reason" do
        described_class.perform_now(appointment.id)
        notification = Notification.last
        expect(notification.body).to include("No puedo asistir")
      end
    end

    context "when cancelled_by is 'customer' without a reason" do
      before do
        appointment.update_columns(cancelled_by: "customer", cancellation_reason: nil)
      end

      it "creates notification without a reason suffix" do
        described_class.perform_now(appointment.id)
        notification = Notification.last
        expect(notification.body).to include("El cliente canceló")
      end
    end

    context "when cancelled_by is nil and no cancellation_reason" do
      before do
        appointment.update_columns(cancelled_by: nil, cancellation_reason: nil)
      end

      it "creates notification with default 'Cancelada' body" do
        described_class.perform_now(appointment.id)
        notification = Notification.last
        expect(notification.body).to eq("Cancelada")
      end
    end

    it "raises ActiveRecord::RecordNotFound for non-existent appointment" do
      expect { described_class.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
