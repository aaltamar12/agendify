require "rails_helper"

RSpec.describe CompleteAppointmentsJob, type: :job do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:service)  { create(:service, business: business) }

  before do
    allow(Realtime::NatsPublisher).to receive(:publish)
    allow(JobConfig).to receive(:enabled?).and_return(true)
    allow(JobConfig).to receive(:record_run!)
  end

  describe "#perform" do
    context "when appointment end_time has passed" do
      let!(:past_appointment) do
        now = Time.current
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.current,
          start_time: (now - 2.hours).strftime("%H:%M"),
          end_time: (now - 1.hour).strftime("%H:%M"),
          status: :checked_in,
          price: 25_000)
      end

      let(:cashback_result) { ServiceResult.new(success: true, data: nil) }

      before do
        allow(Credits::CashbackService).to receive(:call).and_return(cashback_result)
      end

      it "marks checked_in appointments as completed" do
        described_class.perform_now
        expect(past_appointment.reload.status).to eq("completed")
      end

      it "triggers CashbackService" do
        expect(Credits::CashbackService).to receive(:call).with(appointment: past_appointment).and_return(cashback_result)
        described_class.perform_now
      end

      it "enqueues SendRatingRequestJob" do
        expect(SendRatingRequestJob).to receive(:perform_later).with(past_appointment.id)
        described_class.perform_now
      end
    end

    context "when appointment end_time has NOT passed" do
      let!(:future_appointment) do
        now = Time.current
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.current,
          start_time: (now + 1.hour).strftime("%H:%M"),
          end_time: (now + 2.hours).strftime("%H:%M"),
          status: :checked_in,
          price: 25_000)
      end

      it "does NOT mark appointment as completed" do
        described_class.perform_now
        expect(future_appointment.reload.status).to eq("checked_in")
      end
    end

    context "with appointment from a past date" do
      let!(:yesterday_appointment) do
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.yesterday,
          start_time: "10:00",
          end_time: "10:30",
          status: :checked_in,
          price: 25_000)
      end

      before do
        allow(Credits::CashbackService).to receive(:call)
          .and_return(ServiceResult.new(success: true, data: nil))
      end

      it "marks it as completed (past date)" do
        described_class.perform_now
        expect(yesterday_appointment.reload.status).to eq("completed")
      end
    end

    context "with non checked_in appointments" do
      let!(:confirmed_appointment) do
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.yesterday,
          start_time: "10:00",
          end_time: "10:30",
          status: :confirmed,
          price: 25_000)
      end

      it "does NOT process non checked_in appointments" do
        described_class.perform_now
        expect(confirmed_appointment.reload.status).to eq("confirmed")
      end
    end

    context "when cashback result has a positive amount" do
      let!(:past_appointment) do
        now = Time.current
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.current,
          start_time: (now - 2.hours).strftime("%H:%M"),
          end_time: (now - 1.hour).strftime("%H:%M"),
          status: :checked_in,
          price: 25_000)
      end

      before do
        allow(Credits::CashbackService).to receive(:call)
          .and_return(ServiceResult.new(success: true, data: 2500))
      end

      it "enqueues SendCashbackNotificationJob with the cashback amount" do
        expect(SendCashbackNotificationJob).to receive(:perform_later)
          .with(past_appointment.id, 2500.0)
        described_class.perform_now
      end
    end

    context "when cashback result has no data" do
      let!(:past_appointment) do
        now = Time.current
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.current,
          start_time: (now - 2.hours).strftime("%H:%M"),
          end_time: (now - 1.hour).strftime("%H:%M"),
          status: :checked_in,
          price: 25_000)
      end

      before do
        allow(Credits::CashbackService).to receive(:call)
          .and_return(ServiceResult.new(success: true, data: nil))
      end

      it "does NOT enqueue SendCashbackNotificationJob" do
        expect(SendCashbackNotificationJob).not_to receive(:perform_later)
        described_class.perform_now
      end
    end

    context "when appointment end_time has passed" do
      let!(:past_appointment) do
        now = Time.current
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.current,
          start_time: (now - 2.hours).strftime("%H:%M"),
          end_time: (now - 1.hour).strftime("%H:%M"),
          status: :checked_in,
          price: 25_000)
      end

      before do
        allow(Credits::CashbackService).to receive(:call)
          .and_return(ServiceResult.new(success: true, data: nil))
      end

      it "creates an activity log" do
        expect { described_class.perform_now }.to change(ActivityLog, :count).by(1)
        log = ActivityLog.last
        expect(log.action).to eq("appointment_completed")
      end

      it "publishes a NATS real-time event" do
        described_class.perform_now
        expect(Realtime::NatsPublisher).to have_received(:publish).with(
          hash_including(event: "appointment_completed", business_id: business.id)
        )
      end
    end

    context "when job is disabled" do
      before do
        allow(JobConfig).to receive(:enabled?).and_return(false)
      end

      let!(:past_appointment) do
        create(:appointment,
          business: business,
          employee: employee,
          customer: customer,
          service: service,
          appointment_date: Date.yesterday,
          start_time: "10:00",
          end_time: "10:30",
          status: :checked_in,
          price: 25_000)
      end

      it "skips processing and does not complete any appointments" do
        described_class.perform_now
        expect(past_appointment.reload.status).to eq("checked_in")
      end
    end

    context "when an error occurs during processing" do
      it "records the error and re-raises" do
        allow(Appointment).to receive(:includes).and_raise(StandardError.new("DB error"))

        expect { described_class.perform_now }.to raise_error(StandardError, "DB error")
      end
    end
  end
end
