require "rails_helper"

RSpec.describe SendReminderJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment, :confirmed,
      business: business, employee: employee, customer: customer, service: service,
      appointment_date: Date.tomorrow)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    allow(Notifications::MultiChannelService).to receive(:call)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "sends a reminder via MultiChannelService" do
      described_class.perform_now(appointment.id)
      expect(Notifications::MultiChannelService).to have_received(:call).with(
        hash_including(recipient: customer, template: :appointment_reminder)
      )
    end

    it "creates an activity log" do
      expect { described_class.perform_now(appointment.id) }.to change(ActivityLog, :count).by(1)
    end

    context "when appointment is not confirmed" do
      before { appointment.update_column(:status, :cancelled) }

      it "does not send a reminder" do
        described_class.perform_now(appointment.id)
        expect(Notifications::MultiChannelService).not_to have_received(:call)
      end
    end
  end
end
