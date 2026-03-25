require "rails_helper"

RSpec.describe Plan, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:subscriptions).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { build(:plan) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:price_monthly) }
    it { is_expected.to validate_numericality_of(:price_monthly).is_greater_than_or_equal_to(0) }
  end
end
