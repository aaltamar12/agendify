require "rails_helper"

RSpec.describe PexelsService do
  describe ".search" do
    context "when API key is blank" do
      before { allow(ENV).to receive(:[]).with("PEXELS_API_KEY").and_return(nil) }

      it "returns an empty array" do
        expect(described_class.search(query: "barbershop")).to eq([])
      end
    end

    context "when API key is present" do
      before { allow(ENV).to receive(:[]).with("PEXELS_API_KEY").and_return("test-key") }

      let(:success_body) do
        {
          "photos" => [
            {
              "id" => 123,
              "src" => { "medium" => "https://pexels.com/m.jpg", "large" => "https://pexels.com/l.jpg", "original" => "https://pexels.com/o.jpg" },
              "photographer" => "John Doe",
              "alt" => "A barbershop"
            }
          ]
        }.to_json
      end

      let(:mock_http) { instance_double(Net::HTTP) }

      it "returns mapped photo data on success" do
        response = instance_double(Net::HTTPSuccess, is_a?: true, body: success_body)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:start).and_return(response)

        results = described_class.search(query: "barbershop")
        expect(results.length).to eq(1)
        expect(results.first[:id]).to eq(123)
        expect(results.first[:url_small]).to eq("https://pexels.com/m.jpg")
        expect(results.first[:url_medium]).to eq("https://pexels.com/l.jpg")
        expect(results.first[:url_large]).to eq("https://pexels.com/o.jpg")
        expect(results.first[:photographer]).to eq("John Doe")
        expect(results.first[:alt]).to eq("A barbershop")
      end

      it "returns empty array on non-success response" do
        response = instance_double(Net::HTTPForbidden)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(Net::HTTP).to receive(:start).and_return(response)

        expect(described_class.search(query: "barbershop")).to eq([])
      end

      it "returns empty array on network error" do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError.new("timeout"))

        expect(described_class.search(query: "barbershop")).to eq([])
      end

      it "handles response with no photos key" do
        response = instance_double(Net::HTTPSuccess, body: {}.to_json)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:start).and_return(response)

        expect(described_class.search(query: "barbershop")).to eq([])
      end

      it "passes per_page and page parameters" do
        response = instance_double(Net::HTTPSuccess, body: { "photos" => [] }.to_json)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:start).and_return(response)

        results = described_class.search(query: "salon", per_page: 5, page: 2)
        expect(results).to eq([])
      end
    end
  end
end
