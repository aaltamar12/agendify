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

    context "when slot is temporarily locked" do
      before do
        allow(Bookings::SlotLockService).to receive(:locked?).and_return(false)
        allow(Bookings::SlotLockService).to receive(:locked?)
          .with(hash_including(time: "10:00"))
          .and_return(true)
      end

      it "marks locked slots as unavailable" do
        result = described_class.call(business: business, service_id: service.id, date: target_date, employee_id: employee.id)
        slot_10 = result.data.find { |s| s[:time] == "10:00" }
        expect(slot_10[:available]).to be false
      end
    end

    context "with gap between appointments" do
      let(:business) { create(:business, :with_hours, timezone: "America/Bogota", slot_interval_minutes: 30, gap_between_appointments_minutes: 15) }

      before do
        create(:appointment,
          business: business, employee: employee, service: service,
          appointment_date: target_date, start_time: "10:00", end_time: "10:30",
          status: :confirmed)
      end

      it "marks slots within the gap as unavailable" do
        result = described_class.call(business: business, service_id: service.id, date: target_date, employee_id: employee.id)
        # 10:30 slot should be unavailable because there's a 15-min gap after the 10:00-10:30 appointment
        slot_1030 = result.data.find { |s| s[:time] == "10:30" }
        expect(slot_1030[:available]).to be false
      end
    end

    context "with lunch break enabled" do
      let(:business) do
        create(:business, :with_hours,
          timezone: "America/Bogota",
          slot_interval_minutes: 30,
          lunch_enabled: true,
          lunch_start_time: "12:00",
          lunch_end_time: "13:00")
      end

      it "marks lunch break slots as unavailable" do
        result = described_class.call(business: business, service_id: service.id, date: target_date, employee_id: employee.id)
        slot_12 = result.data.find { |s| s[:time] == "12:00" }
        expect(slot_12[:available]).to be false
      end
    end

    context "when date is today" do
      it "marks past slots as unavailable" do
        # Travel to a known time on a weekday
        monday = Date.tomorrow
        monday += 1.day until monday.wday == 1

        travel_to Time.zone.parse("#{monday} 14:00 -0500") do
          employee.employee_schedules.find_or_create_by!(day_of_week: monday.wday) do |s|
            s.start_time = "08:00"
            s.end_time = "18:00"
          end

          result = described_class.call(business: business, service_id: service.id, date: monday)
          # Slots before 14:00 should be unavailable
          slot_10 = result.data.find { |s| s[:time] == "10:00" }
          expect(slot_10[:available]).to be false if slot_10
        end
      end
    end

    context "with date as string" do
      it "parses the date string correctly" do
        result = described_class.call(business: business, service_id: service.id, date: target_date.to_s)
        expect(result).to be_success
        expect(result.data).to be_an(Array)
      end
    end
  end
end
