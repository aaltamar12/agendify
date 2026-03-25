require "rails_helper"

RSpec.describe "Discount Code Booking", type: :model do
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

  context "with a valid 10% discount code" do
    let!(:discount_code) do
      create(:discount_code,
        business: business,
        code: "SAVE10",
        discount_type: "percentage",
        discount_value: 10,
        active: true,
        max_uses: 5,
        current_uses: 0,
        valid_from: Date.current,
        valid_until: Date.current + 30.days)
    end

    it "creates an appointment with the discount applied" do
      params = base_params.merge(discount_code: "SAVE10")
      result = Appointments::CreateAppointmentService.call(business: business, params: params)

      expect(result).to be_success
      appointment = result.data[:appointment]

      # 50,000 - (50,000 * 10%) = 45,000
      expect(appointment.discount_code_id).to eq(discount_code.id)
      expect(appointment.discount_amount).to eq(5_000)
      expect(appointment.price).to eq(45_000)
    end

    it "increments current_uses on the discount code" do
      params = base_params.merge(discount_code: "SAVE10")
      Appointments::CreateAppointmentService.call(business: business, params: params)

      discount_code.reload
      expect(discount_code.current_uses).to eq(1)
    end
  end

  context "with an expired discount code" do
    let!(:expired_code) do
      create(:discount_code,
        business: business,
        code: "EXPIRED10",
        discount_type: "percentage",
        discount_value: 10,
        active: true,
        max_uses: 5,
        current_uses: 0,
        valid_from: 30.days.ago,
        valid_until: 1.day.ago)
    end

    it "does not apply the discount" do
      params = base_params.merge(discount_code: "EXPIRED10")
      result = Appointments::CreateAppointmentService.call(business: business, params: params)

      expect(result).to be_success
      appointment = result.data[:appointment]

      expect(appointment.discount_code_id).to be_nil
      expect(appointment.discount_amount).to eq(0)
      expect(appointment.price).to eq(50_000)
    end
  end

  context "with an exhausted discount code (max_uses reached)" do
    let!(:exhausted_code) do
      create(:discount_code,
        business: business,
        code: "MAXED10",
        discount_type: "percentage",
        discount_value: 10,
        active: true,
        max_uses: 3,
        current_uses: 3,
        valid_from: Date.current,
        valid_until: Date.current + 30.days)
    end

    it "does not apply the discount" do
      params = base_params.merge(discount_code: "MAXED10")
      result = Appointments::CreateAppointmentService.call(business: business, params: params)

      expect(result).to be_success
      appointment = result.data[:appointment]

      expect(appointment.discount_code_id).to be_nil
      expect(appointment.discount_amount).to eq(0)
      expect(appointment.price).to eq(50_000)
    end
  end

  context "with a customer-specific discount code for a different customer" do
    let(:other_customer) { create(:customer, business: business) }

    let!(:specific_code) do
      create(:discount_code,
        business: business,
        code: "BIRTHDAY15",
        discount_type: "percentage",
        discount_value: 15,
        active: true,
        max_uses: 1,
        current_uses: 0,
        valid_from: Date.current,
        valid_until: Date.current + 7.days,
        source: "birthday",
        customer: other_customer)
    end

    it "does not apply the discount when a different customer tries to use it" do
      params = base_params.merge(discount_code: "BIRTHDAY15")
      result = Appointments::CreateAppointmentService.call(business: business, params: params)

      expect(result).to be_success
      appointment = result.data[:appointment]

      expect(appointment.discount_code_id).to be_nil
      expect(appointment.discount_amount).to eq(0)
      expect(appointment.price).to eq(50_000)
    end
  end
end
