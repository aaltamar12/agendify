require "rails_helper"

RSpec.describe Business, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:business_type) }
    it { should validate_presence_of(:status) }

    it do
      create(:business)
      should validate_uniqueness_of(:slug)
    end
  end

  describe "enums" do
    it { should define_enum_for(:business_type).with_values(barbershop: 0, salon: 1, spa: 2, nails: 3, other: 4, estetica: 5, consultorio: 6) }
    it { should define_enum_for(:status).with_values(active: 0, suspended: 1, inactive: 2) }
  end

  describe "associations" do
    it { should belong_to(:owner).class_name("User") }
    it { should have_many(:employees).dependent(:destroy) }
    it { should have_many(:services).dependent(:destroy) }
    it { should have_many(:customers).dependent(:destroy) }
    it { should have_many(:appointments).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:business_hours).dependent(:destroy) }
    it { should have_many(:blocked_slots).dependent(:destroy) }
    it { should have_many(:subscriptions).dependent(:destroy) }
  end

  describe "PlanEnforcement" do
    let(:business) { create(:business) }

    let(:plan_basico) do
      create(:plan, name: "Básico", price_monthly: 30_000,
             max_employees: 3, max_services: 5,
             ticket_digital: false, advanced_reports: false,
             brand_customization: false, ai_features: false)
    end

    let(:plan_profesional) do
      create(:plan, name: "Profesional", price_monthly: 59_900,
             max_employees: 10, max_services: nil,
             ticket_digital: true, advanced_reports: true,
             brand_customization: true, ai_features: false)
    end

    describe "#current_plan" do
      it "returns nil when no active subscription" do
        expect(business.current_plan).to be_nil
      end

      it "returns the plan of the current active subscription" do
        create(:subscription, business: business, plan: plan_basico,
               status: :active, start_date: Date.current, end_date: 30.days.from_now)
        expect(business.current_plan).to eq(plan_basico)
      end

      it "ignores expired subscriptions" do
        create(:subscription, business: business, plan: plan_basico,
               status: :active, start_date: 60.days.ago, end_date: 1.day.ago)
        expect(business.current_plan).to be_nil
      end
    end

    describe "#can_create_employee?" do
      context "with no plan (trial)" do
        it "returns true" do
          expect(business.can_create_employee?).to be true
        end
      end

      context "with basic plan (max 3 employees)" do
        before do
          create(:subscription, business: business, plan: plan_basico,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true when under the limit" do
          create_list(:employee, 2, business: business, active: true)
          expect(business.can_create_employee?).to be true
        end

        it "returns false when at the limit" do
          create_list(:employee, 3, business: business, active: true)
          expect(business.can_create_employee?).to be false
        end

        it "does not count inactive employees" do
          create_list(:employee, 3, business: business, active: true)
          create(:employee, business: business, active: false)
          business.employees.active.first.update!(active: false)
          expect(business.can_create_employee?).to be true
        end
      end

      context "with professional plan (max 10 employees)" do
        before do
          create(:subscription, business: business, plan: plan_profesional,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true when under the limit" do
          create_list(:employee, 5, business: business, active: true)
          expect(business.can_create_employee?).to be true
        end
      end
    end

    describe "#can_create_service?" do
      context "with no plan (trial)" do
        it "returns true" do
          expect(business.can_create_service?).to be true
        end
      end

      context "with basic plan (max 5 services)" do
        before do
          create(:subscription, business: business, plan: plan_basico,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true when under the limit" do
          create_list(:service, 4, business: business, active: true)
          expect(business.can_create_service?).to be true
        end

        it "returns false when at the limit" do
          create_list(:service, 5, business: business, active: true)
          expect(business.can_create_service?).to be false
        end
      end

      context "with professional plan (unlimited services)" do
        before do
          create(:subscription, business: business, plan: plan_profesional,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true regardless of count" do
          create_list(:service, 20, business: business, active: true)
          expect(business.can_create_service?).to be true
        end
      end
    end

    describe "#has_feature?" do
      context "with no plan (trial)" do
        it "returns true for any feature" do
          expect(business.has_feature?(:ticket_digital)).to be true
          expect(business.has_feature?(:brand_customization)).to be true
          expect(business.has_feature?(:ai_features)).to be true
        end
      end

      context "with basic plan" do
        before do
          create(:subscription, business: business, plan: plan_basico,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns false for premium features" do
          expect(business.has_feature?(:ticket_digital)).to be false
          expect(business.has_feature?(:brand_customization)).to be false
          expect(business.has_feature?(:advanced_reports)).to be false
          expect(business.has_feature?(:ai_features)).to be false
        end
      end

      context "with professional plan" do
        before do
          create(:subscription, business: business, plan: plan_profesional,
                 status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "returns true for professional features" do
          expect(business.has_feature?(:ticket_digital)).to be true
          expect(business.has_feature?(:brand_customization)).to be true
          expect(business.has_feature?(:advanced_reports)).to be true
        end

        it "returns false for AI features" do
          expect(business.has_feature?(:ai_features)).to be false
        end
      end
    end
  end
end
