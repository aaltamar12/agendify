require "rails_helper"

RSpec.describe Appointments::CompleteService do
  let(:business) { create(:business) }
  let(:appointment) { create(:appointment, business: business, status: :checked_in) }

  describe "#call" do
    context "when appointment is checked_in" do
      it "completes the appointment" do
        result = described_class.call(appointment: appointment)
        expect(result).to be_success
        expect(appointment.reload.status).to eq("completed")
      end
    end

    context "when appointment is not checked_in" do
      before { appointment.update_column(:status, :confirmed) }

      it "returns failure" do
        result = described_class.call(appointment: appointment)
        expect(result).to be_failure
        expect(result.error).to include("Only checked-in appointments")
      end
    end
  end
end
