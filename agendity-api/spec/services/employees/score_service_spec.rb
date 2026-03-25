require "rails_helper"

RSpec.describe Employees::ScoreService do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }

  describe "#call" do
    context "with completed appointments and reviews" do
      before do
        3.times do
          apt = create(:appointment, business: business, employee: employee,
                       customer: customer, service: service, status: :completed)
          create(:review, business: business, customer: customer, appointment: apt, employee: employee, rating: 4)
        end
      end

      it "returns success with score data" do
        result = described_class.call(employee: employee)
        expect(result).to be_success
        expect(result.data[:rating_avg]).to eq(4.0)
        expect(result.data[:completed_appointments]).to eq(3)
        expect(result.data[:overall]).to be_between(0, 100)
      end
    end

    context "with no data" do
      it "returns default values" do
        result = described_class.call(employee: employee)
        expect(result).to be_success
        expect(result.data[:rating_avg]).to eq(0)
        expect(result.data[:completed_appointments]).to eq(0)
        expect(result.data[:total_revenue]).to eq(0)
      end
    end
  end
end
