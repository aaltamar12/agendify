require "rails_helper"

RSpec.describe SendSubscriptionReminderJob, type: :job do
  let(:business) { create(:business) }
  let(:plan)     { create(:plan) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  describe "#perform" do
    context "when there are pending orders due in 3 days" do
      let!(:subscription) { create(:subscription, business: business, plan: plan) }
      let!(:order) do
        create(:subscription_payment_order,
          subscription: subscription, business: business, plan: plan,
          due_date: 3.days.from_now.to_date, status: "pending")
      end

      it "creates an in-app notification" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)
      end

      it "enqueues a payment reminder email" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :subscription_payment_reminder)
      end

      it "creates an activity log" do
        expect { described_class.perform_now }.to change(ActivityLog, :count).by(1)
      end
    end

    context "when no orders are due in 3 days" do
      let!(:subscription) { create(:subscription, business: business, plan: plan) }
      let!(:order) do
        create(:subscription_payment_order,
          subscription: subscription, business: business, plan: plan,
          due_date: 10.days.from_now.to_date, status: "pending")
      end

      it "does not create notifications" do
        expect { described_class.perform_now }.not_to change(Notification, :count)
      end
    end
  end
end
