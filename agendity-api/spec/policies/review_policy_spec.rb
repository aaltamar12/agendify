require "rails_helper"

RSpec.describe ReviewPolicy do
  let(:owner)    { create(:user) }
  let(:business) { create(:business, owner: owner) }
  let(:review)   { create(:review, business: business) }

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  context "any user" do
    subject { described_class.new(owner, review) }

    it "allows index" do
      expect(subject.index?).to be true
    end
  end

  describe "Scope" do
    it "returns only reviews from user businesses" do
      review # force create
      scope = described_class::Scope.new(owner, Review).resolve
      expect(scope).to include(review)
    end
  end
end
