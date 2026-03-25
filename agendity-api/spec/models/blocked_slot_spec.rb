require "rails_helper"

RSpec.describe BlockedSlot, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:employee).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }
  end

  describe "scopes" do
    let(:business) { create(:business) }
    let(:employee) { create(:employee, business: business) }

    describe ".on_date" do
      let!(:today_slot)    { create(:blocked_slot, business: business, date: Date.current) }
      let!(:tomorrow_slot) { create(:blocked_slot, business: business, date: Date.tomorrow) }

      it "returns slots for the given date" do
        expect(described_class.on_date(Date.current)).to include(today_slot)
        expect(described_class.on_date(Date.current)).not_to include(tomorrow_slot)
      end
    end

    describe ".for_employee" do
      let!(:emp_slot) { create(:blocked_slot, business: business, employee: employee) }
      let!(:biz_slot) { create(:blocked_slot, business: business, employee: nil) }

      it "returns slots for the given employee" do
        expect(described_class.for_employee(employee.id)).to include(emp_slot)
        expect(described_class.for_employee(employee.id)).not_to include(biz_slot)
      end
    end

    describe ".business_wide" do
      let!(:emp_slot) { create(:blocked_slot, business: business, employee: employee) }
      let!(:biz_slot) { create(:blocked_slot, business: business, employee: nil) }

      it "returns only business-wide slots" do
        expect(described_class.business_wide).to include(biz_slot)
        expect(described_class.business_wide).not_to include(emp_slot)
      end
    end
  end
end
