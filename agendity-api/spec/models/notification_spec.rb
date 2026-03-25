require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:notification_type) }

    it "validates notification_type inclusion" do
      notification = build(:notification, business: business, notification_type: "invalid")
      expect(notification).not_to be_valid
    end

    it "accepts valid notification types" do
      %w[new_booking payment_submitted payment_approved booking_cancelled reminder ai_suggestion subscription_expiry].each do |type|
        notification = build(:notification, business: business, notification_type: type)
        expect(notification).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".unread" do
      let!(:unread) { create(:notification, business: business, read: false) }
      let!(:read)   { create(:notification, business: business, read: true) }

      it "returns only unread notifications" do
        expect(described_class.unread).to include(unread)
        expect(described_class.unread).not_to include(read)
      end
    end

    describe ".recent" do
      it "returns notifications ordered by created_at desc" do
        create_list(:notification, 3, business: business)
        expect(described_class.recent.first.created_at).to be >= described_class.recent.last.created_at
      end
    end
  end
end
