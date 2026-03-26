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
      let(:customer) { create(:customer, business: business) }
      let(:service)  { create(:service, business: business) }
      let(:employee) { create(:employee, business: business) }

      it "evaluates daily average progress" do
        result = described_class.call(business: business)
        expect(result).to be_success
        expect(result.data.first[:goal_type]).to eq("daily_average")
      end

      it "returns 'on_track' when daily average meets target" do
        # Create enough revenue to meet the daily average target
        create(:appointment, business: business, employee: employee, customer: customer,
               service: service, status: :completed, price: 100_000 * Date.current.day,
               appointment_date: Date.current)

        result = described_class.call(business: business)
        progress = result.data.first
        expect(progress[:suggestion]).to include("supera tu objetivo")
      end

      it "returns suggestion to increase daily average when below target" do
        create(:appointment, business: business, employee: employee, customer: customer,
               service: service, status: :completed, price: 10_000,
               appointment_date: Date.current)

        result = described_class.call(business: business)
        progress = result.data.first
        expect(progress[:suggestion]).to include("Necesitas")
      end
    end

    context "with custom goal type" do
      let!(:goal) { create(:business_goal, business: business, goal_type: "custom", target_value: 500_000, name: "Mi meta") }

      it "evaluates custom goal progress" do
        result = described_class.call(business: business)
        expect(result).to be_success
        progress = result.data.first
        expect(progress[:goal_type]).to eq("custom")
        expect(progress[:name]).to eq("Mi meta")
        expect(progress[:suggestion]).to include("Progreso:")
      end
    end

    context "with monthly_sales goal — various progress levels" do
      let(:customer) { create(:customer, business: business) }
      let(:service)  { create(:service, business: business) }
      let(:employee) { create(:employee, business: business) }

      context "when goal is achieved (100%+)" do
        let!(:goal) { create(:business_goal, business: business, goal_type: "monthly_sales", target_value: 100_000) }

        before do
          create(:appointment, business: business, employee: employee, customer: customer,
                 service: service, status: :completed, price: 150_000,
                 appointment_date: Date.current)
        end

        it "returns achieved status with congratulatory suggestion" do
          result = described_class.call(business: business)
          progress = result.data.first
          expect(progress[:status]).to eq("achieved")
          expect(progress[:progress]).to eq(100.0)
          expect(progress[:suggestion]).to include("Meta cumplida")
        end
      end

      context "when at 80%+" do
        let!(:goal) { create(:business_goal, business: business, goal_type: "monthly_sales", target_value: 100_000) }

        before do
          create(:appointment, business: business, employee: employee, customer: customer,
                 service: service, status: :completed, price: 85_000,
                 appointment_date: Date.current)
        end

        it "returns on_track status" do
          result = described_class.call(business: business)
          progress = result.data.first
          expect(progress[:status]).to eq("on_track")
          expect(progress[:suggestion]).to include("Excelente")
        end
      end

      context "when at 50%-79%" do
        let!(:goal) { create(:business_goal, business: business, goal_type: "monthly_sales", target_value: 100_000) }

        before do
          create(:appointment, business: business, employee: employee, customer: customer,
                 service: service, status: :completed, price: 60_000,
                 appointment_date: Date.current)
        end

        it "returns behind status with citas suggestion" do
          result = described_class.call(business: business)
          progress = result.data.first
          expect(progress[:status]).to eq("behind")
          expect(progress[:suggestion]).to include("citas")
        end
      end

      context "when below 50%" do
        let!(:goal) { create(:business_goal, business: business, goal_type: "monthly_sales", target_value: 1_000_000) }

        before do
          create(:appointment, business: business, employee: employee, customer: customer,
                 service: service, status: :completed, price: 100_000,
                 appointment_date: Date.current)
        end

        it "returns at_risk status with daily target" do
          result = described_class.call(business: business)
          progress = result.data.first
          expect(progress[:status]).to eq("at_risk")
          expect(progress[:suggestion]).to include("promedio diario")
        end
      end
    end

    context "with break_even goal — various progress levels" do
      let(:customer) { create(:customer, business: business) }
      let(:service)  { create(:service, business: business) }
      let(:employee) { create(:employee, business: business) }

      context "when break-even is achieved" do
        let!(:goal) { create(:business_goal, business: business, goal_type: "break_even", target_value: 100_000, fixed_costs: 100_000) }

        before do
          create(:appointment, business: business, employee: employee, customer: customer,
                 service: service, status: :completed, price: 150_000,
                 appointment_date: Date.current)
        end

        it "returns achieved status" do
          result = described_class.call(business: business)
          progress = result.data.first
          expect(progress[:status]).to eq("achieved")
          expect(progress[:suggestion]).to include("superado tu punto de equilibrio")
        end
      end

      context "when at 70%+" do
        let!(:goal) { create(:business_goal, business: business, goal_type: "break_even", target_value: 100_000, fixed_costs: 100_000) }

        before do
          create(:appointment, business: business, employee: employee, customer: customer,
                 service: service, status: :completed, price: 75_000,
                 appointment_date: Date.current)
        end

        it "returns on_track status" do
          result = described_class.call(business: business)
          progress = result.data.first
          expect(progress[:status]).to eq("on_track")
          expect(progress[:suggestion]).to include("Vas al")
        end
      end

      context "when below 70%" do
        let!(:goal) { create(:business_goal, business: business, goal_type: "break_even", target_value: 500_000, fixed_costs: 500_000) }

        before do
          create(:appointment, business: business, employee: employee, customer: customer,
                 service: service, status: :completed, price: 50_000,
                 appointment_date: Date.current)
        end

        it "returns at_risk status with daily target" do
          result = described_class.call(business: business)
          progress = result.data.first
          expect(progress[:suggestion]).to include("diarios")
        end
      end
    end

    context "goal with nil name" do
      let!(:goal) { create(:business_goal, business: business, goal_type: "monthly_sales", target_value: 100_000, name: nil) }

      it "humanizes the goal_type as name" do
        result = described_class.call(business: business)
        expect(result.data.first[:name]).to eq("Monthly sales")
      end
    end
  end
end
