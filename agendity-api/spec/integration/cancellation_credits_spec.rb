require "rails_helper"

RSpec.describe "Cancellation Credits", type: :model do
  include ActiveJob::TestHelper

  let(:plan) do
    create(:plan,
      name: "Profesional",
      price_monthly: 99_900,
      cashback_enabled: true,
      cashback_percentage: 5)
  end
  let(:business) do
    create(:business, :with_hours,
      timezone: "America/Bogota",
      cancellation_policy_pct: 50,
      cancellation_deadline_hours: 2)
  end
  let!(:subscription) { create(:subscription, business: business, plan: plan, status: :active) }
  let(:service)  { create(:service, business: business, price: 40_000, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:tomorrow) { Date.tomorrow }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
    allow(Notifications::MultiChannelService).to receive(:call).and_return(
      ServiceResult.new(success: true, data: nil)
    )
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)

    employee.services << service
    employee.employee_schedules.create!(
      day_of_week: tomorrow.wday,
      start_time: "08:00",
      end_time: "18:00"
    )
  end

  it "applies penalty, credits refund, and allows credit redemption on next booking" do
    # ============================================================
    # Step 1: Create and confirm appointment
    # ============================================================
    booking_result = Appointments::CreateAppointmentService.call(
      business: business,
      params: {
        service_id: service.id,
        employee_id: employee.id,
        appointment_date: tomorrow,
        start_time: "10:00",
        customer_name: customer.name,
        customer_phone: customer.phone,
        customer_email: customer.email
      }
    )

    expect(booking_result).to be_success
    appointment = booking_result.data[:appointment]

    # Submit and approve payment to confirm
    submit_result = Payments::SubmitPaymentService.call(
      appointment: appointment,
      payment_method: :transfer,
      amount: appointment.price
    )
    Payments::ApprovePaymentService.call(payment: submit_result.data)

    appointment.reload
    expect(appointment.status).to eq("confirmed")

    # ============================================================
    # Step 2: Cancel within deadline (penalty applies)
    # ============================================================
    # Cancel 1 hour before appointment — inside the 2-hour deadline
    cancel_time = Time.zone.parse("#{tomorrow} 09:00").in_time_zone("America/Bogota")

    cancel_result = nil
    travel_to cancel_time do
      cancel_result = Appointments::CancelAppointmentService.call(
        appointment: appointment,
        cancelled_by: "customer",
        reason: "No puedo asistir"
      )
    end

    expect(cancel_result).to be_success
    expect(cancel_result.data[:penalty_applied]).to be true
    # Penalty = 40,000 * 50% = 20,000
    expect(cancel_result.data[:penalty_amount]).to eq(20_000)

    appointment.reload
    expect(appointment.status).to eq("cancelled")

    # ============================================================
    # Step 3: Verify credit generated (price - penalty)
    # ============================================================
    credit_account = CreditAccount.find_by(customer: customer, business: business)
    expect(credit_account).to be_present
    # Refund = 40,000 - 20,000 = 20,000
    expect(credit_account.balance).to eq(20_000)

    refund_tx = credit_account.credit_transactions.find_by(transaction_type: :cancellation_refund)
    expect(refund_tx).to be_present
    expect(refund_tx.amount).to eq(20_000)

    # ============================================================
    # Step 4: Create new booking applying credits
    # ============================================================
    # Need a different day to avoid conflict
    day_after = tomorrow + 1.day
    employee.employee_schedules.create!(
      day_of_week: day_after.wday,
      start_time: "08:00",
      end_time: "18:00"
    )

    new_booking_result = Appointments::CreateAppointmentService.call(
      business: business,
      params: {
        service_id: service.id,
        employee_id: employee.id,
        appointment_date: day_after,
        start_time: "10:00",
        customer_name: customer.name,
        customer_phone: customer.phone,
        customer_email: customer.email,
        apply_credits: 20_000
      }
    )

    expect(new_booking_result).to be_success
    new_appointment = new_booking_result.data[:appointment]

    # Price reduced by credits: 40,000 - 20,000 = 20,000
    expect(new_appointment.credits_applied).to eq(20_000)
    expect(new_appointment.price).to eq(20_000)

    # Credit account balance should be 0
    credit_account.reload
    expect(credit_account.balance).to eq(0)
  end
end
