require "rails_helper"

RSpec.describe EmployeeSchedule, type: :model do
  let(:employee) { create(:employee) }

  describe "associations" do
    it { is_expected.to belong_to(:employee) }
  end

  describe "validations" do
    subject { build(:employee_schedule, employee: employee) }

    it { is_expected.to validate_presence_of(:day_of_week) }
    it { is_expected.to validate_uniqueness_of(:day_of_week).scoped_to(:employee_id) }
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }
  end
end
