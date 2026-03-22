require "rails_helper"

RSpec.describe Appointments::CancelAppointmentService do
  let(:business) do
    create(:business,
      cancellation_policy_pct: 20,
      cancellation_deadline_hours: 2,
      timezone: "America/Bogota")
  end
  let(:customer) { create(:customer, business: business, pending_penalty: 0) }
  let(:employee) { create(:employee, business: business) }
  let(:service)  { create(:service, business: business, price: 40_000) }

  let(:appointment) do
    create(:appointment,
      business: business,
      customer: customer,
      employee: employee,
      service: service,
      price: 40_000,
      appointment_date: Date.tomorrow,
      start_time: "14:00",
      end_time: "14:30",
      status: :confirmed)
  end

  let(:plan_with_cashback) do
    create(:plan, name: "Profesional", cashback_enabled: true, cashback_percentage: 5)
  end

  let(:plan_without_cashback) do
    create(:plan, name: "Básico", cashback_enabled: false, cashback_percentage: 0)
  end

  before do
    # Stub notification jobs
    allow(SendBookingCancelledJob).to receive(:perform_later)
  end

  describe "business cancellation" do
    subject do
      described_class.call(
        appointment: appointment,
        cancelled_by: "business",
        reason: "Barbero no disponible"
      )
    end

    it "cancels the appointment without penalty" do
      result = subject
      expect(result).to be_success
      expect(result.data[:penalty_applied]).to be false
      expect(result.data[:penalty_amount]).to eq(0)
      expect(appointment.reload.status).to eq("cancelled")
      expect(appointment.cancelled_by).to eq("business")
    end

    it "does not change customer pending_penalty" do
      expect { subject }.not_to change { customer.reload.pending_penalty }
    end

    it "does not create credits" do
      create(:subscription, business: business, plan: plan_with_cashback,
        status: :active, start_date: Date.current, end_date: 30.days.from_now)
      expect { subject }.not_to change(CreditTransaction, :count)
    end
  end

  describe "customer cancellation" do
    subject do
      described_class.call(
        appointment: appointment,
        cancelled_by: "customer",
        reason: "No puedo ir"
      )
    end

    context "before the deadline (no penalty)" do
      # appointment is tomorrow at 14:00, deadline is 2 hours before
      # so cancelling now (today) is well before deadline

      it "cancels without penalty" do
        result = subject
        expect(result).to be_success
        expect(result.data[:penalty_applied]).to be false
        expect(result.data[:penalty_amount]).to eq(0)
      end
    end

    context "after the deadline (penalty applies)" do
      let(:appointment) do
        # Set appointment to 30 minutes from now (within 2-hour deadline)
        now = Time.current.in_time_zone("America/Bogota")
        create(:appointment,
          business: business,
          customer: customer,
          employee: employee,
          service: service,
          price: 40_000,
          appointment_date: now.to_date,
          start_time: (now + 30.minutes).strftime("%H:%M"),
          end_time: (now + 60.minutes).strftime("%H:%M"),
          status: :confirmed)
      end

      context "when plan has cashback (uses RefundService)" do
        before do
          create(:subscription, business: business, plan: plan_with_cashback,
            status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "uses Credits::RefundService instead of pending_penalty" do
          expect(Credits::RefundService).to receive(:call).with(appointment: appointment).and_call_original
          subject
        end

        it "creates credit transaction for the refund" do
          expect { subject }.to change(CreditTransaction, :count).by(1)
          tx = CreditTransaction.last
          expect(tx.transaction_type).to eq("cancellation_refund")
        end

        it "does not change pending_penalty on customer" do
          expect { subject }.not_to change { customer.reload.pending_penalty }
        end
      end

      context "when plan has no cashback (legacy pending_penalty)" do
        before do
          create(:subscription, business: business, plan: plan_without_cashback,
            status: :active, start_date: Date.current, end_date: 30.days.from_now)
        end

        it "adds penalty to customer pending_penalty" do
          result = subject
          expect(result).to be_success
          expect(result.data[:penalty_applied]).to be true
          # penalty = 40,000 * 20% = 8,000
          expect(result.data[:penalty_amount]).to eq(8_000)
          expect(customer.reload.pending_penalty).to eq(8_000)
        end

        it "does not create credit transactions" do
          expect { subject }.not_to change(CreditTransaction, :count)
        end
      end

      context "when business has no subscription (trial)" do
        it "adds penalty to customer pending_penalty" do
          result = subject
          expect(result).to be_success
          expect(result.data[:penalty_applied]).to be true
          expect(customer.reload.pending_penalty).to eq(8_000)
        end
      end
    end

    context "when cancellation_policy_pct is 0" do
      let(:business) do
        create(:business,
          cancellation_policy_pct: 0,
          cancellation_deadline_hours: 2,
          timezone: "America/Bogota")
      end

      it "never applies penalty" do
        result = subject
        expect(result.data[:penalty_amount]).to eq(0)
        expect(result.data[:penalty_applied]).to be false
      end
    end
  end

  describe "already cancelled or completed appointment" do
    it "returns failure for already cancelled" do
      appointment.update!(status: :cancelled)
      result = described_class.call(appointment: appointment, cancelled_by: "business")
      expect(result).to be_failure
      expect(result.error).to include("cannot be cancelled")
    end

    it "returns failure for completed" do
      appointment.update!(status: :completed)
      result = described_class.call(appointment: appointment, cancelled_by: "business")
      expect(result).to be_failure
    end
  end

  it "enqueues SendBookingCancelledJob" do
    expect(SendBookingCancelledJob).to receive(:perform_later).with(appointment.id)
    described_class.call(appointment: appointment, cancelled_by: "business")
  end
end
