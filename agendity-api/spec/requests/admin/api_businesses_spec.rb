# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Businesses", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:business) { create(:business) }

  before do
    # API auth uses JWT, not session
    post "/api/v1/auth/login", params: { email: admin.email, password: "password123" }
    @token = JSON.parse(response.body).dig("data", "token")
  end

  describe "GET /api/v1/admin/businesses" do
    it "returns success for admin users" do
      get "/api/v1/admin/businesses", headers: { "Authorization" => "Bearer #{@token}" }
      expect(response).to have_http_status(:success)
    end

    it "supports search parameter" do
      get "/api/v1/admin/businesses", params: { search: business.name[0..3] },
        headers: { "Authorization" => "Bearer #{@token}" }
      expect(response).to have_http_status(:success)
    end
  end
end
