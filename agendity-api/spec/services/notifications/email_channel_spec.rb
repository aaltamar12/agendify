require "rails_helper"

RSpec.describe Notifications::EmailChannel do
  let(:customer) { create(:customer, email: "test@example.com") }
  let(:appointment) { create(:appointment) }

  describe ".deliver" do
    context "when recipient has no email" do
      let(:no_email_customer) { build(:customer, email: nil) }

      it "returns false" do
        expect(described_class.deliver(recipient: no_email_customer, template: :rating_request, data: {})).to be false
      end
    end

    context "with :rating_request template" do
      let(:mailer) { double(deliver_now: true) }

      it "sends rating request email" do
        allow(CustomerMailer).to receive(:rating_request).and_return(mailer)
        result = described_class.deliver(recipient: customer, template: :rating_request, data: { business_name: "Test" })
        expect(result).to be true
        expect(CustomerMailer).to have_received(:rating_request).with(customer, { business_name: "Test" })
      end
    end

    context "with :booking_confirmed template" do
      let(:mailer) { double(deliver_now: true) }

      it "sends booking confirmed email" do
        allow(AppointmentMailer).to receive(:booking_confirmed).and_return(mailer)
        result = described_class.deliver(recipient: customer, template: :booking_confirmed, data: { appointment: appointment })
        expect(result).to be true
      end
    end

    context "with unknown template" do
      it "returns false" do
        result = described_class.deliver(recipient: customer, template: :unknown_template, data: {})
        expect(result).to be false
      end
    end
  end
end
