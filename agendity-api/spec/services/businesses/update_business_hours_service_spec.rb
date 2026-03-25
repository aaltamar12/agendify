require "rails_helper"

RSpec.describe Businesses::UpdateBusinessHoursService do
  let(:business) { create(:business) }

  describe "#call" do
    context "with valid hours data" do
      let(:params) do
        ActionController::Parameters.new(
          business_hours: [
            ActionController::Parameters.new(day_of_week: 1, open_time: "09:00", close_time: "17:00", closed: false),
            ActionController::Parameters.new(day_of_week: 2, open_time: "09:00", close_time: "17:00", closed: false)
          ]
        )
      end

      it "creates business hours" do
        result = described_class.call(business: business, params: params)
        expect(result).to be_success
        expect(business.business_hours.count).to eq(2)
      end

      it "updates existing hours" do
        create(:business_hour, business: business, day_of_week: 1, open_time: "08:00", close_time: "18:00")
        result = described_class.call(business: business, params: params)
        expect(result).to be_success
        expect(business.business_hours.find_by(day_of_week: 1).open_time.strftime("%H:%M")).to eq("09:00")
      end
    end

    context "with blank hours data" do
      it "returns failure" do
        params = ActionController::Parameters.new(business_hours: nil)
        result = described_class.call(business: business, params: params)
        expect(result).to be_failure
        expect(result.error).to eq("No business hours provided")
      end
    end
  end
end
