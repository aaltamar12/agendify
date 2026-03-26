require "rails_helper"

RSpec.describe SubscriptionExpiryAlertJob do
  let(:plan)     { create(:plan, name: "Profesional", price_monthly: 49_900) }
  let(:business) { create(:business, status: :active) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    allow(JobConfig).to receive(:enabled?).with("SubscriptionExpiryAlertJob").and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    context "Stage 1: subscription expiring in 5 days" do
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current + 5,
          expiry_alert_stage: 0)
      end

      it "sends alert and sets expiry_alert_stage to 1" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :subscription_expiry_alert)

        subscription.reload
        expect(subscription.expiry_alert_stage).to eq(1)
      end

      it "creates an in-app notification" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.title).to include("5 días")
      end

      it "publishes real-time event" do
        described_class.perform_now

        expect(Realtime::NatsPublisher).to have_received(:publish).with(
          hash_including(business_id: business.id, event: "subscription_expiry")
        )
      end

      it "logs the activity" do
        expect { described_class.perform_now }.to change(ActivityLog, :count).by(1)

        log = ActivityLog.last
        expect(log.action).to eq("subscription_expiry_alert")
      end
    end

    context "Stage 2: subscription expires today" do
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current,
          expiry_alert_stage: 1)
      end

      it "sends alert and sets expiry_alert_stage to 2" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :subscription_expiry_alert)

        subscription.reload
        expect(subscription.expiry_alert_stage).to eq(2)
      end

      it "creates an in-app notification about expiry today" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.title).to include("vence hoy")
      end
    end

    context "Stage 3: subscription expired 2 days ago" do
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current - 2,
          expiry_alert_stage: 2)
      end

      it "sends suspension alert and sets expiry_alert_stage to 3" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :subscription_expiry_alert)

        subscription.reload
        expect(subscription.expiry_alert_stage).to eq(3)
      end

      it "suspends the business" do
        described_class.perform_now
        business.reload

        expect(business.status).to eq("suspended")
      end

      it "creates an AdminNotification about the suspension" do
        expect { described_class.perform_now }.to change(AdminNotification, :count).by(1)

        notification = AdminNotification.last
        expect(notification.title).to include("suspendido")
      end

      it "logs business_suspended activity" do
        described_class.perform_now

        log = ActivityLog.where(action: "business_suspended").last
        expect(log).to be_present
        expect(log.business).to eq(business)
      end
    end

    context "anti-duplicates via expiry_alert_stage" do
      let!(:subscription_stage_1_done) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current + 5,
          expiry_alert_stage: 1)
      end

      it "does not re-send stage 1 alert" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(BusinessMailer, :subscription_expiry_alert)

        subscription_stage_1_done.reload
        expect(subscription_stage_1_done.expiry_alert_stage).to eq(1)
      end
    end

    context "does not process subscriptions at wrong stage" do
      let!(:subscription_stage_0) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current,
          expiry_alert_stage: 0)
      end

      it "does not send stage 2 alert if still at stage 0" do
        # Stage 2 requires expiry_alert_stage: 1 and end_date == today
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(BusinessMailer, :subscription_expiry_alert)
      end
    end

    context "Stage 4: subscription expired 7 days ago" do
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current - 7,
          expiry_alert_stage: 3)
      end

      it "sets expiry_alert_stage to 4" do
        described_class.perform_now
        subscription.reload
        expect(subscription.expiry_alert_stage).to eq(4)
      end

      it "deactivates the business" do
        described_class.perform_now
        business.reload
        expect(business.status).to eq("inactive")
      end

      it "creates an AdminNotification about the deactivation" do
        expect { described_class.perform_now }.to change(AdminNotification, :count).by(1)

        notification = AdminNotification.last
        expect(notification.title).to include("desactivado")
      end

      it "logs business_deactivated activity" do
        described_class.perform_now
        log = ActivityLog.where(action: "business_deactivated").last
        expect(log).to be_present
        expect(log.business).to eq(business)
      end
    end

    context "WhatsApp notification for Pro+ plan" do
      let(:pro_plan) { create(:plan, name: "Pro+", price_monthly: 99_900, whatsapp_notifications: true) }
      let(:owner) { business.owner }
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: pro_plan,
          status: :active,
          end_date: Date.current + 5,
          expiry_alert_stage: 0)
      end

      before do
        owner.update!(phone: "+573001234567")
        allow(business).to receive(:current_plan).and_return(pro_plan)
      end

      it "sends WhatsApp notification when plan supports it and owner has phone" do
        described_class.perform_now
        expect(Notifications::WhatsAppChannel).to have_received(:deliver).with(
          hash_including(template: :subscription_expiry_stage_1)
        )
      end
    end

    context "when job is disabled" do
      before do
        allow(JobConfig).to receive(:enabled?).with("SubscriptionExpiryAlertJob").and_return(false)
      end

      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: Date.current + 5,
          expiry_alert_stage: 0)
      end

      it "does not process any subscriptions" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(BusinessMailer)

        subscription.reload
        expect(subscription.expiry_alert_stage).to eq(0)
      end
    end
  end
end
