require "rails_helper"

RSpec.describe NotificationEventConfig, type: :model do
  describe "validations" do
    subject { build(:notification_event_config) }

    it { is_expected.to validate_presence_of(:event_key) }
    it { is_expected.to validate_uniqueness_of(:event_key) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_config)   { create(:notification_event_config, active: true) }
      let!(:inactive_config) { create(:notification_event_config, active: false) }

      it "returns only active configs" do
        expect(described_class.active).to include(active_config)
        expect(described_class.active).not_to include(inactive_config)
      end
    end
  end
end
