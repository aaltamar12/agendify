require "rails_helper"

RSpec.describe BusinessGoal, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:goal_type) }
    it { is_expected.to validate_presence_of(:target_value) }
    it { is_expected.to validate_numericality_of(:target_value).is_greater_than(0) }

    it "validates goal_type inclusion" do
      goal = build(:business_goal, business: business, goal_type: "invalid")
      expect(goal).not_to be_valid
      expect(goal.errors[:goal_type]).to be_present
    end

    it "accepts valid goal types" do
      %w[break_even monthly_sales daily_average custom].each do |type|
        goal = build(:business_goal, business: business, goal_type: type)
        expect(goal).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_goal)   { create(:business_goal, business: business, active: true) }
      let!(:inactive_goal) { create(:business_goal, business: business, active: false) }

      it "returns only active goals" do
        expect(described_class.active).to include(active_goal)
        expect(described_class.active).not_to include(inactive_goal)
      end
    end
  end
end
