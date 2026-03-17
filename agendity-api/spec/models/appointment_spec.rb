require "rails_helper"

RSpec.describe Appointment, type: :model do
  describe "validations" do
    it { should validate_presence_of(:appointment_date) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:status) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it do
      should define_enum_for(:status).with_values(
        pending_payment: 0,
        payment_sent: 1,
        confirmed: 2,
        checked_in: 3,
        cancelled: 4,
        completed: 5
      )
    end
  end

  describe "associations" do
    it { should belong_to(:business) }
    it { should belong_to(:employee) }
    it { should belong_to(:service) }
    it { should belong_to(:customer) }
    it { should have_one(:payment).dependent(:destroy) }
  end
end
