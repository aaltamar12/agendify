require "rails_helper"

RSpec.describe BusinessPolicy do
  let(:owner)    { create(:user) }
  let(:business) { create(:business, owner: owner) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  context "when user is the owner" do
    subject { described_class.new(owner, business) }

    it "allows show" do
      expect(subject.show?).to be true
    end

    it "allows update" do
      expect(subject.update?).to be true
    end

    it "allows onboarding" do
      expect(subject.onboarding?).to be true
    end
  end

  context "when user is an admin" do
    let(:admin) { create(:user, :admin) }
    subject { described_class.new(admin, business) }

    it "allows update" do
      expect(subject.update?).to be true
    end

    it "denies show" do
      expect(subject.show?).to be false
    end
  end

  context "when user is not the owner" do
    let(:other_user) { create(:user) }
    subject { described_class.new(other_user, business) }

    it "denies show" do
      expect(subject.show?).to be false
    end

    it "denies onboarding" do
      expect(subject.onboarding?).to be false
    end
  end
end
