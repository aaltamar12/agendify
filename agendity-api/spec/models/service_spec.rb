require "rails_helper"

RSpec.describe Service, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:duration_minutes) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:duration_minutes).is_greater_than(0) }
  end

  describe "associations" do
    it { should belong_to(:business) }
    it { should have_many(:employee_services).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_services) }
    it { should have_many(:appointments).dependent(:restrict_with_error) }
  end
end
