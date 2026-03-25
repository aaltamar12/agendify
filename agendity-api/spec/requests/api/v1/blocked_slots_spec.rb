# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::BlockedSlots", type: :request do
  let(:business) { create(:business) }
  let(:user) { business.owner }
  let(:token) { Auth::TokenGenerator.encode(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/blocked_slots" do
    it "returns blocked slots for the business" do
      create(:blocked_slot, business: business)
      get "/api/v1/blocked_slots", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end

    it "returns 401 without token" do
      get "/api/v1/blocked_slots"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/blocked_slots" do
    it "creates a blocked slot" do
      employee = create(:employee, business: business)
      params = {
        employee_id: employee.id,
        date: Date.tomorrow.to_s,
        start_time: "12:00",
        end_time: "13:00",
        reason: "Almuerzo"
      }
      post "/api/v1/blocked_slots", params: params, headers: headers
      expect(response).to have_http_status(:created)
    end

    it "returns 422 with invalid params" do
      post "/api/v1/blocked_slots", params: { date: nil }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/blocked_slots/:id" do
    it "deletes a blocked slot" do
      slot = create(:blocked_slot, business: business)
      delete "/api/v1/blocked_slots/#{slot.id}", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
