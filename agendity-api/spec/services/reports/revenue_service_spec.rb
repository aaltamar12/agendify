require "rails_helper"

RSpec.describe Reports::RevenueService do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }

  describe "#call" do
    context "with completed appointments" do
      before do
        create(:appointment, business: business, employee: employee, customer: customer,
               service: service, status: :completed, price: 50_000,
               appointment_date: 5.days.ago.to_date)
        create(:appointment, business: business, employee: employee, customer: customer,
               service: service, status: :completed, price: 30_000,
               appointment_date: 3.days.ago.to_date)
      end

      it "returns revenue grouped by date for week period" do
        result = described_class.call(business: business, period: "week")
        expect(result).to be_success
        expect(result.data).to be_an(Array)
        total = result.data.sum { |d| d[:revenue] }
        expect(total).to eq(80_000.0)
      end

      it "returns revenue for month period" do
        result = described_class.call(business: business, period: "month")
        expect(result).to be_success
        expect(result.data.length).to eq(2) # 2 different dates
      end
    end

    context "with invalid period" do
      it "returns failure" do
        result = described_class.call(business: business, period: "decade")
        expect(result).to be_failure
        expect(result.error).to include("Invalid period")
      end
    end

    context "with no appointments" do
      it "returns empty array" do
        result = described_class.call(business: business, period: "month")
        expect(result).to be_success
        expect(result.data).to be_empty
      end
    end
  end
end
