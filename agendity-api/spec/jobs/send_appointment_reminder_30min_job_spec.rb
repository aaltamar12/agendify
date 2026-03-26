require "rails_helper"

RSpec.describe SendAppointmentReminder30minJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment, :confirmed,
      business: business, employee: employee, customer: customer, service: service,
      appointment_date: Date.today, start_time: 30.minutes.from_now.strftime("%H:%M"))
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    allow(Notifications::MultiChannelService).to receive(:call)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "sends a 30-min reminder via MultiChannelService for confirmed appointment" do
      described_class.perform_now(appointment.id)
      expect(Notifications::MultiChannelService).to have_received(:call).with(
        hash_including(recipient: customer, template: :appointment_reminder_30min)
      )
    end

    it "sends a 30-min reminder for checked_in appointment" do
      appointment.update_column(:status, :checked_in)
      described_class.perform_now(appointment.id)
      expect(Notifications::MultiChannelService).to have_received(:call).with(
        hash_including(recipient: customer, template: :appointment_reminder_30min)
      )
    end

    it "creates an activity log" do
      expect { described_class.perform_now(appointment.id) }.to change(ActivityLog, :count).by(1)
    end

    it "logs with action reminder_30min_sent" do
      described_class.perform_now(appointment.id)
      log = ActivityLog.last
      expect(log.action).to eq("reminder_30min_sent")
    end

    context "when appointment is cancelled" do
      before { appointment.update_column(:status, :cancelled) }

      it "does not send a reminder" do
        described_class.perform_now(appointment.id)
        expect(Notifications::MultiChannelService).not_to have_received(:call)
      end

      it "does not create an activity log" do
        expect { described_class.perform_now(appointment.id) }.not_to change(ActivityLog, :count)
      end
    end

    context "when appointment does not exist" do
      it "does not raise an error" do
        expect { described_class.perform_now(0) }.not_to raise_error
      end
    end
  end
end
