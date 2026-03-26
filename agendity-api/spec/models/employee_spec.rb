require "rails_helper"

RSpec.describe Employee, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:employee_invitations).dependent(:destroy) }
    it { is_expected.to have_many(:employee_services).dependent(:destroy) }
    it { is_expected.to have_many(:services).through(:employee_services) }
    it { is_expected.to have_many(:employee_schedules).dependent(:destroy) }
    it { is_expected.to have_many(:appointments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:blocked_slots).dependent(:destroy) }
    it { is_expected.to have_many(:employee_payments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:employee_balance_adjustments).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    context "when commission payment type" do
      subject { build(:employee, business: business, payment_type: :commission, commission_percentage: 40) }

      it { is_expected.to validate_numericality_of(:commission_percentage).is_greater_than(0).is_less_than_or_equal_to(100) }
    end

    context "when fixed_daily payment type" do
      subject { build(:employee, business: business, payment_type: :fixed_daily, fixed_daily_pay: 50_000) }

      it { is_expected.to validate_numericality_of(:fixed_daily_pay).is_greater_than(0) }
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_emp)   { create(:employee, business: business, active: true) }
      let!(:inactive_emp) { create(:employee, business: business, active: false) }

      it "returns only active employees" do
        expect(described_class.active).to include(active_emp)
        expect(described_class.active).not_to include(inactive_emp)
      end
    end
  end

  describe "callbacks" do
    it "clears commission_percentage when not commission type" do
      emp = create(:employee, business: business, payment_type: :commission, commission_percentage: 40)
      emp.update!(payment_type: :manual)
      expect(emp.reload.commission_percentage).to eq(0)
    end

    it "clears fixed_daily_pay when not fixed_daily type" do
      emp = create(:employee, business: business, payment_type: :fixed_daily, fixed_daily_pay: 50_000)
      emp.update!(payment_type: :manual)
      expect(emp.reload.fixed_daily_pay).to eq(0)
    end

    it "preserves commission_percentage when switching to commission" do
      emp = create(:employee, business: business, payment_type: :manual)
      emp.update!(payment_type: :commission, commission_percentage: 25)
      expect(emp.reload.commission_percentage).to eq(25)
    end

    it "preserves fixed_daily_pay when switching to fixed_daily" do
      emp = create(:employee, business: business, payment_type: :manual)
      emp.update!(payment_type: :fixed_daily, fixed_daily_pay: 80_000)
      expect(emp.reload.fixed_daily_pay).to eq(80_000)
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:payment_type).with_values(manual: "none", commission: "commission", fixed_daily: "fixed_daily").backed_by_column_of_type(:string) }
  end

  describe "scopes" do
    describe ".for_business" do
      it "returns employees for the given business" do
        emp = create(:employee, business: business)
        other = create(:employee) # different business
        expect(described_class.for_business(business.id)).to include(emp)
        expect(described_class.for_business(business.id)).not_to include(other)
      end
    end
  end

  describe "validations edge cases" do
    it "is invalid with zero commission_percentage for commission type" do
      emp = build(:employee, business: business, payment_type: :commission, commission_percentage: 0)
      expect(emp).not_to be_valid
      expect(emp.errors[:commission_percentage]).to be_present
    end

    it "is invalid with commission_percentage over 100" do
      emp = build(:employee, business: business, payment_type: :commission, commission_percentage: 101)
      expect(emp).not_to be_valid
      expect(emp.errors[:commission_percentage]).to be_present
    end

    it "is invalid with zero fixed_daily_pay for fixed_daily type" do
      emp = build(:employee, business: business, payment_type: :fixed_daily, fixed_daily_pay: 0)
      expect(emp).not_to be_valid
      expect(emp.errors[:fixed_daily_pay]).to be_present
    end

    it "is invalid without a name" do
      emp = build(:employee, business: business, name: nil)
      expect(emp).not_to be_valid
      expect(emp.errors[:name]).to be_present
    end
  end

  describe ".ransackable_attributes" do
    it "returns allowed attributes" do
      expect(described_class.ransackable_attributes).to include("name", "active")
    end
  end

  describe ".ransackable_associations" do
    it "returns allowed associations" do
      expect(described_class.ransackable_associations).to include("business", "services")
    end
  end
end
