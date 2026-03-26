require "rails_helper"

RSpec.describe Subscriptions::ApprovePaymentService do
  let(:plan)     { create(:plan, name: "Profesional", price_monthly: 49_900) }
  let(:business) { create(:business, status: :active) }
  let(:order) do
    create(:subscription_payment_order,
      business: business,
      plan: plan,
      status: "proof_submitted",
      amount: plan.price_monthly)
  end
  let(:reviewed_by) { "admin@agendity.com" }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
  end

  describe "#call" do
    subject { described_class.call(order: order, reviewed_by: reviewed_by) }

    context "when order is proof_submitted" do
      it "creates a new Subscription" do
        expect { subject }.to change(Subscription, :count).by(1)

        subscription = Subscription.last
        expect(subscription.business).to eq(business)
        expect(subscription.plan).to eq(plan)
        expect(subscription.status).to eq("active")
        expect(subscription.start_date).to eq(Date.current)
        expect(subscription.end_date).to eq(Date.current + 1.month)
      end

      it "marks the order as paid" do
        subject
        order.reload

        expect(order.status).to eq("paid")
        expect(order.reviewed_by).to eq(reviewed_by)
        expect(order.reviewed_at).to be_present
      end

      it "associates the subscription with the order" do
        subject
        order.reload

        expect(order.subscription).to be_present
        expect(order.subscription.plan).to eq(plan)
      end

      it "sends subscription_activated email" do
        expect { subject }.to have_enqueued_mail(BusinessMailer, :subscription_activated)
      end

      it "creates an in-app notification" do
        expect { subject }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.business).to eq(business)
        expect(notification.notification_type).to eq("subscription_expiry")
        expect(notification.title).to include("Suscripcion activada")
      end

      it "publishes a real-time event via NATS" do
        subject

        expect(Realtime::NatsPublisher).to have_received(:publish).with(
          hash_including(
            business_id: business.id,
            event: "subscription_activated"
          )
        )
      end

      it "returns success with order and subscription IDs" do
        result = subject

        expect(result).to be_success
        expect(result.data[:order_id]).to eq(order.id)
        expect(result.data[:subscription_id]).to be_present
      end
    end

    context "when business is suspended" do
      let(:business) { create(:business, status: :suspended) }

      it "reactivates the business" do
        subject
        business.reload

        expect(business.status).to eq("active")
      end
    end

    context "when a pending referral exists" do
      let(:referral_code) { create(:referral_code, commission_percentage: 10.0) }
      let(:business) { create(:business, status: :active, referral_code: referral_code) }
      let!(:referral) do
        create(:referral,
          referral_code: referral_code,
          business: business,
          status: :pending)
      end

      it "activates the referral" do
        subject
        referral.reload

        expect(referral.status).to eq("activated")
        expect(referral.activated_at).to eq(Date.current)
        expect(referral.subscription).to be_present
      end

      it "calculates the commission amount" do
        subject
        referral.reload

        expected_commission = plan.price_monthly * (referral_code.commission_percentage / 100.0)
        expect(referral.commission_amount).to eq(expected_commission)
      end
    end

    context "when an active subscription already exists for the same plan" do
      let!(:existing_subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          start_date: Date.current - 15.days,
          end_date: Date.current + 15.days,
          status: :active)
      end

      it "extends the existing subscription instead of creating a new one" do
        expect { subject }.not_to change(Subscription, :count)

        existing_subscription.reload
        expect(existing_subscription.end_date).to eq(Date.current + 15.days + 1.month)
      end
    end

    context "when order is not in proof_submitted status" do
      let(:order) do
        create(:subscription_payment_order,
          business: business,
          plan: plan,
          status: "paid",
          amount: plan.price_monthly)
      end

      it "returns failure" do
        result = subject

        expect(result).to be_failure
        expect(result.error).to include("not in proof_submitted status")
      end

      it "does not create a subscription" do
        expect { subject }.not_to change(Subscription, :count)
      end
    end
  end
end
