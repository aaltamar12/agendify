require "rails_helper"

RSpec.describe Appointments::CheckinService do
  let(:business)    { create(:business, timezone: "America/Bogota") }
  let(:employee)    { create(:employee, business: business) }
  let(:customer)    { create(:customer, business: business) }
  let(:service)     { create(:service, business: business) }

  let(:appointment) do
    create(:appointment,
      business: business,
      employee: employee,
      customer: customer,
      service: service,
      status: :confirmed,
      appointment_date: Date.current,
      start_time: "10:00",
      end_time: "10:30"
    )
  end

  describe "#call" do
    context "when appointment is confirmed and within check-in window" do
      it "checks in the appointment" do
        travel_to Time.zone.parse("#{Date.current} 09:45") do
          result = described_class.call(appointment: appointment)
          expect(result).to be_success
          expect(appointment.reload.status).to eq("checked_in")
          expect(appointment.checked_in_at).to be_present
        end
      end
    end

    context "when appointment is not confirmed" do
      before { appointment.update_column(:status, :pending_payment) }

      it "returns failure" do
        result = described_class.call(appointment: appointment)
        expect(result).to be_failure
        expect(result.error).to include("Only confirmed appointments")
      end
    end

    context "when too early for check-in" do
      it "returns failure with CHECKIN_TOO_EARLY code" do
        travel_to Time.zone.parse("#{Date.current} 08:00") do
          result = described_class.call(appointment: appointment)
          expect(result).to be_failure
          expect(result.error_code).to eq("CHECKIN_TOO_EARLY")
        end
      end
    end

    context "when a different employee does check-in" do
      let(:other_user) { create(:user, role: :employee) }
      let(:other_employee) { create(:employee, business: business, user: other_user) }

      it "requires confirmation for substitute" do
        travel_to Time.zone.parse("#{Date.current} 09:45") do
          result = described_class.call(appointment: appointment, actor: other_user)
          expect(result).to be_failure
          expect(result.data[:requires_confirmation]).to be true
        end
      end

      it "allows substitute with confirmation" do
        travel_to Time.zone.parse("#{Date.current} 09:45") do
          result = described_class.call(appointment: appointment, actor: other_user, confirmed: true, substitute_reason: "Cambio de turno")
          expect(result).to be_success
          expect(appointment.reload.checkin_substitute).to be true
        end
      end
    end
  end
end
