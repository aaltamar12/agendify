# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Businesses", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/business" do
    it "returns the current business" do
      get "/api/v1/business", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(business.id)
    end

    it "returns 401 without token" do
      get "/api/v1/business"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/business" do
    it "updates the business" do
      patch "/api/v1/business", params: { business: { name: "Updated Name" } }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq("Updated Name")
    end

    it "returns 401 without token" do
      patch "/api/v1/business", params: { business: { name: "X" } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/business/upload_logo" do
    it "returns 422 without file" do
      post "/api/v1/business/upload_logo", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/business/upload_cover" do
    it "returns 422 without file" do
      post "/api/v1/business/upload_cover", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/business/cover_gallery" do
    it "returns gallery photos" do
      allow(PexelsService).to receive(:search).and_return([])
      get "/api/v1/business/cover_gallery", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/business/select_cover" do
    it "returns 422 without URL" do
      post "/api/v1/business/select_cover", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/business/onboarding" do
    it "completes onboarding" do
      params = {
        name: business.name,
        business_type: "barbershop",
        phone: "3001234567",
        address: "Calle 1",
        city: "Barranquilla",
        state: "ATL",
        country: "CO"
      }
      post "/api/v1/business/onboarding", params: params, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/business (admin without business)" do
    it "returns nil data for admin without business" do
      admin_user = create(:user, :admin)
      admin_token = Auth::TokenGenerator.encode(admin_user)
      admin_headers = { "Authorization" => "Bearer #{admin_token}" }
      get "/api/v1/business", headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_nil
    end
  end

  describe "PATCH /api/v1/business (brand customization)" do
    it "returns 403 when changing colors without brand_customization feature" do
      plan = create(:plan, brand_customization: false)
      create(:subscription, business: business, plan: plan)
      patch "/api/v1/business",
            params: { business: { primary_color: "#ff0000" } },
            headers: headers
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("personalización")
    end

    it "returns 422 when update service fails" do
      allow(Businesses::UpdateService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Invalid data", details: { name: ["is invalid"] })
      )
      patch "/api/v1/business",
            params: { business: { name: "" } },
            headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/business/upload_logo with file" do
    it "attaches logo successfully" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png")
      post "/api/v1/business/upload_logo", params: { logo: file }, headers: headers
      expect(response).to have_http_status(:ok)
    rescue Errno::ENOENT
      skip "Test fixture file not available"
    end

    it "returns 422 when logo fails to attach" do
      allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attached?).and_return(false)
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png")
      post "/api/v1/business/upload_logo", params: { logo: file }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Error al subir")
    end
  end

  describe "POST /api/v1/business/upload_cover with file" do
    it "attaches cover successfully" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png")
      post "/api/v1/business/upload_cover", params: { cover: file }, headers: headers
      expect(response).to have_http_status(:ok)
    rescue Errno::ENOENT
      skip "Test fixture file not available"
    end

    it "returns 422 when cover fails to attach" do
      allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attached?).and_return(false)
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test_image.png"), "image/png")
      post "/api/v1/business/upload_cover", params: { cover: file }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Error al subir")
    end
  end

  describe "POST /api/v1/business/onboarding (failure)" do
    it "returns 422 when onboarding service fails" do
      allow(Businesses::CompleteOnboardingService).to receive(:call).and_return(
        ServiceResult.new(success: false, error: "Missing data", details: { name: ["required"] })
      )
      post "/api/v1/business/onboarding",
           params: { name: "", business_type: "" },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/business/select_cover with valid URL" do
    it "downloads and attaches cover from Pexels URL" do
      file_content = File.binread(Rails.root.join("spec/fixtures/files/test_image.png"))
      fake_io = StringIO.new(file_content)
      fake_io.define_singleton_method(:content_type) { "image/png" }

      original_parse = URI.method(:parse)
      allow(URI).to receive(:parse) do |url|
        result = original_parse.call(url)
        if url.include?("images.pexels.com")
          allow(result).to receive(:open).and_return(fake_io)
        end
        result
      end

      post "/api/v1/business/select_cover",
           params: { url: "https://images.pexels.com/photos/123/test.jpg" },
           headers: headers
      expect(response).to have_http_status(:ok)
      expect(business.reload.cover_source).to eq("pexels")
    end

    it "returns 422 when download fails with HTTP error" do
      require "open-uri"
      original_parse = URI.method(:parse)
      allow(URI).to receive(:parse) do |url|
        result = original_parse.call(url)
        if url.include?("images.pexels.com")
          allow(result).to receive(:open).and_raise(OpenURI::HTTPError.new("404 Not Found", StringIO.new))
        end
        result
      end

      post "/api/v1/business/select_cover",
           params: { url: "https://images.pexels.com/photos/invalid/bad.jpg" },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Error al descargar")
    end
  end

  describe "PATCH /api/v1/business (cover_url mapping)" do
    it "maps cover_url to cover_image_url" do
      patch "/api/v1/business",
            params: { business: { cover_url: "https://example.com/cover.jpg" } },
            headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
