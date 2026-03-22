require "rails_helper"

RSpec.describe Appointments::CreateAppointmentService do
  let(:business) { create(:business, :with_hours, timezone: "America/Bogota") }
  let(:service)  { create(:service, business: business, price: 25_000, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business) }

  let(:tomorrow) { Date.tomorrow }

  let(:base_params) do
    {
      service_id: service.id,
      employee_id: employee.id,
      appointment_date: tomorrow,
      start_time: "10:00",
      customer_name: "Carlos Test",
      customer_phone: "3001234567",
      customer_email: "carlos@test.com"
    }
  end

  before do
    # Create employee-service relationship
    employee.services << service

    # Create employee schedule for tomorrow
    employee.employee_schedules.create!(
      day_of_week: tomorrow.wday,
      start_time: "08:00",
      end_time: "18:00"
    )
  end

  subject { described_class.call(business: business, params: base_params) }

  describe "dynamic pricing" do
    context "when an active pricing exists for the date" do
      let!(:pricing) do
        create(:dynamic_pricing,
          business: business,
          service: nil,
          price_adjustment_type: :percentage,
          adjustment_mode: :fixed_mode,
          adjustment_value: 20,
          start_date: Date.current,
          end_date: Date.current + 60.days,
          days_of_week: [],
          status: :active)
      end

      it "applies dynamic pricing to the appointment price" do
        result = subject
        expect(result).to be_success
        appointment = result.data[:appointment]
        # 25,000 + (25,000 * 20%) = 30,000
        expect(appointment.price).to eq(30_000)
      end

      it "stores original_price" do
        result = subject
        appointment = result.data[:appointment]
        expect(appointment.original_price).to eq(25_000)
      end

      it "stores dynamic_pricing_id" do
        result = subject
        appointment = result.data[:appointment]
        expect(appointment.dynamic_pricing_id).to eq(pricing.id)
      end
    end

    context "when a service-specific pricing exists" do
      let!(:general_pricing) do
        create(:dynamic_pricing,
          business: business,
          service: nil,
          price_adjustment_type: :percentage,
          adjustment_mode: :fixed_mode,
          adjustment_value: 10,
          start_date: Date.current,
          end_date: Date.current + 60.days,
          status: :active)
      end

      let!(:service_pricing) do
        create(:dynamic_pricing,
          business: business,
          service: service,
          price_adjustment_type: :percentage,
          adjustment_mode: :fixed_mode,
          adjustment_value: 30,
          start_date: Date.current,
          end_date: Date.current + 60.days,
          status: :active)
      end

      it "applies service-specific pricing over general pricing" do
        result = subject
        expect(result).to be_success
        appointment = result.data[:appointment]
        # Should use service-specific 30%, not general 10%
        # 25,000 + (25,000 * 30%) = 32,500
        expect(appointment.price).to eq(32_500)
        expect(appointment.dynamic_pricing_id).to eq(service_pricing.id)
      end
    end

    context "when no active pricing exists" do
      it "uses the base service price" do
        result = subject
        expect(result).to be_success
        appointment = result.data[:appointment]
        expect(appointment.price).to eq(25_000)
        expect(appointment.original_price).to be_nil
        expect(appointment.dynamic_pricing_id).to be_nil
      end
    end

    context "when pricing doesn't apply on appointment day" do
      let!(:pricing) do
        # Only applies on Sundays (wday=0) and Saturdays (wday=6)
        create(:dynamic_pricing,
          business: business,
          adjustment_value: 20,
          start_date: Date.current,
          end_date: Date.current + 60.days,
          days_of_week: [0, 6],
          status: :active)
      end

      it "does not apply pricing if day doesn't match" do
        # Find a weekday for tomorrow
        weekday_date = Date.tomorrow
        weekday_date += 1.day while [0, 6].include?(weekday_date.wday)

        # Ensure schedule exists for that day
        employee.employee_schedules.find_or_create_by!(day_of_week: weekday_date.wday) do |s|
          s.start_time = "08:00"
          s.end_time = "18:00"
        end

        params = base_params.merge(appointment_date: weekday_date)
        result = described_class.call(business: business, params: params)
        expect(result).to be_success
        expect(result.data[:appointment].price).to eq(25_000)
      end
    end
  end
end
