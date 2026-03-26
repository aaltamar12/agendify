require "rails_helper"

RSpec.describe TrialExpiryAlertJob do
  let(:plan) { create(:plan) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    # Ensure the job is enabled
    allow(JobConfig).to receive(:enabled?).with("TrialExpiryAlertJob").and_return(true)
    allow(JobConfig).to receive(:record_run!)
    # Stub SiteConfig
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  describe "#perform" do
    context "Stage 1: trial expiring in 5 days" do
      let!(:business) do
        create(:business,
          trial_ends_at: 5.days.from_now.beginning_of_day,
          trial_alert_stage: 0,
          status: :active)
      end

      it "sends alert and sets trial_alert_stage to 1" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :trial_expiry_alert)

        business.reload
        expect(business.trial_alert_stage).to eq(1)
      end

      it "creates an in-app notification" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.business).to eq(business)
        expect(notification.title).to include("5 dias")
      end

      it "publishes a real-time event" do
        described_class.perform_now

        expect(Realtime::NatsPublisher).to have_received(:publish).with(
          hash_including(business_id: business.id, event: "trial_expiry")
        )
      end

      it "creates an activity log" do
        expect { described_class.perform_now }.to change(ActivityLog, :count).by(1)
      end
    end

    context "Stage 2: trial ends today" do
      let!(:business) do
        create(:business,
          trial_ends_at: Date.current.beginning_of_day,
          trial_alert_stage: 1,
          status: :active)
      end

      it "sends thank-you email and sets trial_alert_stage to 2" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :trial_ended_thank_you)

        business.reload
        expect(business.trial_alert_stage).to eq(2)
      end

      it "creates an in-app notification about trial ending today" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.title).to include("termina hoy")
      end
    end

    context "Stage 3: trial expired 2 days ago" do
      let!(:business) do
        create(:business,
          trial_ends_at: 2.days.ago.beginning_of_day,
          trial_alert_stage: 2,
          status: :active)
      end

      it "sends suspension alert and sets trial_alert_stage to 3" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(BusinessMailer, :trial_expiry_alert)

        business.reload
        expect(business.trial_alert_stage).to eq(3)
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

      it "logs a business_suspended activity" do
        described_class.perform_now

        log = ActivityLog.where(action: "business_suspended").last
        expect(log).to be_present
        expect(log.business).to eq(business)
      end
    end

    context "skips businesses with active subscription" do
      let!(:business) do
        create(:business,
          trial_ends_at: 5.days.from_now.beginning_of_day,
          trial_alert_stage: 0,
          status: :active)
      end
      let!(:subscription) do
        create(:subscription,
          business: business,
          plan: plan,
          status: :active,
          end_date: 30.days.from_now)
      end

      it "does not send alert" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(BusinessMailer, :trial_expiry_alert)

        business.reload
        expect(business.trial_alert_stage).to eq(0)
      end
    end

    context "anti-duplicates: skips businesses that already received the alert" do
      let!(:business_stage_1_done) do
        create(:business,
          trial_ends_at: 5.days.from_now.beginning_of_day,
          trial_alert_stage: 1,
          status: :active)
      end

      let!(:business_stage_2_done) do
        create(:business,
          trial_ends_at: Date.current.beginning_of_day,
          trial_alert_stage: 2,
          status: :active)
      end

      it "does not re-send stage 1 to a business already at stage 1" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(BusinessMailer, :trial_expiry_alert)

        business_stage_1_done.reload
        expect(business_stage_1_done.trial_alert_stage).to eq(1)
      end

      it "does not re-send stage 2 to a business already at stage 2" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(BusinessMailer, :trial_ended_thank_you)

        business_stage_2_done.reload
        expect(business_stage_2_done.trial_alert_stage).to eq(2)
      end
    end

    context "when job is disabled" do
      before do
        allow(JobConfig).to receive(:enabled?).with("TrialExpiryAlertJob").and_return(false)
      end

      let!(:business) do
        create(:business,
          trial_ends_at: 5.days.from_now.beginning_of_day,
          trial_alert_stage: 0,
          status: :active)
      end

      it "does not process any businesses" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(BusinessMailer)

        business.reload
        expect(business.trial_alert_stage).to eq(0)
      end
    end
  end
end
