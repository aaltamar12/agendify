require "rails_helper"

RSpec.describe BusinessMailer, type: :mailer do
  let(:business) { create(:business, trial_ends_at: 14.days.from_now) }
  let(:plan)     { create(:plan, name: "Profesional", price_monthly: 49_900) }
  let(:subscription) { create(:subscription, business: business, plan: plan, end_date: 30.days.from_now) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  describe "#welcome" do
    let(:mail) { described_class.welcome(business) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("Bienvenido a Agendity")
    end
  end

  describe "#payment_submitted" do
    let(:customer) { create(:customer, business: business) }
    let(:service)  { create(:service, business: business) }
    let(:employee) { create(:employee, business: business) }
    let(:appointment) do
      create(:appointment, business: business, customer: customer,
             service: service, employee: employee)
    end

    context "without additional_info" do
      let(:payment) { create(:payment, appointment: appointment, amount: 25_000) }
      let(:mail)    { described_class.payment_submitted(payment) }

      it "sends to the business owner" do
        expect(mail.to).to eq([business.owner.email])
      end

      it "does not include additional info section" do
        expect(mail.body.encoded).not_to include("adicional")
      end
    end

    context "with additional_info" do
      let(:payment) do
        create(:payment, appointment: appointment, amount: 25_000,
               additional_info: "Nombre: Juan, Dirección: Calle 50")
      end
      let(:mail) { described_class.payment_submitted(payment) }

      it "includes additional_info in the email body" do
        expect(mail.body.encoded).to include("Nombre: Juan")
        expect(mail.body.encoded).to include("Calle 50")
      end
    end
  end

  describe "#trial_expiry_alert" do
    let(:mail) { described_class.trial_expiry_alert(business, 1) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject for stage 1" do
      expect(mail.subject).to include("periodo de prueba")
    end
  end

  describe "#trial_ended_thank_you" do
    before { create(:plan, name: "Básico", price_monthly: 0) }

    let(:mail) { described_class.trial_ended_thank_you(business) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("Gracias por probar Agendity")
    end
  end

  describe "#subscription_activated" do
    let(:mail) { described_class.subscription_activated(business, subscription) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("Suscripcion activada")
    end
  end

  describe "#subscription_expiry_alert" do
    let(:mail) { described_class.subscription_expiry_alert(business, subscription, 1) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject for stage 1" do
      expect(mail.subject).to include("vence en 5 días")
    end
  end

  describe "#subscription_renewed" do
    let(:mail) { described_class.subscription_renewed(business, subscription) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("renovada")
    end
  end

  describe "#subscription_payment_reminder" do
    let(:order) do
      create(:subscription_payment_order,
        subscription: subscription, business: business, plan: plan,
        due_date: 3.days.from_now.to_date)
    end

    let(:mail) { described_class.subscription_payment_reminder(order) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("Recordatorio")
    end
  end

  describe "#subscription_expired" do
    let(:mail) { described_class.subscription_expired(business, subscription) }

    it "sends to the owner email" do
      expect(mail.to).to eq([business.owner.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("expirado")
    end
  end

  describe "#subscription_expiry_alert stage 2" do
    let(:mail) { described_class.subscription_expiry_alert(business, subscription, 2) }

    it "has the correct subject for stage 2" do
      expect(mail.subject).to include("vence hoy")
    end
  end

  describe "#subscription_expiry_alert stage 3" do
    let(:mail) { described_class.subscription_expiry_alert(business, subscription, 3) }

    it "has the correct subject for stage 3" do
      expect(mail.subject).to include("suspendida")
    end
  end

  describe "#trial_expiry_alert stage 3" do
    let(:mail) { described_class.trial_expiry_alert(business, 3) }

    it "has the correct subject for stage 3" do
      expect(mail.subject).to include("suspendida")
    end
  end
end
