require "rails_helper"

RSpec.describe "Cash Register Lifecycle", type: :model do
  include ActiveJob::TestHelper

  let(:business) { create(:business, :with_hours, timezone: "America/Bogota") }
  let(:owner)    { business.owner }
  let(:service)  { create(:service, business: business, price: 50_000, duration_minutes: 30) }
  let(:today)    { Date.current }

  let(:emp_commission) do
    create(:employee, business: business, payment_type: :commission,
           commission_percentage: 30, pending_balance: 0)
  end
  let(:emp_fixed) do
    create(:employee, business: business, payment_type: :fixed_daily,
           fixed_daily_pay: 50_000, pending_balance: 0)
  end
  let(:emp_manual) do
    create(:employee, business: business, payment_type: :manual, pending_balance: 0)
  end

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(Notifications::WhatsappChannel).to receive(:deliver)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
    allow(SiteConfig).to receive(:get).and_return(nil)
  end

  def create_completed_appointment(employee, price: 50_000)
    @slot_counter ||= 0
    hour = 8 + @slot_counter
    @slot_counter += 1
    customer = create(:customer, business: business)
    create(:appointment,
      business: business,
      employee: employee,
      service: service,
      customer: customer,
      appointment_date: today,
      start_time: format("%02d:00", hour),
      end_time: format("%02d:30", hour),
      price: price,
      status: :completed)
  end

  it "closes cash register with 3 payment types, verifies balances and reconciliation" do
    # ============================================================
    # Step 1: Create completed appointments for each employee
    # ============================================================
    # Commission employee: 2 appointments x 50,000 = 100,000 revenue
    create_completed_appointment(emp_commission)
    create_completed_appointment(emp_commission)

    # Fixed daily employee: 1 appointment x 50,000 = 50,000 revenue
    create_completed_appointment(emp_fixed)

    # Manual employee: 1 appointment x 50,000 = 50,000 revenue
    create_completed_appointment(emp_manual)

    # ============================================================
    # Step 2: Get daily summary
    # ============================================================
    summary_result = CashRegister::DailySummaryService.call(business: business, date: today)

    expect(summary_result).to be_success
    summary = summary_result.data

    expect(summary[:total_revenue]).to eq(200_000)
    expect(summary[:total_appointments]).to eq(4)

    # Verify employee breakdown
    commission_breakdown = summary[:employees].find { |e| e[:employee_id] == emp_commission.id }
    expect(commission_breakdown[:total_earned]).to eq(100_000)
    expect(commission_breakdown[:commission_amount]).to eq(30_000) # 100,000 * 30%

    fixed_breakdown = summary[:employees].find { |e| e[:employee_id] == emp_fixed.id }
    expect(fixed_breakdown[:total_earned]).to eq(50_000)
    expect(fixed_breakdown[:commission_amount]).to eq(50_000) # Fixed daily pay

    manual_breakdown = summary[:employees].find { |e| e[:employee_id] == emp_manual.id }
    expect(manual_breakdown[:total_earned]).to eq(50_000)
    expect(manual_breakdown[:commission_amount]).to eq(0) # Manual = 0 calculated

    # ============================================================
    # Step 3: Close register — pay commission and fixed in full, pay manual partially
    # ============================================================
    close_result = CashRegister::CloseService.call(
      business: business,
      user: owner,
      date: today,
      employee_payments: [
        {
          employee_id: emp_commission.id,
          appointments_count: 2,
          total_earned: 100_000,
          commission_pct: 30,
          commission_amount: 30_000,
          amount_paid: 30_000,
          payment_method: :cash
        },
        {
          employee_id: emp_fixed.id,
          appointments_count: 1,
          total_earned: 50_000,
          commission_pct: 0,
          commission_amount: 50_000,
          amount_paid: 50_000,
          payment_method: :cash
        },
        {
          employee_id: emp_manual.id,
          appointments_count: 1,
          total_earned: 50_000,
          commission_pct: 0,
          commission_amount: 0,
          amount_paid: 20_000,
          payment_method: :cash
        }
      ]
    )

    expect(close_result).to be_success
    close = close_result.data
    expect(close.status).to eq("closed")
    expect(close.total_revenue).to eq(200_000)

    # ============================================================
    # Step 4: Verify EmployeePayments created
    # ============================================================
    expect(close.employee_payments.count).to eq(3)

    commission_payment = close.employee_payments.find_by(employee: emp_commission)
    expect(commission_payment.commission_amount).to eq(30_000)
    expect(commission_payment.amount_paid).to eq(30_000)

    fixed_payment = close.employee_payments.find_by(employee: emp_fixed)
    expect(fixed_payment.commission_amount).to eq(50_000)
    expect(fixed_payment.amount_paid).to eq(50_000)

    manual_payment = close.employee_payments.find_by(employee: emp_manual)
    expect(manual_payment.amount_paid).to eq(20_000)

    # ============================================================
    # Step 5: Verify pending balances
    # ============================================================
    emp_commission.reload
    emp_fixed.reload
    emp_manual.reload

    # Commission: paid in full -> 0 pending
    expect(emp_commission.pending_balance).to eq(0)

    # Fixed: paid in full -> 0 pending
    expect(emp_fixed.pending_balance).to eq(0)

    # Manual: paid 20,000 but owed at least 20,000 (manual type uses max of paid vs prev pending)
    # Since pending_from_previous was 0 and manual type: total_owed = max(20000, 0) = 20000
    # new_pending = max(20000 - 20000, 0) = 0
    expect(emp_manual.pending_balance).to eq(0)

    # ============================================================
    # Step 6: Reconciliation should show 0 discrepancies
    # ============================================================
    recon_result = CashRegister::ReconciliationService.call(business: business)
    expect(recon_result).to be_success
    expect(recon_result.data).to be_empty

    # ============================================================
    # Step 7: Day 2 — close with partial payment to test carry forward
    # ============================================================
    day2 = today + 1.day

    # Create appointments for day 2
    create_completed_appointment(emp_commission).update!(appointment_date: day2)
    create_completed_appointment(emp_commission).update!(appointment_date: day2)

    day2_summary = CashRegister::DailySummaryService.call(business: business, date: day2)
    expect(day2_summary).to be_success
    # Commission employee: 2 x 50,000 = 100,000 revenue, commission = 30,000

    # Close with partial payment (pay only 20,000 of 30,000 owed)
    travel_to day2 do
      day2_close = CashRegister::CloseService.call(
        business: business,
        user: owner,
        date: day2,
        employee_payments: [
          {
            employee_id: emp_commission.id,
            appointments_count: 2,
            total_earned: 100_000,
            commission_pct: 30,
            commission_amount: 30_000,
            amount_paid: 20_000,
            payment_method: :cash
          }
        ]
      )

      expect(day2_close).to be_success
    end

    # Pending balance should carry forward: 30,000 - 20,000 = 10,000
    emp_commission.reload
    expect(emp_commission.pending_balance).to eq(10_000)
  end
end
