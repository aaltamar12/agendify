require "rails_helper"

RSpec.describe BaseService do
  # Create a concrete subclass for testing
  let(:success_service_class) do
    Class.new(BaseService) do
      def initialize(value:)
        @value = value
      end

      def call
        success(@value)
      end
    end
  end

  let(:failure_service_class) do
    Class.new(BaseService) do
      def initialize(message:)
        @message = message
      end

      def call
        failure(@message, code: "TEST_ERROR", details: ["detail1"])
      end
    end
  end

  describe ".call" do
    it "instantiates and calls the service" do
      result = success_service_class.call(value: "hello")
      expect(result).to be_success
      expect(result.data).to eq("hello")
    end
  end

  describe "#success" do
    it "returns a successful ServiceResult" do
      result = success_service_class.call(value: { key: "val" })
      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.data).to eq({ key: "val" })
    end
  end

  describe "#failure" do
    it "returns a failed ServiceResult with error info" do
      result = failure_service_class.call(message: "something broke")
      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.error).to eq("something broke")
      expect(result.error_code).to eq("TEST_ERROR")
      expect(result.details).to eq(["detail1"])
    end
  end
end
