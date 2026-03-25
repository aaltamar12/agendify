require "rails_helper"

RSpec.describe Businesses::UpdateService do
  let(:business) { create(:business) }

  describe "#call" do
    context "with valid params" do
      it "updates the business" do
        result = described_class.call(business: business, params: { phone: "3009876543" })
        expect(result).to be_success
        expect(business.reload.phone).to eq("3009876543")
      end
    end

    context "with invalid params" do
      it "returns failure" do
        result = described_class.call(business: business, params: { name: "" })
        expect(result).to be_failure
        expect(result.error).to include("Could not update business")
      end
    end
  end
end
