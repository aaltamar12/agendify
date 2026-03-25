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
end
