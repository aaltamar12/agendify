require "rails_helper"

RSpec.describe Bookings::AvailabilityService do
  let(:business) { create(:business, :with_hours, timezone: "America/Bogota", slot_interval_minutes: 30) }
  let(:service)  { create(:service, business: business, duration_minutes: 30) }
  let(:employee) { create(:employee, business: business) }

  # Use a future Monday (wday=1) to ensure not Sunday (closed)
  let(:target_date) do
    date = Date.tomorrow
    date += 1.day until date.wday == 1
    date
  end

  before do
    employee.services << service
    employee.employee_schedules.create!(day_of_week: target_date.wday, start_time: "08:00", end_time: "18:00")
    allow(Bookings::SlotLockService).to receive(:locked?).and_return(false)
  end

  describe "#call" do
    context "with valid service and available employee" do
      it "returns available time slots" do
        result = described_class.call(business: business, service_id: service.id, date: target_date)
        expect(result).to be_success
        expect(result.data).to be_an(Array)
        expect(result.data.any? { |s| s[:available] }).to be true
      end
    end

    context "when service does not exist" do
      it "returns failure" do
        result = described_class.call(business: business, service_id: 0, date: target_date)
        expect(result).to be_failure
        expect(result.error).to eq("Service not found")
      end
    end

    context "when no employees available" do
      before { employee.update!(active: false) }

      it "returns failure" do
        result = described_class.call(business: business, service_id: service.id, date: target_date)
        expect(result).to be_failure
        expect(result.error).to include("No employees available")
      end
    end

    context "when business is closed on that day" do
      it "returns empty slots" do
        # Sunday is closed in :with_hours trait
        sunday = Date.tomorrow
        sunday += 1.day until sunday.wday == 0
        employee.employee_schedules.create!(day_of_week: 0, start_time: "08:00", end_time: "18:00")
        result = described_class.call(business: business, service_id: service.id, date: sunday)
        expect(result).to be_success
        expect(result.data).to eq([])
      end
    end

    context "with specific employee" do
      it "only checks that employee" do
        result = described_class.call(business: business, service_id: service.id, date: target_date, employee_id: employee.id)
        expect(result).to be_success
        expect(result.data).to be_an(Array)
      end
    end

    context "when slot is blocked" do
      before do
        create(:blocked_slot, business: business, employee: employee, date: target_date, start_time: "10:00", end_time: "11:00")
      end

      it "marks blocked slots as unavailable" do
        result = described_class.call(business: business, service_id: service.id, date: target_date, employee_id: employee.id)
        slot_10 = result.data.find { |s| s[:time] == "10:00" }
        expect(slot_10[:available]).to be false
      end
    end
  end
end
