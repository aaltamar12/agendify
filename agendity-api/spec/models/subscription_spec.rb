require "rails_helper"

RSpec.describe Subscription, type: :model do
  let(:business) { create(:business) }
  let(:plan)     { create(:plan) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:plan) }
    it { is_expected.to have_many(:subscription_payment_orders).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, expired: 1, cancelled: 2) }
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_sub)    { create(:subscription, business: business, plan: plan, status: :active) }
      let!(:expired_sub)   { create(:subscription, business: create(:business), plan: plan, status: :expired) }

      it "returns only active subscriptions" do
        expect(described_class.active).to include(active_sub)
        expect(described_class.active).not_to include(expired_sub)
      end
    end

    describe ".current" do
      let!(:current_sub) { create(:subscription, business: business, plan: plan, status: :active, end_date: 10.days.from_now) }
      let!(:past_sub) do
        sub = create(:subscription, business: create(:business), plan: plan, status: :active)
        sub.update_column(:end_date, 1.day.ago)
        sub
      end

      it "returns only active subs with future end_date" do
        expect(described_class.current).to include(current_sub)
        expect(described_class.current).not_to include(past_sub)
      end
    end
  end

  describe "#process_renewal!" do
    let(:subscription) { create(:subscription, business: business, plan: plan, status: :active, end_date: Date.current) }

    before do
      allow(BusinessMailer).to receive_message_chain(:subscription_renewed, :deliver_later)
      allow(Realtime::NatsPublisher).to receive(:publish)
      allow(Notifications::WhatsAppChannel).to receive(:deliver)
    end

    it "extends the end_date by 1 month" do
      subscription.process_renewal!
      expect(subscription.reload.end_date).to eq(Date.current + 1.month)
    end

    it "sets status to active and resets expiry_alert_stage" do
      subscription.update_column(:expiry_alert_stage, 3)
      subscription.process_renewal!
      subscription.reload
      expect(subscription.status).to eq("active")
      expect(subscription.expiry_alert_stage).to eq(0)
    end

    it "creates an in-app notification" do
      expect {
        subscription.process_renewal!
      }.to change(Notification, :count).by(1)
    end

    it "accepts a custom new_end_date" do
      custom_date = Date.current + 3.months
      subscription.process_renewal!(new_end_date: custom_date)
      expect(subscription.reload.end_date).to eq(custom_date)
    end

    it "reactivates a suspended business" do
      business.suspended!
      subscription.process_renewal!
      expect(business.reload.status).to eq("active")
    end

    it "publishes a real-time event via NATS" do
      subscription.process_renewal!
      expect(Realtime::NatsPublisher).to have_received(:publish).with(
        hash_including(event: "subscription_expiry")
      )
    end

    it "creates an activity log" do
      expect { subscription.process_renewal! }.to change(ActivityLog, :count).by(1)
      log = ActivityLog.last
      expect(log.action).to eq("subscription_renewed")
    end

    it "sends WhatsApp when plan has whatsapp_notifications and owner has phone" do
      plan.update!(whatsapp_notifications: true)
      # Ensure the subscription is current so current_plan returns this plan
      subscription.update!(end_date: Date.current + 1.month, status: :active)
      # Ensure owner has a phone number
      business.owner.update!(phone: "3001234567") unless business.owner.phone.present?

      subscription.process_renewal!
      expect(Notifications::WhatsAppChannel).to have_received(:deliver).with(
        hash_including(template: :subscription_renewed)
      )
    end
  end

  describe "scopes" do
    describe ".expiring_in" do
      let!(:expiring) { create(:subscription, business: business, plan: plan, status: :active, end_date: Date.current + 5) }
      let!(:not_expiring) { create(:subscription, business: create(:business), plan: plan, status: :active, end_date: Date.current + 10) }

      it "returns subscriptions expiring in N days" do
        expect(Subscription.expiring_in(5)).to include(expiring)
        expect(Subscription.expiring_in(5)).not_to include(not_expiring)
      end
    end

    describe ".expired_since" do
      let!(:expired) do
        sub = create(:subscription, business: business, plan: plan, status: :active)
        sub.update_column(:end_date, Date.current - 3)
        sub
      end

      it "returns subscriptions expired N days ago" do
        expect(Subscription.expired_since(3)).to include(expired)
      end
    end
  end

  describe ".ransackable_attributes" do
    it "returns expected attributes" do
      expect(Subscription.ransackable_attributes).to include("status", "start_date", "end_date")
    end
  end

  describe ".ransackable_associations" do
    it "returns expected associations" do
      expect(Subscription.ransackable_associations).to include("business", "plan")
    end
  end
end
