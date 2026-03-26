require "rails_helper"

RSpec.describe AppointmentPolicy do
  let(:owner)    { create(:user) }
  let(:business) { create(:business, owner: owner) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }
  let(:appointment) do
    create(:appointment, business: business, employee: employee, customer: customer, service: service)
  end

  before { allow(Realtime::NatsPublisher).to receive(:publish) }

  context "when user owns the business" do
    subject { described_class.new(owner, appointment) }

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

    it "allows confirm" do
      expect(subject.confirm?).to be true
    end

    it "allows checkin" do
      expect(subject.checkin?).to be true
    end

    it "allows cancel" do
      expect(subject.cancel?).to be true
    end

    it "allows complete" do
      expect(subject.complete?).to be true
    end
  end

  context "when user does not own the business" do
    let(:other_user) { create(:user) }
    subject { described_class.new(other_user, appointment) }

    it "denies index" do
      expect(subject.index?).to be false
    end

    it "denies show" do
      expect(subject.show?).to be false
    end

    it "denies confirm" do
      expect(subject.confirm?).to be false
    end

    it "denies checkin" do
      expect(subject.checkin?).to be false
    end

    it "denies cancel" do
      expect(subject.cancel?).to be false
    end

    it "denies complete" do
      expect(subject.complete?).to be false
    end
  end

  describe "Scope" do
    it "returns only appointments from user businesses" do
      appointment # force create
      scope = described_class::Scope.new(owner, Appointment).resolve
      expect(scope).to include(appointment)
    end
  end
end
