require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:user) { create(:user) }
  let(:record) { double("record") }

  subject { described_class.new(user, record) }

  it "denies index by default" do
    expect(subject.index?).to be false
  end

  it "denies show by default" do
    expect(subject.show?).to be false
  end

  it "denies create by default" do
    expect(subject.create?).to be false
  end

  it "denies update by default" do
    expect(subject.update?).to be false
  end

  it "denies destroy by default" do
    expect(subject.destroy?).to be false
  end

  describe ApplicationPolicy::Scope do
    let(:scope) { double("scope", none: []) }

    it "returns no records by default" do
      expect(described_class.new(user, scope).resolve).to eq([])
    end
  end
end
