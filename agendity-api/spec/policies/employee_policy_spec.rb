require "rails_helper"

RSpec.describe EmployeePolicy do
  let(:owner)    { create(:user) }
  let(:business) { create(:business, owner: owner) }
  let(:employee) { create(:employee, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  context "when user owns the business" do
    subject { described_class.new(owner, employee) }

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
    subject { described_class.new(other_user, employee) }

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
    it "returns only employees from user businesses" do
      employee # force create
      scope = described_class::Scope.new(owner, Employee).resolve
      expect(scope).to include(employee)
    end
  end
end
