# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmployeeMailer, type: :mailer do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:invitation) { create(:employee_invitation, employee: employee, business: business) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
  end

  describe "#invitation" do
    let(:mail) { described_class.invitation(invitation) }

    it "sends to the invitation email" do
      expect(mail.to).to eq([invitation.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("invitaron")
      expect(mail.subject).to include(business.name)
    end
  end

  describe "#payment_receipt" do
    let(:close) { create(:cash_register_close, business: business, closed_by_user: business.owner, status: :closed) }
    let(:payment) do
      create(:employee_payment,
        cash_register_close: close,
        employee: employee,
        appointments_count: 5,
        total_earned: 100_000,
        commission_pct: 40,
        commission_amount: 40_000,
        total_owed: 40_000,
        amount_paid: 40_000
      )
    end

    let(:mail) { described_class.payment_receipt(payment) }

    it "sends to the employee email" do
      expect(mail.to).to eq([employee.email])
    end

    it "has the correct subject with business name and date" do
      expect(mail.subject).to include("Recibo de pago")
      expect(mail.subject).to include(business.name)
      expect(mail.subject).to include(close.date.strftime("%d/%m/%Y"))
    end

    it "includes employee name in the body" do
      expect(mail.body.encoded).to include(employee.name)
    end

    it "includes payment amounts in the body" do
      expect(mail.body.encoded).to include("100")
      expect(mail.body.encoded).to include("40")
    end
  end
end
