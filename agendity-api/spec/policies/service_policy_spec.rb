require "rails_helper"

RSpec.describe ServicePolicy do
  let(:owner)    { create(:user) }
  let(:business) { create(:business, owner: owner) }
  let(:service)  { create(:service, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  context "when user owns the business" do
    subject { described_class.new(owner, service) }

    it "allows index" do
      expect(subject.index?).to be true
    end

    it "allows show" do
      expect(subject.show?).to be true
    end

    it "allows create" do
      expect(subject.create?).to be true
    end

    it "allows update" do
      expect(subject.update?).to be true
    end

    it "allows destroy" do
      expect(subject.destroy?).to be true
    end
  end

  context "when user does not own the business" do
    let(:other_user) { create(:user) }
    subject { described_class.new(other_user, service) }

    it "allows index" do
      expect(subject.index?).to be true
    end

    it "denies show" do
      expect(subject.show?).to be false
    end

    it "denies update" do
      expect(subject.update?).to be false
    end

    it "denies destroy" do
      expect(subject.destroy?).to be false
    end
  end

  describe "Scope" do
    it "returns only services from user businesses" do
      service # force create
      scope = described_class::Scope.new(owner, Service).resolve
      expect(scope).to include(service)
    end
  end
end
