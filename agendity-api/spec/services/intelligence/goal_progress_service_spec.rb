require "rails_helper"

RSpec.describe Intelligence::GoalProgressService do
  let(:business) { create(:business) }

  describe "#call" do
    context "with no active goals" do
      it "returns empty array" do
        result = described_class.call(business: business)
        expect(result).to be_success
        expect(result.data).to eq([])
      end
    end

    context "with monthly_sales goal" do
      let!(:goal) { create(:business_goal, business: business, goal_type: "monthly_sales", target_value: 1_000_000) }
      let(:customer) { create(:customer, business: business) }
      let(:service)  { create(:service, business: business) }
      let(:employee) { create(:employee, business: business) }

      before do
        create(:appointment, business: business, employee: employee, customer: customer,
               service: service, status: :completed, price: 300_000,
               appointment_date: Date.current)
      end

      it "calculates progress" do
        result = described_class.call(business: business)
        expect(result).to be_success
        expect(result.data.length).to eq(1)
        progress = result.data.first
        expect(progress[:goal_type]).to eq("monthly_sales")
        expect(progress[:current_value]).to eq(300_000.0)
        expect(progress[:progress]).to eq(30.0)
        expect(progress[:status]).to eq("at_risk")
      end
    end

    context "with break_even goal" do
      let!(:goal) { create(:business_goal, business: business, goal_type: "break_even", target_value: 500_000, fixed_costs: 500_000) }

      it "evaluates break even progress" do
        result = described_class.call(business: business)
        expect(result).to be_success
        expect(result.data.first[:goal_type]).to eq("break_even")
      end
    end

    context "with daily_average goal" do
      let!(:goal) { create(:business_goal, business: business, goal_type: "daily_average", target_value: 100_000) }

      it "evaluates daily average progress" do
        result = described_class.call(business: business)
        expect(result).to be_success
        expect(result.data.first[:goal_type]).to eq("daily_average")
      end
    end
  end
end
