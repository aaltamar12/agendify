require "rails_helper"

RSpec.describe NotifyPriceChangeJob do
  let(:plan) { create(:plan, name: "Profesional", price_monthly: 49_900) }
  let(:old_prices) { { "Profesional" => 49_900, "Pro+" => 99_900 } }
  let(:new_prices) { { "Profesional" => 59_900, "Pro+" => 119_900 } }
  let(:effective_date) { "2026-05-01" }

  before do
    allow(JobConfig).to receive(:enabled?).with("NotifyPriceChangeJob").and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    context "when businesses have active subscriptions" do
      let!(:business) { create(:business, status: :active) }
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current + 30)
      end

      it "sends a price change notification email" do
        expect {
          described_class.perform_now(
            old_prices: old_prices,
            new_prices: new_prices,
            effective_date: effective_date
          )
        }.to have_enqueued_mail(BusinessMailer, :price_change_notification)
      end

      it "records success with the count of emails queued" do
        expect(JobConfig).to receive(:record_run!).with(
          "NotifyPriceChangeJob",
          status: "success",
          message: "Emails queued: 1"
        )

        described_class.perform_now(
          old_prices: old_prices,
          new_prices: new_prices,
          effective_date: effective_date
        )
      end
    end

    context "when no businesses have active subscriptions" do
      let!(:business) { create(:business, status: :active) }

      it "does not send any emails" do
        expect {
          described_class.perform_now(
            old_prices: old_prices,
            new_prices: new_prices,
            effective_date: effective_date
          )
        }.not_to have_enqueued_mail(BusinessMailer, :price_change_notification)
      end

      it "records success with zero count" do
        expect(JobConfig).to receive(:record_run!).with(
          "NotifyPriceChangeJob",
          status: "success",
          message: "Emails queued: 0"
        )

        described_class.perform_now(
          old_prices: old_prices,
          new_prices: new_prices,
          effective_date: effective_date
        )
      end
    end

    context "when a subscription is expired" do
      let!(:business) { create(:business, status: :active) }
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :expired,
          end_date: Date.current - 10)
      end

      it "does not send an email to the expired business" do
        expect {
          described_class.perform_now(
            old_prices: old_prices,
            new_prices: new_prices,
            effective_date: effective_date
          )
        }.not_to have_enqueued_mail(BusinessMailer, :price_change_notification)
      end
    end

    context "with multiple businesses" do
      let!(:business_a) { create(:business, status: :active) }
      let!(:business_b) { create(:business, status: :active) }
      let!(:sub_a) do
        create(:subscription, business: business_a, plan: plan, status: :active, end_date: Date.current + 30)
      end
      let!(:sub_b) do
        create(:subscription, business: business_b, plan: plan, status: :active, end_date: Date.current + 15)
      end

      it "sends emails to all businesses with active subscriptions" do
        expect {
          described_class.perform_now(
            old_prices: old_prices,
            new_prices: new_prices,
            effective_date: effective_date
          )
        }.to have_enqueued_mail(BusinessMailer, :price_change_notification).exactly(2).times
      end
    end

    context "when effective_date is a Date object" do
      let!(:business) { create(:business, status: :active) }
      let!(:subscription) do
        create(:subscription, business: business, plan: plan, status: :active, end_date: Date.current + 30)
      end

      it "handles Date objects without error" do
        expect {
          described_class.perform_now(
            old_prices: old_prices,
            new_prices: new_prices,
            effective_date: Date.new(2026, 5, 1)
          )
        }.to have_enqueued_mail(BusinessMailer, :price_change_notification)
      end
    end
  end
end
