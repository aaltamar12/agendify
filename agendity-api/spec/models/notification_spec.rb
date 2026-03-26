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
      %w[new_booking payment_submitted payment_approved booking_cancelled reminder ai_suggestion subscription_expiry birthday].each do |type|
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

      it "limits to 20 notifications" do
        create_list(:notification, 25, business: business)
        expect(described_class.recent.count).to eq(20)
      end
    end
  end

  describe "validations edge cases" do
    it "is invalid without a title" do
      notification = build(:notification, business: business, title: nil)
      expect(notification).not_to be_valid
      expect(notification.errors[:title]).to be_present
    end

    it "is invalid without a notification_type" do
      notification = build(:notification, business: business, notification_type: nil)
      expect(notification).not_to be_valid
      expect(notification.errors[:notification_type]).to be_present
    end

    it "is invalid with empty string notification_type" do
      notification = build(:notification, business: business, notification_type: "")
      expect(notification).not_to be_valid
    end
  end

  describe "default values" do
    it "is unread by default" do
      notification = create(:notification, business: business)
      expect(notification.read).to be false
    end
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to include("title", "notification_type")
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to include("business")
    end
  end
end
