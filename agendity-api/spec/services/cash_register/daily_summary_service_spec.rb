require "rails_helper"

RSpec.describe CashRegister::DailySummaryService do
  let(:business)  { create(:business) }
  let(:employee)  { create(:employee, business: business, payment_type: :commission, commission_percentage: 40) }
  let(:customer)  { create(:customer, business: business) }
  let(:service)   { create(:service, business: business, price: 25_000) }

  describe "#call" do
    context "with completed appointments" do
      before do
        create(:appointment, business: business, employee: employee, customer: customer,
               service: service, appointment_date: Date.current, status: :completed, price: 25_000)
        create(:appointment, business: business, employee: employee, customer: customer,
               service: service, appointment_date: Date.current, status: :completed, price: 30_000)
      end

      it "returns daily summary" do
        result = described_class.call(business: business, date: Date.current)
        expect(result).to be_success
        expect(result.data[:total_revenue]).to eq(55_000.0)
        expect(result.data[:total_appointments]).to eq(2)
        expect(result.data[:date]).to eq(Date.current)
      end

      it "includes employee breakdown" do
        result = described_class.call(business: business, date: Date.current)
        employees = result.data[:employees]
        expect(employees.length).to eq(1)
        expect(employees.first[:employee_id]).to eq(employee.id)
        expect(employees.first[:total_earned]).to eq(55_000.0)
        expect(employees.first[:commission_amount]).to eq(22_000.0) # 40% of 55,000
      end
    end

    context "with no appointments" do
      it "returns zero totals" do
        result = described_class.call(business: business, date: Date.current)
        expect(result).to be_success
        expect(result.data[:total_revenue]).to eq(0.0)
        expect(result.data[:total_appointments]).to eq(0)
        expect(result.data[:employees]).to be_empty
      end
    end

    context "when cash register already closed" do
      let!(:close) { create(:cash_register_close, business: business, date: Date.current, status: :closed) }

      it "reports already_closed" do
        result = described_class.call(business: business, date: Date.current)
        expect(result.data[:already_closed]).to be true
        expect(result.data[:close_id]).to eq(close.id)
      end
    end
  end
end
