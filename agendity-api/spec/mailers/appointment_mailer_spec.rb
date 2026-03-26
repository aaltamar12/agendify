require "rails_helper"

RSpec.describe AppointmentMailer, type: :mailer do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business, email: "cliente@example.com") }
  let(:service)  { create(:service, business: business) }
  let(:appointment) do
    create(:appointment, :confirmed,
      business: business, employee: employee, customer: customer, service: service)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
  end

  describe "#booking_confirmed" do
    let(:mail) { described_class.booking_confirmed(appointment) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("confirmada")
      expect(mail.subject).to include(business.name)
    end
  end

  describe "#booking_cancelled" do
    let(:mail) { described_class.booking_cancelled(appointment) }

    it "sends to the business owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("cancelada")
    end
  end

  describe "#booking_cancelled_to_customer" do
    let(:mail) { described_class.booking_cancelled_to_customer(appointment) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("cancelada")
    end
  end

  describe "#reminder" do
    let(:mail) { described_class.reminder(appointment) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("Recordatorio")
    end
  end

  describe "#payment_reminder" do
    let(:mail) { described_class.payment_reminder(appointment) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("pendiente de pago")
    end
  end

  describe "#payment_rejected" do
    let(:mail) { described_class.payment_rejected(appointment, "Imagen borrosa") }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("rechazado")
    end
  end

  describe "#new_booking" do
    let(:mail) { described_class.new_booking(appointment) }

    it "sends to the business owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("Nueva reserva")
      expect(mail.subject).to include(customer.name)
    end
  end

  describe "#reminder_30min" do
    let(:mail) { described_class.reminder_30min(appointment) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("30 minutos")
    end
  end

  describe "mailers with customer without email" do
    let(:no_email_customer) { create(:customer, business: business, email: nil) }
    let(:no_email_appointment) do
      create(:appointment, :confirmed,
        business: business, employee: employee, customer: no_email_customer, service: service)
    end

    it "booking_confirmed returns nil for customer without email" do
      mail = described_class.booking_confirmed(no_email_appointment)
      expect(mail.to).to be_nil
    end

    it "payment_reminder returns nil for customer without email" do
      mail = described_class.payment_reminder(no_email_appointment)
      expect(mail.to).to be_nil
    end

    it "payment_rejected returns nil for customer without email" do
      mail = described_class.payment_rejected(no_email_appointment, "reason")
      expect(mail.to).to be_nil
    end

    it "reminder_30min returns nil for customer without email" do
      mail = described_class.reminder_30min(no_email_appointment)
      expect(mail.to).to be_nil
    end

    it "reminder returns nil for customer without email" do
      mail = described_class.reminder(no_email_appointment)
      expect(mail.to).to be_nil
    end
  end
end
