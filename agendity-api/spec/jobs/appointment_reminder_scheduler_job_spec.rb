require "rails_helper"

RSpec.describe AppointmentReminderSchedulerJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    context "when there are confirmed appointments tomorrow" do
      let!(:appointment) do
        create(:appointment, :confirmed,
          business: business, employee: employee, customer: customer, service: service,
          appointment_date: Date.tomorrow)
      end

      it "enqueues a SendReminderJob for each appointment" do
        expect(SendReminderJob).to receive(:perform_later).with(appointment.id)
        described_class.perform_now
      end
    end

    context "when there are no confirmed appointments tomorrow" do
      let!(:appointment) do
        create(:appointment,
          business: business, employee: employee, customer: customer, service: service,
          appointment_date: Date.tomorrow, status: :pending_payment)
      end

      it "does not enqueue any jobs" do
        expect(SendReminderJob).not_to receive(:perform_later)
        described_class.perform_now
      end
    end
  end
end
