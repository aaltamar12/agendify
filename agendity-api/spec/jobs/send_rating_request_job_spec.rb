require "rails_helper"

RSpec.describe SendRatingRequestJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let!(:appointment) do
    create(:appointment, :completed,
      business: business, employee: employee, customer: customer, service: service)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)
    allow(Notifications::MultiChannelService).to receive(:call)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    it "sends a rating request via MultiChannelService" do
      described_class.perform_now(appointment.id)
      expect(Notifications::MultiChannelService).to have_received(:call).with(
        hash_including(recipient: customer, template: :rating_request)
      )
    end

    context "when appointment has a customer" do
      it "performs without error" do
        expect { described_class.perform_now(appointment.id) }.not_to raise_error
      end
    end
  end
end
