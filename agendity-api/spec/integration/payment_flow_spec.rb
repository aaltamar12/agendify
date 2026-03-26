require "rails_helper"

RSpec.describe "Payment Flow", type: :model do
  include ActiveJob::TestHelper

  let(:business) { create(:business, :with_hours, timezone: "America/Bogota") }
  let(:service)  { create(:service, business: business, price: 35_000, duration_minutes: 30) }
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

  def create_pending_appointment(start_time: "10:00")
    result = Appointments::CreateAppointmentService.call(
      business: business,
      params: {
        service_id: service.id,
        employee_id: employee.id,
        appointment_date: tomorrow,
        start_time: start_time,
        customer_name: customer.name,
        customer_phone: customer.phone,
        customer_email: customer.email
      }
    )
    expect(result).to be_success
    result.data[:appointment]
  end

  it "completes the full P2P payment approval flow" do
    # ============================================================
    # Step 1: Create appointment (pending_payment)
    # ============================================================
    appointment = create_pending_appointment
    expect(appointment.status).to eq("pending_payment")

    # ============================================================
    # Step 2: Submit payment with proof
    # ============================================================
    submit_result = Payments::SubmitPaymentService.call(
      appointment: appointment,
      payment_method: :transfer,
      amount: appointment.price,
      proof_image_url: "https://example.com/comprobante.jpg"
    )

    expect(submit_result).to be_success
    payment = submit_result.data

    expect(payment.status).to eq("submitted")
    expect(payment.payment_method).to eq("transfer")
    expect(payment.amount).to eq(35_000)
    expect(payment.proof_image_url).to eq("https://example.com/comprobante.jpg")

    appointment.reload
    expect(appointment.status).to eq("payment_sent")

    # ============================================================
    # Step 3: Approve payment
    # ============================================================
    approve_result = Payments::ApprovePaymentService.call(payment: payment)

    expect(approve_result).to be_success

    payment.reload
    appointment.reload

    expect(payment.status).to eq("approved")
    expect(appointment.status).to eq("confirmed")

    # Verify SendBookingConfirmedJob was enqueued
    expect(SendBookingConfirmedJob).to have_been_enqueued.with(appointment.id)
  end

  it "handles payment rejection and allows retry" do
    # ============================================================
    # Step 1: Create appointment and submit payment
    # ============================================================
    appointment = create_pending_appointment(start_time: "11:00")

    submit_result = Payments::SubmitPaymentService.call(
      appointment: appointment,
      payment_method: :transfer,
      amount: appointment.price,
      proof_image_url: "https://example.com/proof_blurry.jpg"
    )

    expect(submit_result).to be_success
    payment = submit_result.data

    # ============================================================
    # Step 2: Reject payment with reason
    # ============================================================
    reject_result = Payments::RejectPaymentService.call(
      payment: payment,
      reason: "El comprobante está borroso, por favor envía uno más claro"
    )

    expect(reject_result).to be_success

    payment.reload
    appointment.reload

    expect(payment.status).to eq("rejected")
    expect(payment.rejection_reason).to eq("El comprobante está borroso, por favor envía uno más claro")
    expect(payment.rejected_at).to be_present

    # Appointment reverts to pending_payment for retry
    expect(appointment.status).to eq("pending_payment")

    # ============================================================
    # Step 3: Verify notification was sent to customer
    # ============================================================
    expect(Notifications::MultiChannelService).to have_received(:call).with(
      hash_including(
        template: :payment_rejected,
        recipient: customer
      )
    )
  end
end
