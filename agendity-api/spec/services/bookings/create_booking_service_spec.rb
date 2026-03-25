require "rails_helper"

RSpec.describe Bookings::CreateBookingService do
  let(:business) { create(:business, :with_hours, timezone: "America/Bogota") }
  let(:service)  { create(:service, business: business, price: 25_000, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business) }

  let(:tomorrow) { Date.tomorrow }

  let(:params) do
    {
      service_id: service.id,
      employee_id: employee.id,
      appointment_date: tomorrow,
      start_time: "10:00",
      customer_name: "Carlos Test",
      customer_phone: "3001234567"
    }
  end

  before do
    employee.services << service
    employee.employee_schedules.create!(day_of_week: tomorrow.wday, start_time: "08:00", end_time: "18:00")
    allow(Bookings::SlotLockService).to receive(:locked?).and_return(false)
    allow(Bookings::SlotLockService).to receive(:unlock)
  end

  describe "#call" do
    context "with valid params" do
      it "creates a booking and enqueues notification job" do
        result = described_class.call(slug: business.slug, params: params)
        expect(result).to be_success
        expect(result.data[:appointment]).to be_persisted
        expect(result.data[:business]).to eq(business)
        expect(SendNewBookingNotificationJob).to have_been_enqueued
      end
    end

    context "with unknown slug" do
      it "returns failure" do
        result = described_class.call(slug: "nonexistent-slug", params: params)
        expect(result).to be_failure
        expect(result.error_code).to eq("BUSINESS_NOT_FOUND")
      end
    end

    context "when business is inactive" do
      before { business.update_column(:status, :suspended) }

      it "returns failure" do
        result = described_class.call(slug: business.slug, params: params)
        expect(result).to be_failure
        expect(result.error_code).to eq("BUSINESS_INACTIVE")
      end
    end
  end
end
