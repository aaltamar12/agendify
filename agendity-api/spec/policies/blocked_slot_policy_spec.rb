require "rails_helper"

RSpec.describe BlockedSlotPolicy do
  let(:owner)    { create(:user) }
  let(:business) { create(:business, owner: owner) }
  let(:blocked_slot) { create(:blocked_slot, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  context "when user owns the business" do
    subject { described_class.new(owner, blocked_slot) }

    it "allows index" do
      expect(subject.index?).to be true
    end

    it "allows create" do
      expect(subject.create?).to be true
    end

    it "allows destroy" do
      expect(subject.destroy?).to be true
    end
  end

  context "when user does not own the business" do
    let(:other_user) { create(:user) }
    subject { described_class.new(other_user, blocked_slot) }

    it "denies create" do
      expect(subject.create?).to be false
    end

    it "denies destroy" do
      expect(subject.destroy?).to be false
    end
  end

  describe "Scope" do
    it "returns only blocked slots from user businesses" do
      blocked_slot # force create
      scope = described_class::Scope.new(owner, BlockedSlot).resolve
      expect(scope).to include(blocked_slot)
    end
  end
end
