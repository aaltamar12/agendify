require "rails_helper"

RSpec.describe RequestLog, type: :model do
  describe "associations" do
    it { should belong_to(:business).optional }
  end

  describe "scopes" do
    let!(:ok_log) { create(:request_log, status_code: 200) }
    let!(:client_error_log) { create(:request_log, :error) }
    let!(:server_error_log) { create(:request_log, :server_error) }

    describe ".errors" do
      it "returns logs with status >= 400" do
        expect(described_class.errors).to include(client_error_log, server_error_log)
        expect(described_class.errors).not_to include(ok_log)
      end
    end

    describe ".server_errors" do
      it "returns logs with status >= 500" do
        expect(described_class.server_errors).to include(server_error_log)
        expect(described_class.server_errors).not_to include(ok_log, client_error_log)
      end
    end

    describe ".for_resource" do
      let!(:appointment_log) { create(:request_log, :with_resource, resource_type: "Appointment", resource_id: 42) }

      it "returns logs for a specific resource" do
        expect(described_class.for_resource("Appointment", 42)).to contain_exactly(appointment_log)
      end
    end

    describe ".slow_requests" do
      let!(:slow_log) { create(:request_log, duration_ms: 2000) }
      let!(:fast_log) { create(:request_log, duration_ms: 50) }

      it "returns requests above threshold" do
        expect(described_class.slow_requests(1000)).to contain_exactly(slow_log)
      end
    end
  end

  describe "instance methods" do
    it "#error? returns true for 4xx status" do
      log = build(:request_log, status_code: 422)
      expect(log.error?).to be true
    end

    it "#error? returns false for 2xx status" do
      log = build(:request_log, status_code: 200)
      expect(log.error?).to be false
    end

    it "#server_error? returns true for 5xx status" do
      log = build(:request_log, status_code: 500)
      expect(log.server_error?).to be true
    end

    it "#server_error? returns false for 4xx status" do
      log = build(:request_log, status_code: 422)
      expect(log.server_error?).to be false
    end

    it "#display_name returns method, path, and status" do
      log = build(:request_log, method: "GET", path: "/api/v1/test", status_code: 200)
      expect(log.display_name).to eq("GET /api/v1/test (200)")
    end
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to include("method", "path", "status_code")
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to include("business")
    end
  end
end
