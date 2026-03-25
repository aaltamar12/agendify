require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:refresh_token) }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".active" do
      let!(:active_token)  { create(:refresh_token, user: user, expires_at: 1.day.from_now) }
      let!(:expired_token) { create(:refresh_token, user: user, expires_at: 1.day.ago) }

      it "returns only non-expired tokens" do
        expect(described_class.active).to include(active_token)
        expect(described_class.active).not_to include(expired_token)
      end
    end

    describe ".expired" do
      let!(:active_token)  { create(:refresh_token, user: user, expires_at: 1.day.from_now) }
      let!(:expired_token) { create(:refresh_token, user: user, expires_at: 1.day.ago) }

      it "returns only expired tokens" do
        expect(described_class.expired).to include(expired_token)
        expect(described_class.expired).not_to include(active_token)
      end
    end
  end
end
