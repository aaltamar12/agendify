require "rails_helper"

RSpec.describe Intelligence::PricingSuggestionJob, type: :job do
  let(:plan)     { create(:plan, ai_features: true) }
  let(:business) { create(:business, status: :active) }
  let!(:subscription) { create(:subscription, business: business, plan: plan, status: :active) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    context "when business has enough appointments and suggestions exist" do
      let(:suggestions) { [{ service_id: 1, suggested_price: 30_000 }] }
      let(:result) { ServiceResult.new(success: true, data: suggestions) }

      before do
        allow_any_instance_of(Appointment.const_get(:ActiveRecord_Associations_CollectionProxy)).to receive(:count).and_return(50)
        allow(Intelligence::DemandAnalysisService).to receive(:call).and_return(result)
      end

      it "creates a notification for the business" do
        expect { described_class.perform_now }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.business).to eq(business)
        expect(notification.notification_type).to eq("ai_suggestion")
      end

      it "publishes a NATS event" do
        described_class.perform_now
        expect(Realtime::NatsPublisher).to have_received(:publish).with(
          hash_including(business_id: business.id, event: "ai_suggestion")
        )
      end
    end

    context "when business has fewer than 30 appointments" do
      before do
        allow(Intelligence::DemandAnalysisService).to receive(:call)
      end

      it "skips the business" do
        described_class.perform_now
        expect(Intelligence::DemandAnalysisService).not_to have_received(:call)
      end
    end
  end
end
