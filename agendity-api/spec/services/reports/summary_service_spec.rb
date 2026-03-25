require "rails_helper"

RSpec.describe Reports::SummaryService do
  let(:business) { create(:business, rating_average: 4.5) }
  let(:employee) { create(:employee, business: business) }
  let(:service)  { create(:service, business: business) }

  describe "#call" do
    context "with data" do
      let!(:customer1) { create(:customer, business: business) }
      let!(:customer2) { create(:customer, business: business) }

      before do
        create(:appointment, business: business, employee: employee, customer: customer1,
               service: service, status: :completed, price: 50_000)
        create(:appointment, business: business, employee: employee, customer: customer2,
               service: service, status: :completed, price: 30_000)
        create(:appointment, business: business, employee: employee, customer: customer1,
               service: service, status: :pending_payment, price: 25_000)
      end

      it "returns correct summary" do
        result = described_class.call(business: business)
        expect(result).to be_success
        expect(result.data[:total_revenue]).to eq(80_000.0)
        expect(result.data[:total_appointments]).to eq(3)
        expect(result.data[:total_customers]).to eq(2)
        expect(result.data[:avg_rating]).to eq(4.5)
      end
    end

    context "with no data" do
      it "returns zero values" do
        result = described_class.call(business: business)
        expect(result).to be_success
        expect(result.data[:total_revenue]).to eq(0.0)
        expect(result.data[:total_appointments]).to eq(0)
        expect(result.data[:total_customers]).to eq(0)
      end
    end
  end
end
