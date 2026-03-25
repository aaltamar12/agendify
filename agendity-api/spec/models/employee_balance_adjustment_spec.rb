require "rails_helper"

RSpec.describe EmployeeBalanceAdjustment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:employee) }
    it { is_expected.to belong_to(:performed_by_user).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:amount).is_other_than(0) }
    it { is_expected.to validate_presence_of(:reason) }
  end

  describe "scopes" do
    let(:business) { create(:business) }
    let(:employee) { create(:employee, business: business) }
    let(:user) { create(:user) }

    describe ".for_employee" do
      let!(:adj1) { create(:employee_balance_adjustment, business: business, employee: employee, performed_by_user: user) }
      let!(:adj2) { create(:employee_balance_adjustment, business: business, employee: create(:employee, business: business), performed_by_user: user) }

      it "returns adjustments for the given employee" do
        expect(described_class.for_employee(employee.id)).to include(adj1)
        expect(described_class.for_employee(employee.id)).not_to include(adj2)
      end
    end

    describe ".chronological" do
      it "returns adjustments in ascending order" do
        old = create(:employee_balance_adjustment, business: business, employee: employee, performed_by_user: user, created_at: 1.day.ago)
        new_adj = create(:employee_balance_adjustment, business: business, employee: employee, performed_by_user: user)
        expect(described_class.chronological.first).to eq(old)
      end
    end
  end
end
