require "rails_helper"

RSpec.describe JobConfig, type: :model do
  describe "validations" do
    subject { build(:job_config) }

    it { is_expected.to validate_presence_of(:job_class) }
    it { is_expected.to validate_uniqueness_of(:job_class) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "scopes" do
    describe ".enabled" do
      let!(:enabled_job)  { create(:job_config, enabled: true) }
      let!(:disabled_job) { create(:job_config, enabled: false) }

      it "returns only enabled jobs" do
        expect(described_class.enabled).to include(enabled_job)
        expect(described_class.enabled).not_to include(disabled_job)
      end
    end
  end

  describe ".enabled?" do
    it "returns true when no config exists (defaults enabled)" do
      expect(described_class.enabled?("NonexistentJob")).to be true
    end

    it "returns true when config is enabled" do
      create(:job_config, job_class: "MyJob", enabled: true)
      expect(described_class.enabled?("MyJob")).to be true
    end

    it "returns false when config is disabled" do
      create(:job_config, job_class: "MyJob", enabled: false)
      expect(described_class.enabled?("MyJob")).to be false
    end
  end

  describe ".record_run!" do
    it "records the execution status" do
      config = create(:job_config, job_class: "MyJob")
      described_class.record_run!("MyJob", status: "success", message: "All good")
      config.reload
      expect(config.last_run_status).to eq("success")
      expect(config.last_run_message).to eq("All good")
      expect(config.last_run_at).to be_present
    end

    it "does nothing when config does not exist" do
      expect {
        described_class.record_run!("Nonexistent", status: "success")
      }.not_to raise_error
    end
  end
end
