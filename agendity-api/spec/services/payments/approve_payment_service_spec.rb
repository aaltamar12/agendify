require "rails_helper"

RSpec.describe Payments::ApprovePaymentService do
  let(:business)    { create(:business, timezone: "America/Bogota") }
  let(:customer)    { create(:customer, business: business) }
  let(:employee)    { create(:employee, business: business) }
  let(:service)     { create(:service, business: business) }

  let(:appointment) do
    create(:appointment,
      business: business,
      customer: customer,
      employee: employee,
      service: service,
      price: 25_000,
      appointment_date: Date.tomorrow,
      start_time: "14:00",
      end_time: "14:30",
      status: :payment_sent)
  end

  let(:payment) do
    create(:payment,
      appointment: appointment,
      payment_method: :transfer,
      amount: 25_000,
      status: :submitted)
  end

  subject { described_class.call(payment: payment) }

  describe "#call" do
    context "with a valid submitted payment" do
      it "returns success" do
        expect(subject).to be_success
      end

      it "approves the payment" do
        subject
        expect(payment.reload.status).to eq("approved")
      end

      it "confirms the appointment" do
        subject
        expect(appointment.reload.status).to eq("confirmed")
      end

      it "returns the payment as data" do
        result = subject
        expect(result.data).to eq(payment)
      end

      it "enqueues SendBookingConfirmedJob" do
        subject
        expect(SendBookingConfirmedJob).to have_been_enqueued.with(appointment.id)
      end

      it "creates an activity log" do
        expect { subject }.to change(ActivityLog, :count).by(1)
        log = ActivityLog.last
        expect(log.action).to eq("payment_approved")
        expect(log.metadata["payment_id"]).to eq(payment.id)
      end
    end

    context "when appointment is far enough in the future" do
      let(:appointment) do
        # Tomorrow at 14:00 — reminder at 13:30 which is in the future
        create(:appointment,
          business: business,
          customer: customer,
          employee: employee,
          service: service,
          price: 25_000,
          appointment_date: Date.tomorrow,
          start_time: "14:00",
          end_time: "14:30",
          status: :payment_sent)
      end

      it "schedules a 30-minute reminder job" do
        subject
        expect(SendAppointmentReminder30minJob).to have_been_enqueued
      end
    end

    context "when business has ticket_digital feature" do
      before do
        plan = create(:plan, ticket_digital: true)
        create(:subscription, business: business, plan: plan,
          status: :active, start_date: Date.current, end_date: 30.days.from_now)
        # Remove the existing ticket_code to test generation
        appointment.update_column(:ticket_code, nil)
      end

      it "generates a ticket_code for the appointment" do
        subject
        expect(appointment.reload.ticket_code).to be_present
      end
    end

    context "when appointment already has a ticket_code" do
      it "does not overwrite the existing ticket_code" do
        original_code = appointment.ticket_code
        subject
        expect(appointment.reload.ticket_code).to eq(original_code)
      end
    end

    context "activity log on approval" do
      it "logs payment_approved action" do
        expect { subject }.to change(ActivityLog, :count).by(1)
        log = ActivityLog.last
        expect(log.action).to eq("payment_approved")
      end
    end
  end
end
