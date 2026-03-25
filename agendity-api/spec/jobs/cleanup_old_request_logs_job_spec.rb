require "rails_helper"

RSpec.describe CleanupOldRequestLogsJob, type: :job do
  before do
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    let(:business) { create(:business) }

    context "with old successful request logs" do
      before do
        create(:request_log, business: business, status_code: 200, created_at: 31.days.ago)
        create(:request_log, business: business, status_code: 200, created_at: 5.days.ago)
      end

      it "deletes logs older than 30 days" do
        expect { described_class.perform_now }.to change(RequestLog, :count).by(-1)
      end
    end

    context "with old error request logs" do
      before do
        create(:request_log, :error, business: business, created_at: 91.days.ago)
        create(:request_log, :error, business: business, created_at: 30.days.ago)
      end

      it "deletes error logs older than 90 days" do
        expect { described_class.perform_now }.to change(RequestLog, :count).by(-1)
      end
    end
  end
end
