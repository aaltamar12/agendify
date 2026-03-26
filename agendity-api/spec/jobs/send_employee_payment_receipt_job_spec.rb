# frozen_string_literal: true

require "rails_helper"

RSpec.describe SendEmployeePaymentReceiptJob, type: :job do
  let(:business) { create(:business) }
  let(:close) { create(:cash_register_close, business: business, closed_by_user: business.owner, status: :closed) }

  let(:employee_with_email) { create(:employee, business: business, email: "barber@example.com") }
  let(:employee_without_email) { create(:employee, business: business, email: nil) }

  let!(:payment_with_email) do
    create(:employee_payment, cash_register_close: close, employee: employee_with_email)
  end
  let!(:payment_without_email) do
    create(:employee_payment, cash_register_close: close, employee: employee_without_email)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "sends a payment receipt email for employees with email" do
      expect {
        described_class.perform_now(close.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "does not send email to employees without email" do
      described_class.perform_now(close.id)
      recipients = ActionMailer::Base.deliveries.map(&:to).flatten
      expect(recipients).to include("barber@example.com")
      expect(recipients).not_to include(nil)
    end

    it "sends emails with correct subject" do
      described_class.perform_now(close.id)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to include("Recibo de pago")
      expect(mail.subject).to include(business.name)
    end
  end
end
