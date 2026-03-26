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

    # Stub slot lock service
    allow(Bookings::SlotLockService).to receive(:locked?).and_return(false)
    allow(Bookings::SlotLockService).to receive(:unlock)
  end

  subject { described_class.call(business: business, params: base_params) }

  describe "happy path" do
    it "creates an appointment successfully" do
      result = subject
      expect(result).to be_success
      appointment = result.data[:appointment]
      expect(appointment).to be_persisted
      expect(appointment.service).to eq(service)
      expect(appointment.employee).to eq(employee)
      expect(appointment.price).to eq(25_000)
      expect(appointment.appointment_date).to eq(tomorrow)
      expect(appointment.start_time.strftime("%H:%M")).to eq("10:00")
      expect(appointment.end_time.strftime("%H:%M")).to eq("10:30")
    end

    it "creates a customer record" do
      expect { subject }.to change(Customer, :count).by(1)
      customer = Customer.last
      expect(customer.name).to eq("Carlos Test")
      expect(customer.phone).to eq("3001234567")
      expect(customer.email).to eq("carlos@test.com")
    end

    it "finds existing customer by email" do
      existing = create(:customer, business: business, email: "carlos@test.com", name: "Carlos Existing", phone: "3009999999")
      expect { subject }.not_to change(Customer, :count)
      appointment = subject.data[:appointment]
      expect(appointment.customer).to eq(existing)
    end

    it "generates a ticket_code" do
      result = subject
      expect(result.data[:appointment].ticket_code).to be_present
    end

    it "creates an activity log" do
      expect { subject }.to change(ActivityLog, :count).by(1)
      log = ActivityLog.last
      expect(log.action).to eq("booking_created")
    end

    it "sets status to pending_payment by default" do
      result = subject
      expect(result.data[:appointment].status).to eq("pending_payment")
    end
  end

  describe "validation errors" do
    context "when booking in the past" do
      let(:base_params) do
        {
          service_id: service.id,
          employee_id: employee.id,
          appointment_date: Date.yesterday,
          start_time: "10:00",
          customer_name: "Carlos Test",
          customer_phone: "3001234567"
        }
      end

      it "returns failure with SLOT_IN_PAST code" do
        result = subject
        expect(result).to be_failure
        expect(result.error_code).to eq("SLOT_IN_PAST")
      end
    end

    context "when business is closed on that day" do
      it "returns failure with BUSINESS_CLOSED code" do
        # Sunday is closed in :with_hours trait
        sunday = Date.tomorrow
        sunday += 1.day until sunday.wday == 0
        params = base_params.merge(appointment_date: sunday)
        result = described_class.call(business: business, params: params)
        expect(result).to be_failure
        expect(result.error_code).to eq("BUSINESS_CLOSED")
      end
    end

    context "when service does not exist" do
      it "returns failure with SERVICE_NOT_FOUND code" do
        params = base_params.merge(service_id: 0)
        result = described_class.call(business: business, params: params)
        expect(result).to be_failure
        expect(result.error_code).to eq("SERVICE_NOT_FOUND")
      end
    end

    context "when employee does not exist" do
      it "returns failure with NO_EMPLOYEE_AVAILABLE code" do
        params = base_params.merge(employee_id: 0)
        result = described_class.call(business: business, params: params)
        expect(result).to be_failure
        expect(result.error_code).to eq("NO_EMPLOYEE_AVAILABLE")
      end
    end

    context "when employee cannot perform the service" do
      let(:other_employee) { create(:employee, business: business) }

      before do
        other_employee.employee_schedules.create!(
          day_of_week: tomorrow.wday,
          start_time: "08:00",
          end_time: "18:00"
        )
      end

      it "returns failure with EMPLOYEE_SERVICE_MISMATCH code" do
        params = base_params.merge(employee_id: other_employee.id)
        result = described_class.call(business: business, params: params)
        expect(result).to be_failure
        expect(result.error_code).to eq("EMPLOYEE_SERVICE_MISMATCH")
      end
    end

    context "when slot is already taken" do
      before do
        create(:appointment,
          business: business,
          employee: employee,
          appointment_date: tomorrow,
          start_time: "10:00",
          end_time: "10:30",
          status: :confirmed)
      end

      it "returns failure with SLOT_TAKEN code" do
        result = subject
        expect(result).to be_failure
        expect(result.error_code).to eq("SLOT_TAKEN")
      end
    end

    context "when slot is blocked" do
      before do
        create(:blocked_slot,
          business: business,
          employee: employee,
          date: tomorrow,
          start_time: "09:30",
          end_time: "10:30")
      end

      it "returns failure with SLOT_BLOCKED code" do
        result = subject
        expect(result).to be_failure
        expect(result.error_code).to eq("SLOT_BLOCKED")
      end
    end
  end

  describe "auto-assign employee" do
    let(:base_params) do
      {
        service_id: service.id,
        employee_id: nil,
        appointment_date: tomorrow,
        start_time: "10:00",
        customer_name: "Carlos Test",
        customer_phone: "3001234567"
      }
    end

    it "assigns an available employee when employee_id is blank" do
      result = subject
      expect(result).to be_success
      expect(result.data[:appointment].employee).to eq(employee)
    end

    context "when no employees are available" do
      before do
        create(:appointment,
          business: business,
          employee: employee,
          appointment_date: tomorrow,
          start_time: "10:00",
          end_time: "10:30",
          status: :confirmed)
      end

      it "returns failure with NO_EMPLOYEE_AVAILABLE code" do
        result = subject
        expect(result).to be_failure
        expect(result.error_code).to eq("NO_EMPLOYEE_AVAILABLE")
      end
    end
  end

  describe "penalty from previous cancellations" do
    let(:customer) { create(:customer, business: business, email: "carlos@test.com", pending_penalty: 5_000) }

    before { customer } # ensure customer exists before the service runs

    it "adds pending penalty to the price and resets it" do
      result = subject
      expect(result).to be_success
      expect(result.data[:appointment].price).to eq(30_000) # 25,000 + 5,000 penalty
      expect(result.data[:penalty_applied]).to eq(5_000)
      expect(customer.reload.pending_penalty).to eq(0)
    end
  end

  describe "discount codes" do
    let!(:discount) do
      create(:discount_code,
        business: business,
        code: "SAVE10",
        discount_type: "percentage",
        discount_value: 10,
        active: true)
    end

    it "applies a valid discount code" do
      params = base_params.merge(discount_code: "SAVE10")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      appointment = result.data[:appointment]
      expect(appointment.discount_code_id).to eq(discount.id)
      expect(appointment.discount_amount).to be > 0
    end

    it "ignores an invalid discount code" do
      params = base_params.merge(discount_code: "INVALID")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      appointment = result.data[:appointment]
      expect(appointment.discount_code_id).to be_nil
      expect(appointment.discount_amount).to eq(0)
    end
  end

  describe "credits" do
    let(:customer) { create(:customer, business: business, email: "carlos@test.com") }

    before do
      customer
      business.update!(credits_enabled: true)
      CreditAccount.create!(customer: customer, business: business, balance: 50_000)
    end

    it "applies credits when requested" do
      params = base_params.merge(apply_credits: "10000")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      appointment = result.data[:appointment]
      expect(appointment.credits_applied).to eq(10_000)
      expect(appointment.price).to eq(15_000) # 25,000 - 10,000
    end

    it "auto-confirms when credits cover full price" do
      params = base_params.merge(apply_credits: "25000")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      appointment = result.data[:appointment]
      expect(appointment.status).to eq("confirmed")
      expect(appointment.credits_applied).to eq(25_000)
      expect(appointment.price).to eq(0)
    end

    it "does not apply more credits than the balance" do
      params = base_params.merge(apply_credits: "999999")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      appointment = result.data[:appointment]
      # Should cap at min(999999, 50000 balance, 25000 price) = 25,000
      expect(appointment.credits_applied).to eq(25_000)
    end

    it "does not apply credits when business has credits_enabled false" do
      business.update!(credits_enabled: false)
      params = base_params.merge(apply_credits: "10000")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      expect(result.data[:appointment].credits_applied).to eq(0)
    end
  end

  describe "additional services" do
    let(:extra_service) { create(:service, business: business, price: 10_000, duration_minutes: 15) }

    it "adds additional services to the appointment" do
      params = base_params.merge(additional_service_ids: [extra_service.id])
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      appointment = result.data[:appointment]
      expect(appointment.appointment_services.count).to eq(1)
      expect(appointment.end_time.strftime("%H:%M")).to eq("10:45") # 30 + 15 min
      expect(appointment.price).to eq(35_000) # 25,000 + 10,000
    end
  end

  describe "lock token release" do
    it "releases the slot lock when lock_token is provided" do
      expect(Bookings::SlotLockService).to receive(:unlock).with(
        hash_including(token: "my-lock-token")
      )
      result = described_class.call(business: business, params: base_params, lock_token: "my-lock-token")
      expect(result).to be_success
    end

    it "does not attempt unlock when lock_token is blank" do
      expect(Bookings::SlotLockService).not_to receive(:unlock)
      result = described_class.call(business: business, params: base_params, lock_token: nil)
      expect(result).to be_success
    end
  end

  describe "customer with birth_date" do
    let(:customer) { create(:customer, business: business, email: "carlos@test.com", birth_date: nil) }

    before { customer }

    it "updates birth_date when provided and not yet set" do
      params = base_params.merge(customer_birth_date: "1990-05-15")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      expect(customer.reload.birth_date.to_s).to eq("1990-05-15")
    end
  end

  describe "customer-specific discount code" do
    let(:other_customer) { create(:customer, business: business, email: "other@test.com") }
    let!(:discount) do
      create(:discount_code,
        business: business,
        code: "VIP10",
        discount_type: "percentage",
        discount_value: 10,
        active: true,
        customer: other_customer)
    end

    it "rejects discount code assigned to a different customer" do
      params = base_params.merge(discount_code: "VIP10")
      result = described_class.call(business: business, params: params)
      expect(result).to be_success
      appointment = result.data[:appointment]
      expect(appointment.discount_code_id).to be_nil
    end
  end

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
