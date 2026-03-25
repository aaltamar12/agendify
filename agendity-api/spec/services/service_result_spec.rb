require "rails_helper"

RSpec.describe ServiceResult do
  describe "success result" do
    let(:result) { described_class.new(success: true, data: { id: 1 }) }

    it "is success" do
      expect(result).to be_success
    end

    it "is not failure" do
      expect(result).not_to be_failure
    end

    it "has data" do
      expect(result.data).to eq({ id: 1 })
    end

    it "has no error" do
      expect(result.error).to be_nil
      expect(result.error_code).to be_nil
      expect(result.details).to be_nil
    end
  end

  describe "failure result" do
    let(:result) do
      described_class.new(
        success: false,
        error: "Something failed",
        error_code: "FAIL_CODE",
        details: ["detail1", "detail2"]
      )
    end

    it "is failure" do
      expect(result).to be_failure
    end

    it "is not success" do
      expect(result).not_to be_success
    end

    it "has error info" do
      expect(result.error).to eq("Something failed")
      expect(result.error_code).to eq("FAIL_CODE")
      expect(result.details).to eq(["detail1", "detail2"])
    end

    it "has no data" do
      expect(result.data).to be_nil
    end
  end
end
