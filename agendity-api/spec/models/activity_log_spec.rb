require "rails_helper"

RSpec.describe ActivityLog, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe "scopes" do
    describe ".recent" do
      it "returns most recent logs first, limited to 50" do
        create_list(:activity_log, 3, business: business)
        expect(described_class.recent.count).to eq(3)
        expect(described_class.recent.first.created_at).to be >= described_class.recent.last.created_at
      end
    end
  end

  describe ".log" do
    it "creates an activity log entry" do
      expect {
        described_class.log(
          business: business,
          action: "test_action",
          description: "Something happened"
        )
      }.to change(described_class, :count).by(1)
    end

    it "stores metadata and actor info" do
      log = described_class.log(
        business: business,
        action: "test_action",
        description: "Test",
        actor_type: "business",
        actor_name: "Admin",
        metadata: { key: "value" },
        request_id: "req-123"
      )
      expect(log.actor_type).to eq("business")
      expect(log.actor_name).to eq("Admin")
      expect(log.metadata["key"]).to eq("value")
      expect(log.metadata["request_id"]).to eq("req-123")
    end

    it "stores resource polymorphic info" do
      employee = create(:employee, business: business)
      log = described_class.log(
        business: business,
        action: "test",
        description: "Test",
        resource: employee
      )
      expect(log.resource_type).to eq("Employee")
      expect(log.resource_id).to eq(employee.id)
    end

    it "fails silently on error" do
      expect {
        described_class.log(business: nil, action: nil, description: nil)
      }.not_to raise_error
    end
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to be_an(Array)
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to be_an(Array)
    end
  end

end
