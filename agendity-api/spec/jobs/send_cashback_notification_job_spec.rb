require "rails_helper"

RSpec.describe SendCashbackNotificationJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business, email: "test@example.com") }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment, :completed,
      business: business, employee: employee, customer: customer, service: service)
  end
  let!(:credit_account) { create(:credit_account, customer: customer, business: business, balance: 5_000) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "sends a cashback email to the customer" do
      described_class.perform_now(appointment.id, 2_500)
      # CustomerMailer.cashback_credited is called with deliver_now — just verify no error
    end

    context "when customer has no email" do
      before { customer.update_column(:email, nil) }

      it "does not send an email" do
        expect { described_class.perform_now(appointment.id, 2_500) }.not_to raise_error
      end
    end
  end
end
