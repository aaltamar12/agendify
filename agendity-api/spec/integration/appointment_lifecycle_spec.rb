require "rails_helper"

RSpec.describe "Appointment Lifecycle", type: :model do
  include ActiveJob::TestHelper

  let(:plan) do
    create(:plan,
      name: "Profesional",
      price_monthly: 99_900,
      cashback_enabled: true,
      cashback_percentage: 5,
      ticket_digital: true)
  end
  let(:business) { create(:business, :with_hours, timezone: "America/Bogota") }
  let!(:subscription) { create(:subscription, business: business, plan: plan, status: :active) }
  let(:service)  { create(:service, business: business, price: 50_000, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:tomorrow) { Date.tomorrow }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
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

  it "completes the full lifecycle: booking -> payment -> checkin -> complete -> cashback" do
    # ============================================================
    # Step 1: Create appointment via CreateAppointmentService
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
    expect(appointment.status).to eq("pending_payment")

    # ============================================================
    # Step 2: Submit payment proof
    # ============================================================
    submit_result = Payments::SubmitPaymentService.call(
      appointment: appointment,
      payment_method: :transfer,
      amount: appointment.price,
      proof_image_url: "https://example.com/proof.jpg"
    )

    expect(submit_result).to be_success
    payment = submit_result.data
    expect(payment.status).to eq("submitted")

    appointment.reload
    expect(appointment.status).to eq("payment_sent")

    # ============================================================
    # Step 3: Approve payment
    # ============================================================
    approve_result = Payments::ApprovePaymentService.call(payment: payment)

    expect(approve_result).to be_success

    appointment.reload
    expect(appointment.status).to eq("confirmed")
    expect(appointment.ticket_code).to be_present

    # ============================================================
    # Step 4: Check-in (within 30 min window)
    # ============================================================
    checkin_time = Time.zone.parse("#{tomorrow} 09:45").in_time_zone("America/Bogota")

    travel_to checkin_time do
      checkin_result = Appointments::CheckinService.call(appointment: appointment)

      expect(checkin_result).to be_success
      appointment.reload
      expect(appointment.status).to eq("checked_in")
      expect(appointment.checked_in_at).to be_present
    end

    # ============================================================
    # Step 5: Complete via CompleteAppointmentsJob (after end_time)
    # ============================================================
    after_end_time = Time.zone.parse("#{tomorrow} 10:45").in_time_zone("America/Bogota")

    travel_to after_end_time do
      CompleteAppointmentsJob.perform_now
    end

    appointment.reload
    expect(appointment.status).to eq("completed")

    # ============================================================
    # Step 6: Verify cashback credited
    # ============================================================
    credit_account = CreditAccount.find_by(customer: customer, business: business)
    expect(credit_account).to be_present
    # 50,000 * 5% = 2,500
    expect(credit_account.balance).to eq(2_500)

    cashback_tx = credit_account.credit_transactions.find_by(transaction_type: :cashback)
    expect(cashback_tx).to be_present
    expect(cashback_tx.amount).to eq(2_500)

    # ============================================================
    # Step 7: Verify SendRatingRequestJob was enqueued
    # ============================================================
    expect(SendRatingRequestJob).to have_been_enqueued.with(appointment.id)
  end
end
