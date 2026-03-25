require "rails_helper"

RSpec.describe "Dynamic Pricing Booking", type: :model do
  let(:business) { create(:business, :with_hours, timezone: "America/Bogota") }
  let(:service)  { create(:service, business: business, price: 50_000, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:tomorrow) { Date.tomorrow }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsAppChannel).to receive(:deliver)

    # Create employee-service relationship and schedule
    employee.services << service
    employee.employee_schedules.create!(
      day_of_week: tomorrow.wday,
      start_time: "08:00",
      end_time: "18:00"
    )
  end

  let(:base_params) do
    {
      service_id: service.id,
      employee_id: employee.id,
      appointment_date: tomorrow,
      start_time: "10:00",
      customer_name: customer.name,
      customer_phone: customer.phone,
      customer_email: customer.email
    }
  end

  context "with an active +20% dynamic pricing" do
    let!(:pricing) do
      create(:dynamic_pricing,
        business: business,
        service: nil,
        name: "Temporada alta",
        price_adjustment_type: :percentage,
        adjustment_mode: :fixed_mode,
        adjustment_value: 20,
        start_date: Date.current,
        end_date: Date.current + 60.days,
        days_of_week: [],
        status: :active)
    end

    it "creates an appointment with the price increment applied" do
      result = Appointments::CreateAppointmentService.call(business: business, params: base_params)

      expect(result).to be_success
      appointment = result.data[:appointment]

      # 50,000 + (50,000 * 20%) = 60,000
      expect(appointment.price).to eq(60_000)
      expect(appointment.original_price).to eq(50_000)
      expect(appointment.dynamic_pricing_id).to eq(pricing.id)
    end
  end

  context "with an active -10% discount dynamic pricing" do
    let!(:pricing) do
      create(:dynamic_pricing,
        business: business,
        service: nil,
        name: "Promo baja temporada",
        price_adjustment_type: :percentage,
        adjustment_mode: :fixed_mode,
        adjustment_value: -10,
        start_date: Date.current,
        end_date: Date.current + 60.days,
        days_of_week: [],
        status: :active)
    end

    it "creates an appointment with a reduced price" do
      result = Appointments::CreateAppointmentService.call(business: business, params: base_params)

      expect(result).to be_success
      appointment = result.data[:appointment]

      # 50,000 + (50,000 * -10%) = 45,000
      expect(appointment.price).to eq(45_000)
      expect(appointment.original_price).to eq(50_000)
      expect(appointment.dynamic_pricing_id).to eq(pricing.id)
    end
  end

  context "with dynamic pricing +20% combined with discount code -10%" do
    let!(:pricing) do
      create(:dynamic_pricing,
        business: business,
        service: nil,
        name: "Temporada alta",
        price_adjustment_type: :percentage,
        adjustment_mode: :fixed_mode,
        adjustment_value: 20,
        start_date: Date.current,
        end_date: Date.current + 60.days,
        days_of_week: [],
        status: :active)
    end

    let!(:discount_code) do
      create(:discount_code,
        business: business,
        code: "COMBO10",
        discount_type: "percentage",
        discount_value: 10,
        active: true,
        max_uses: 10,
        current_uses: 0,
        valid_from: Date.current,
        valid_until: Date.current + 30.days)
    end

    it "applies dynamic pricing first, then the discount code on the adjusted price" do
      params = base_params.merge(discount_code: "COMBO10")
      result = Appointments::CreateAppointmentService.call(business: business, params: params)

      expect(result).to be_success
      appointment = result.data[:appointment]

      # Step 1: Dynamic pricing: 50,000 + (50,000 * 20%) = 60,000
      # Step 2: Discount code: 60,000 - (60,000 * 10%) = 54,000
      expect(appointment.original_price).to eq(50_000)
      expect(appointment.dynamic_pricing_id).to eq(pricing.id)
      expect(appointment.discount_code_id).to eq(discount_code.id)
      expect(appointment.discount_amount).to eq(6_000)
      expect(appointment.price).to eq(54_000)
    end
  end
end
