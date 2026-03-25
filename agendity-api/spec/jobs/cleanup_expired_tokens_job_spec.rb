require "rails_helper"

RSpec.describe CleanupExpiredTokensJob, type: :job do
  before do
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    let(:user) { create(:user) }

    context "with expired refresh tokens" do
      let!(:expired_token) { create(:refresh_token, user: user, expires_at: 1.day.ago) }
      let!(:valid_token)   { create(:refresh_token, user: user, expires_at: 30.days.from_now) }

      it "deletes expired refresh tokens" do
        expect { described_class.perform_now }.to change(RefreshToken, :count).by(-1)
        expect(RefreshToken.exists?(expired_token.id)).to be false
        expect(RefreshToken.exists?(valid_token.id)).to be true
      end
    end

    context "with old JWT denylist entries" do
      it "deletes entries expired more than 24 hours ago" do
        JwtDenylist.create!(jti: SecureRandom.uuid, exp: 2.days.ago)
        JwtDenylist.create!(jti: SecureRandom.uuid, exp: 1.hour.ago)

        expect { described_class.perform_now }.to change(JwtDenylist, :count).by(-1)
      end
    end
  end
end
