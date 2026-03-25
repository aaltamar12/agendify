require "rails_helper"

RSpec.describe Businesses::CompleteOnboardingService do
  let(:business) { create(:business, onboarding_completed: false) }

  describe "#call" do
    context "with valid params" do
      let(:params) do
        {
          name: "Mi Barberia",
          business_type: "barbershop",
          address: "Calle 45 #20-30",
          city: "Barranquilla",
          country: "CO",
          phone: "3001234567"
        }
      end

      it "updates the business and marks onboarding as completed" do
        result = described_class.call(business: business, params: params)
        expect(result).to be_success
        business.reload
        expect(business.onboarding_completed).to be true
        expect(business.phone).to eq("3001234567")
      end
    end

    context "with invalid params" do
      it "returns failure when name is blank" do
        result = described_class.call(business: business, params: { name: "" })
        expect(result).to be_failure
      end
    end

    context "with unpermitted params" do
      it "ignores unpermitted attributes" do
        result = described_class.call(business: business, params: { name: "Test", status: "suspended" })
        expect(result).to be_success
        expect(business.reload.status).to eq("active")
      end
    end
  end
end
