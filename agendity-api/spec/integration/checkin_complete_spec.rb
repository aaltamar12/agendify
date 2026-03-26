require "rails_helper"

RSpec.describe "Checkin Complete", type: :model do
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
  let(:service)  { create(:service, business: business, price: 60_000, duration_minutes: 45) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:tomorrow) { Date.tomorrow }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  it "validates check-in window, completes appointment, and enqueues cashback and rating jobs" do
    # ============================================================
    # Step 1: Create confirmed appointment for 10:00
    # ============================================================
    appointment = create(:appointment, :confirmed,
      business: business,
      employee: employee,
      service: service,
      customer: customer,
      appointment_date: tomorrow,
      start_time: "10:00",
      end_time: "10:45",
      price: 60_000)

    # ============================================================
    # Step 2: Too early check-in (09:00 = 60 min before) — should fail
    # ============================================================
    too_early = Time.zone.parse("#{tomorrow} 09:00").in_time_zone("America/Bogota")

    travel_to too_early do
      early_result = Appointments::CheckinService.call(appointment: appointment)

      expect(early_result).not_to be_success
      expect(early_result.error).to include("Check-in disponible")
    end

    # Appointment should still be confirmed
    appointment.reload
    expect(appointment.status).to eq("confirmed")

    # ============================================================
    # Step 3: Valid check-in (09:30 = exactly 30 min before) — should succeed
    # ============================================================
    valid_time = Time.zone.parse("#{tomorrow} 09:30").in_time_zone("America/Bogota")

    travel_to valid_time do
      checkin_result = Appointments::CheckinService.call(appointment: appointment)

      expect(checkin_result).to be_success
      appointment.reload
      expect(appointment.status).to eq("checked_in")
      expect(appointment.checked_in_at).to be_present
    end

    # ============================================================
    # Step 4: Complete via CompleteAppointmentsJob (after end_time 10:45)
    # ============================================================
    after_end = Time.zone.parse("#{tomorrow} 10:50").in_time_zone("America/Bogota")

    travel_to after_end do
      CompleteAppointmentsJob.perform_now
    end

    appointment.reload
    expect(appointment.status).to eq("completed")

    # ============================================================
    # Step 5: Verify cashback was credited
    # ============================================================
    credit_account = CreditAccount.find_by(customer: customer, business: business)
    expect(credit_account).to be_present
    # 60,000 * 5% = 3,000
    expect(credit_account.balance).to eq(3_000)

    # ============================================================
    # Step 6: Verify SendCashbackNotificationJob was enqueued
    # ============================================================
    expect(SendCashbackNotificationJob).to have_been_enqueued.with(appointment.id, 3_000.0)

    # ============================================================
    # Step 7: Verify SendRatingRequestJob was enqueued
    # ============================================================
    expect(SendRatingRequestJob).to have_been_enqueued.with(appointment.id)
  end
end
