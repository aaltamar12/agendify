require "rails_helper"

RSpec.describe CheckExpiredSubscriptionsJob, type: :job do
  let(:business) { create(:business) }
  let!(:basic_plan) { create(:plan, name: "Básico", price_monthly: 0) }
  let(:pro_plan) { create(:plan, name: "Profesional", price_monthly: 49_900) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  describe "#perform" do
    context "when subscription is expired with no paid order" do
      let!(:subscription) do
        create(:subscription, business: business, plan: pro_plan, status: :active,
          end_date: Date.yesterday)
      end

      it "marks the subscription as expired and creates a Básico subscription" do
        expect { described_class.perform_now }.to change(Subscription, :count).by(1)

        subscription.reload
        expect(subscription.status).to eq("expired")

        new_sub = Subscription.last
        expect(new_sub.plan.name).to eq("Básico")
        expect(new_sub.business).to eq(business)
      end

      it "creates an in-app notification" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)
      end
    end

    context "when subscription is expired with a paid order for next period" do
      let!(:subscription) do
        create(:subscription, business: business, plan: pro_plan, status: :active,
          end_date: Date.yesterday)
      end

      let!(:paid_order) do
        create(:subscription_payment_order,
          subscription: subscription, business: business, plan: pro_plan,
          status: "paid", period_start: Date.current, period_end: Date.current + 1.month)
      end

      it "extends the subscription instead of downgrading" do
        described_class.perform_now
        subscription.reload
        expect(subscription.status).to eq("active")
      end
    end
  end
end
