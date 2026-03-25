require "rails_helper"

RSpec.describe BusinessHour, type: :model do
  let(:business) { create(:business) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe "validations" do
    subject { build(:business_hour, business: business) }

    it { is_expected.to validate_presence_of(:day_of_week) }
    it { is_expected.to validate_uniqueness_of(:day_of_week).scoped_to(:business_id) }
    it { is_expected.to validate_presence_of(:open_time) }
    it { is_expected.to validate_presence_of(:close_time) }
  end

  describe "scopes" do
    before do
      create(:business_hour, business: business, day_of_week: 1, closed: false)
      create(:business_hour, business: business, day_of_week: 0, closed: true)
    end

    describe ".open_days" do
      it "returns only non-closed days" do
        expect(business.business_hours.open_days.count).to eq(1)
      end
    end

    describe ".for_day" do
      it "finds the business hour for a given day" do
        hour = business.business_hours.for_day(1)
        expect(hour).to be_present
        expect(hour.day_of_week).to eq(1)
      end

      it "returns nil for a day with no hours" do
        result = described_class.where(business: business).find_by(day_of_week: 5)
        expect(result).to be_nil
      end
    end
  end
end
