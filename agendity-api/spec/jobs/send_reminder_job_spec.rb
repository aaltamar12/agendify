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
    allow(Notifications::WhatsappChannel).to receive(:deliver)
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

      it "does not create an activity log" do
        expect { described_class.perform_now(appointment.id) }.not_to change(ActivityLog, :count)
      end
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

    it "creates an activity log with reminder_sent action" do
      described_class.perform_now(appointment.id)
      log = ActivityLog.last
      expect(log.action).to eq("reminder_sent")
      expect(log.description).to include(customer.name)
    end
  end
end
