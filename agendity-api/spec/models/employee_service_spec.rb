require "rails_helper"

RSpec.describe EmployeeService, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:employee) }
    it { is_expected.to belong_to(:service) }
  end

  describe "validations" do
    subject { create(:employee_service) }

    it { is_expected.to validate_uniqueness_of(:employee_id).scoped_to(:service_id) }
  end
end
