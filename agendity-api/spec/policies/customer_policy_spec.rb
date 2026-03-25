require "rails_helper"

RSpec.describe CustomerPolicy do
  let(:owner)    { create(:user) }
  let(:business) { create(:business, owner: owner) }
  let(:customer) { create(:customer, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  context "when user owns the business" do
    subject { described_class.new(owner, customer) }

    it "allows index" do
      expect(subject.index?).to be true
    end

    it "allows show" do
      expect(subject.show?).to be true
    end
  end

  context "when user does not own the business" do
    let(:other_user) { create(:user) }
    subject { described_class.new(other_user, customer) }

    it "allows index" do
      expect(subject.index?).to be true
    end

    it "denies show" do
      expect(subject.show?).to be false
    end
  end

  describe "Scope" do
    it "returns only customers from user businesses" do
      customer # force create
      scope = described_class::Scope.new(owner, Customer).resolve
      expect(scope).to include(customer)
    end
  end
end
