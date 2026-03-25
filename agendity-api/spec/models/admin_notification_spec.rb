require "rails_helper"

RSpec.describe AdminNotification, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "scopes" do
    describe ".unread" do
      let!(:unread) { create(:admin_notification, read: false) }
      let!(:read)   { create(:admin_notification, read: true) }

      it "returns only unread notifications" do
        expect(described_class.unread).to include(unread)
        expect(described_class.unread).not_to include(read)
      end
    end

    describe ".recent" do
      it "returns notifications in descending order" do
        create_list(:admin_notification, 3)
        expect(described_class.recent.first.created_at).to be >= described_class.recent.last.created_at
      end
    end
  end

  describe "#mark_read!" do
    it "marks the notification as read" do
      notification = create(:admin_notification, read: false)
      notification.mark_read!
      expect(notification.reload.read).to be true
    end
  end

  describe ".mark_all_read!" do
    it "marks all unread notifications as read" do
      create(:admin_notification, read: false)
      create(:admin_notification, read: false)
      described_class.mark_all_read!
      expect(described_class.unread.count).to eq(0)
    end
  end

  describe ".notify!" do
    it "creates a notification" do
      expect {
        described_class.notify!(title: "New signup", body: "A new business signed up")
      }.to change(described_class, :count).by(1)
    end
  end
end
