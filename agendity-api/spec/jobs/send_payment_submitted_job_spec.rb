require "rails_helper"

RSpec.describe SendPaymentSubmittedJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment,
      business: business, employee: employee, customer: customer, service: service)
  end
  let!(:payment) { create(:payment, appointment: appointment, amount: 25_000) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "creates an in-app notification" do
      expect { described_class.perform_now(payment.id) }.to change(Notification, :count).by(1)
    end

    it "creates an activity log" do
      expect { described_class.perform_now(payment.id) }.to change(ActivityLog, :count).by(1)
    end

    it "publishes a NATS event" do
      described_class.perform_now(payment.id)
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(event: "payment_submitted")
      )
    end

    it "sends BusinessMailer.payment_submitted email" do
      mail_double = double(deliver_now: true)
      allow(BusinessMailer).to receive(:payment_submitted).and_return(mail_double)

      described_class.perform_now(payment.id)
      expect(BusinessMailer).to have_received(:payment_submitted).with(payment)
    end

    it "includes correct data in the notification" do
      described_class.perform_now(payment.id)
      notification = Notification.last
      expect(notification.title).to include(customer.name)
      expect(notification.body).to include(service.name)
      expect(notification.notification_type).to eq("payment_submitted")
    end

    it "includes correct data in the NATS event" do
      described_class.perform_now(payment.id)
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(
          business_id: business.id,
          data: hash_including(
            payment_id: payment.id,
            amount: 25_000
          )
        )
      )
    end

    it "raises ActiveRecord::RecordNotFound for non-existent payment" do
      expect { described_class.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
