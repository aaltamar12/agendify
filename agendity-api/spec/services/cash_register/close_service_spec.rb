require "rails_helper"

RSpec.describe CashRegister::CloseService do
  let(:business) { create(:business) }
  let(:user)     { create(:user) }
  let(:employee) { create(:employee, business: business, pending_balance: 5_000) }

  let(:today) { Date.current }

  before do
    # Create completed appointments for today
    2.times do
      create(:appointment,
        business: business,
        employee: employee,
        appointment_date: today,
        status: :completed,
        price: 30_000)
    end
  end

  describe "successful close" do
    let(:employee_payments) do
      [{
        employee_id: employee.id,
        appointments_count: 2,
        total_earned: 60_000,
        commission_pct: 40,
        commission_amount: 24_000,
        amount_paid: 29_000, # 24,000 commission + 5,000 pending
        payment_method: :cash,
        notes: nil
      }]
    end

    subject do
      described_class.call(
        business: business,
        user: user,
        date: today,
        employee_payments: employee_payments,
        notes: "Cierre normal"
      )
    end

    it "returns success" do
      expect(subject).to be_success
    end

    it "creates a cash register close record" do
      expect { subject }.to change(CashRegisterClose, :count).by(1)
      close = CashRegisterClose.last
      expect(close.date).to eq(today)
      expect(close.status).to eq("closed")
      expect(close.closed_by_user).to eq(user)
      expect(close.total_revenue).to eq(60_000)
      expect(close.total_appointments).to eq(2)
      expect(close.notes).to eq("Cierre normal")
    end

    it "creates employee payment records" do
      expect { subject }.to change(EmployeePayment, :count).by(1)
      payment = EmployeePayment.last
      expect(payment.employee).to eq(employee)
      expect(payment.commission_amount).to eq(24_000)
      expect(payment.pending_from_previous).to eq(5_000)
      expect(payment.total_owed).to eq(29_000) # 24,000 + 5,000
      expect(payment.amount_paid).to eq(29_000)
    end

    it "clears employee pending_balance when fully paid" do
      subject
      expect(employee.reload.pending_balance).to eq(0)
    end
  end

  describe "partial payment (pending balance)" do
    let(:employee_payments) do
      [{
        employee_id: employee.id,
        appointments_count: 2,
        total_earned: 60_000,
        commission_pct: 40,
        commission_amount: 24_000,
        amount_paid: 20_000, # Less than owed (24,000 + 5,000 = 29,000)
        payment_method: :transfer
      }]
    end

    subject do
      described_class.call(
        business: business,
        user: user,
        date: today,
        employee_payments: employee_payments
      )
    end

    it "calculates pending_balance when paid less than owed" do
      subject
      # total_owed = 24,000 + 5,000 = 29,000
      # amount_paid = 20,000
      # new pending = 29,000 - 20,000 = 9,000
      expect(employee.reload.pending_balance).to eq(9_000)
    end
  end

  describe "cannot close future dates" do
    subject do
      described_class.call(
        business: business,
        user: user,
        date: Date.tomorrow,
        employee_payments: []
      )
    end

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("No se puede cerrar caja de un día futuro")
    end
  end

  describe "fails to close if reconciliation finds discrepancies" do
    let(:employee_payments) do
      [{
        employee_id: employee.id,
        appointments_count: 2,
        total_earned: 60_000,
        commission_pct: 40,
        commission_amount: 24_000,
        amount_paid: 29_000,
        payment_method: :cash
      }]
    end

    before do
      # Create an EmployeePayment from a previous close that leaves a debt,
      # then manually tamper with the employee's pending_balance so reconciliation
      # detects a discrepancy.
      prev_close = create(:cash_register_close,
        business: business,
        closed_by_user: user,
        date: today - 1,
        status: :closed)

      create(:employee_payment,
        cash_register_close: prev_close,
        employee: employee,
        total_owed: 10_000,
        amount_paid: 5_000)

      # pending_balance should be 5,000 from the previous payment + the factory default,
      # but we deliberately set it to 0 to create a discrepancy.
      employee.update_column(:pending_balance, 0)
    end

    subject do
      described_class.call(
        business: business,
        user: user,
        date: today,
        employee_payments: employee_payments
      )
    end

    it "returns failure with discrepancy message" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to include("inconsistencias")
      expect(result.error).to include(employee.name)
    end

    it "does not create a cash register close record" do
      expect { subject }.not_to change(CashRegisterClose.where(date: today), :count)
    end
  end

  describe "cannot close same date twice" do
    before do
      create(:cash_register_close,
        business: business,
        closed_by_user: user,
        date: today,
        status: :closed)
    end

    subject do
      described_class.call(
        business: business,
        user: user,
        date: today,
        employee_payments: []
      )
    end

    it "returns failure" do
      result = subject
      expect(result).to be_failure
      expect(result.error).to eq("Ya se cerró caja de este día")
    end
  end
end
