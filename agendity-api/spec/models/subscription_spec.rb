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
  end
end
