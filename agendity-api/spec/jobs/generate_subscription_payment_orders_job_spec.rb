require "rails_helper"

RSpec.describe GenerateSubscriptionPaymentOrdersJob, type: :job do
  let(:business) { create(:business) }
  let(:plan)     { create(:plan, price_monthly: 49_900) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    context "when subscription ends within 7 days" do
      let!(:subscription) do
        create(:subscription, business: business, plan: plan, status: :active,
          end_date: 3.days.from_now.to_date)
      end

      it "creates a payment order" do
        expect { described_class.perform_now }.to change(SubscriptionPaymentOrder, :count).by(1)

        order = SubscriptionPaymentOrder.last
        expect(order.business).to eq(business)
        expect(order.amount).to eq(49_900)
        expect(order.status).to eq("pending")
      end

      it "creates an in-app notification" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)
      end

      it "creates an activity log" do
        expect { described_class.perform_now }.to change(ActivityLog, :count).by(1)
      end
    end

    context "when a pending order already exists for the next period" do
      let!(:subscription) do
        create(:subscription, business: business, plan: plan, status: :active,
          end_date: 3.days.from_now.to_date)
      end

      before do
        create(:subscription_payment_order,
          subscription: subscription, business: business,
          period_start: subscription.end_date + 1.day, status: "pending")
      end

      it "does not create a duplicate order" do
        expect { described_class.perform_now }.not_to change(SubscriptionPaymentOrder, :count)
      end
    end

    context "when subscription ends in more than 7 days" do
      let!(:subscription) do
        create(:subscription, business: business, plan: plan, status: :active,
          end_date: 15.days.from_now.to_date)
      end

      it "does not create a payment order" do
        expect { described_class.perform_now }.not_to change(SubscriptionPaymentOrder, :count)
      end
    end

    context "when a paid order already exists for the next period" do
      let!(:subscription) do
        create(:subscription, business: business, plan: plan, status: :active,
          end_date: 3.days.from_now.to_date)
      end

      before do
        create(:subscription_payment_order,
          subscription: subscription, business: business,
          period_start: subscription.end_date + 1.day, status: "paid")
      end

      it "does not create a duplicate order" do
        expect { described_class.perform_now }.not_to change(SubscriptionPaymentOrder, :count)
      end
    end

    context "when subscription is not active (expired)" do
      let!(:subscription) do
        create(:subscription, business: business, plan: plan, status: :expired,
          end_date: 3.days.from_now.to_date)
      end

      it "does not create a payment order" do
        expect { described_class.perform_now }.not_to change(SubscriptionPaymentOrder, :count)
      end
    end

    context "payment order attributes" do
      let!(:subscription) do
        create(:subscription, business: business, plan: plan, status: :active,
          end_date: 3.days.from_now.to_date)
      end

      it "sets correct period_start and period_end" do
        described_class.perform_now
        order = SubscriptionPaymentOrder.last
        expect(order.period_start).to eq(subscription.end_date + 1.day)
        expect(order.period_end).to eq(subscription.end_date + 1.day + 1.month - 1.day)
        expect(order.due_date).to eq(subscription.end_date)
      end

      it "creates notification with renewal information" do
        described_class.perform_now
        notification = Notification.last
        expect(notification.title).to eq("Renovación de suscripción")
        expect(notification.notification_type).to eq("reminder")
      end

      it "creates activity log with payment order details" do
        described_class.perform_now
        log = ActivityLog.last
        expect(log.action).to eq("payment_order_created")
        expect(log.description).to include("49900")
      end
    end
  end
end
