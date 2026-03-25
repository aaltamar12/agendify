require "rails_helper"

RSpec.describe NotificationSerializer do
  let(:notification) { create(:notification) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  subject(:result) { JSON.parse(described_class.render(notification)) }

  it "renders expected keys" do
    expect(result).to include("id", "title", "body", "notification_type", "read", "created_at")
  end
end
