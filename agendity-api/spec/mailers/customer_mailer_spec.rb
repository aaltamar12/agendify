require "rails_helper"

RSpec.describe CustomerMailer, type: :mailer do
  let(:business) { create(:business) }
  let(:customer) { create(:customer, business: business, email: "cliente@example.com", name: "Carlos") }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
  end

  describe "#rating_request" do
    let(:data) do
      { business_name: business.name, service_name: "Corte", review_url: "https://example.com/review" }
    end
    let(:mail) { described_class.rating_request(customer, data) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("experiencia")
    end
  end

  describe "#cashback_credited" do
    let(:data) do
      { business_name: business.name, service_name: "Corte", cashback_amount: 2_500,
        new_balance: 5_000, booking_url: "https://example.com/book" }
    end
    let(:mail) { described_class.cashback_credited(customer, data) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("créditos")
    end
  end

  describe "#credits_adjusted" do
    let(:data) do
      { business_name: business.name, amount: 1_000, new_balance: 3_000,
        description: "Ajuste manual", booking_url: "https://example.com/book" }
    end
    let(:mail) { described_class.credits_adjusted(customer, data) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("créditos")
    end
  end

  describe "#birthday_greeting" do
    let(:data) do
      { business_name: business.name, discount_pct: 15, code: "BDAY15",
        valid_until: 10.days.from_now.to_date, booking_url: "https://example.com/book" }
    end
    let(:mail) { described_class.birthday_greeting(customer, data) }

    it "sends to the customer email" do
      expect(mail.to).to eq(["cliente@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to include("cumpleanos")
    end
  end
end
