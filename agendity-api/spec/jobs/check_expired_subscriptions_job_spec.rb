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

      it "extends the end_date by 1 month" do
        old_end_date = subscription.end_date
        described_class.perform_now
        subscription.reload
        expect(subscription.end_date).to eq(old_end_date + 1.month)
      end
    end

    context "when subscription is expired with no paid order" do
      let!(:subscription) do
        create(:subscription, business: business, plan: pro_plan, status: :active,
          end_date: Date.yesterday)
      end

      it "marks pending payment orders as overdue" do
        pending_order = create(:subscription_payment_order,
          subscription: subscription, business: business,
          status: "pending", period_start: Date.current, period_end: Date.current + 1.month)

        described_class.perform_now
        expect(pending_order.reload.status).to eq("overdue")
      end

      it "sends a subscription_expired email" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :subscription_expired)
      end

      it "creates an activity log for the downgrade" do
        described_class.perform_now
        log = ActivityLog.where(action: "subscription_expired").last
        expect(log).to be_present
        expect(log.business).to eq(business)
      end
    end

    context "when subscription is not yet expired" do
      let!(:subscription) do
        create(:subscription, business: business, plan: pro_plan, status: :active,
          end_date: Date.tomorrow)
      end

      it "does not downgrade the subscription" do
        expect { described_class.perform_now }.not_to change(Subscription, :count)
        expect(subscription.reload.status).to eq("active")
      end
    end

    context "when subscription is already expired status" do
      let!(:subscription) do
        create(:subscription, business: business, plan: pro_plan, status: :expired,
          end_date: Date.yesterday)
      end

      it "does not process already-expired subscriptions" do
        expect { described_class.perform_now }.not_to change(Subscription, :count)
      end
    end
  end
end
