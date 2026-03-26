require "rails_helper"

RSpec.describe BirthdayCampaignJob do
  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
    allow(JobConfig).to receive(:enabled?).with("BirthdayCampaignJob").and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)
    allow(Notifications::MultiChannelService).to receive(:call)
  end

  describe "#perform" do
    context "when a customer has a birthday today" do
      let!(:business) do
        create(:business, birthday_campaign_enabled: true, birthday_discount_pct: 15, birthday_discount_days_valid: 10)
      end
      let!(:employee) { create(:employee, business: business) }
      let!(:customer) do
        create(:customer, business: business, birth_date: Date.current - 25.years)
      end

      it "generates a discount code for the customer" do
        expect { described_class.perform_now }.to change(DiscountCode, :count).by(1)

        code = DiscountCode.last
        expect(code.business).to eq(business)
        expect(code.customer).to eq(customer)
        expect(code.discount_type).to eq("percentage")
        expect(code.discount_value).to eq(15)
        expect(code.max_uses).to eq(1)
        expect(code.source).to eq("birthday")
        expect(code.valid_from).to eq(Date.current)
        expect(code.valid_until).to eq(Date.current + 10.days)
      end

      it "sends a notification via MultiChannelService" do
        described_class.perform_now

        expect(Notifications::MultiChannelService).to have_received(:call).with(
          hash_including(
            recipient: customer,
            template: :birthday_greeting,
            business: business
          )
        )
      end

      it "creates an activity log" do
        expect { described_class.perform_now }.to change(ActivityLog, :count).by(1)

        log = ActivityLog.last
        expect(log.business).to eq(business)
        expect(log.action).to eq("birthday_campaign_sent")
      end
    end

    context "when business has birthday_campaign_enabled: false" do
      let!(:business) do
        create(:business, birthday_campaign_enabled: false)
      end
      let!(:employee) { create(:employee, business: business) }
      let!(:customer) do
        create(:customer, business: business, birth_date: Date.current - 30.years)
      end

      it "does not generate a discount code" do
        expect { described_class.perform_now }.not_to change(DiscountCode, :count)
      end
    end

    context "when customer has no birth_date" do
      let!(:business) do
        create(:business, birthday_campaign_enabled: true)
      end
      let!(:employee) { create(:employee, business: business) }
      let!(:customer) do
        create(:customer, business: business, birth_date: nil)
      end

      it "does not generate a discount code" do
        expect { described_class.perform_now }.not_to change(DiscountCode, :count)
      end
    end

    context "when a birthday code already exists for today" do
      let!(:business) do
        create(:business, birthday_campaign_enabled: true, birthday_discount_pct: 10, birthday_discount_days_valid: 7)
      end
      let!(:employee) { create(:employee, business: business) }
      let!(:customer) do
        create(:customer, business: business, birth_date: Date.current - 20.years)
      end

      it "creates a code on first run" do
        expect { described_class.perform_now }.to change(DiscountCode, :count).by(1)
      end

      it "creates another code on second run (job is idempotent per day via cron scheduling)" do
        described_class.perform_now
        # The job itself does not check for duplicates — it relies on cron running once per day.
        # Running it twice will create two codes.
        expect { described_class.perform_now }.to change(DiscountCode, :count).by(1)
      end
    end

    context "when business plan has ai_features enabled" do
      let(:ai_plan) { create(:plan, name: "Pro+", ai_features: true) }
      let!(:business) do
        create(:business, birthday_campaign_enabled: true, birthday_discount_pct: 10, birthday_discount_days_valid: 7)
      end
      let!(:subscription) do
        create(:subscription, business: business, plan: ai_plan, status: :active)
      end
      let!(:employee) { create(:employee, business: business) }
      let!(:customer) do
        create(:customer, business: business, birth_date: Date.current - 25.years)
      end

      it "creates an in-app notification for the business owner" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.title).to include(customer.name)
        expect(notification.notification_type).to eq("birthday")
      end

      it "publishes a NATS birthday event" do
        described_class.perform_now
        expect(Realtime::NatsPublisher).to have_received(:publish).with(
          hash_including(event: "birthday", business_id: business.id)
        )
      end
    end

    context "when customer has no email" do
      let!(:business) do
        create(:business, birthday_campaign_enabled: true, birthday_discount_pct: 10, birthday_discount_days_valid: 7)
      end
      let!(:employee) { create(:employee, business: business) }
      let!(:customer) do
        create(:customer, business: business, birth_date: Date.current - 25.years, email: nil)
      end

      it "does not generate a discount code (requires email)" do
        expect { described_class.perform_now }.not_to change(DiscountCode, :count)
      end
    end

    context "when job is disabled" do
      before do
        allow(JobConfig).to receive(:enabled?).with("BirthdayCampaignJob").and_return(false)
      end

      let!(:business) do
        create(:business, birthday_campaign_enabled: true)
      end
      let!(:employee) { create(:employee, business: business) }
      let!(:customer) do
        create(:customer, business: business, birth_date: Date.current - 25.years)
      end

      it "does not process any businesses" do
        expect { described_class.perform_now }.not_to change(DiscountCode, :count)
      end
    end
  end
end
