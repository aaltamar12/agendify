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
  end
end
