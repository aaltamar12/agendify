# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::Reviews", type: :request do
  let(:business) { create(:business) }
  let(:employee) { create(:employee, business: business) }
  let(:service) { create(:service, business: business) }
  let(:customer) { create(:customer, business: business) }
  let(:appointment) do
    create(:appointment,
           business: business,
           employee: employee,
           service: service,
           customer: customer,
           status: :confirmed)
  end

  describe "GET /api/v1/public/:slug/rate" do
    it "returns appointment data for the rating page" do
      get "/api/v1/public/#{business.slug}/rate", params: { appointment: appointment.id }
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["appointment"]["id"]).to eq(appointment.id)
      expect(data["appointment"]["service_name"]).to eq(service.name)
      expect(data["appointment"]["employee_name"]).to eq(employee.name)
      expect(data["business_name"]).to eq(business.name)
      expect(data["already_reviewed"]).to be false
    end

    it "returns already_reviewed true when a review exists" do
      create(:review, business: business, appointment: appointment, customer: customer)
      get "/api/v1/public/#{business.slug}/rate", params: { appointment: appointment.id }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["already_reviewed"]).to be true
    end

    it "returns 404 for unknown slug" do
      get "/api/v1/public/nonexistent-slug/rate", params: { appointment: appointment.id }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for appointment from another business" do
      other_appointment = create(:appointment)
      get "/api/v1/public/#{business.slug}/rate", params: { appointment: other_appointment.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/public/:slug/reviews" do
    it "creates a business review" do
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: appointment.id,
        rating: 5,
        comment: "Excelente servicio"
      }
      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["review"]).to be_present
    end

    it "creates both business and employee reviews when employee_rating is provided" do
      expect {
        post "/api/v1/public/#{business.slug}/reviews", params: {
          appointment_id: appointment.id,
          rating: 5,
          employee_rating: 4,
          comment: "Great"
        }
      }.to change(Review, :count).by(2)
      expect(response).to have_http_status(:created)
    end

    it "uses customer_name from params when provided" do
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: appointment.id,
        rating: 4,
        customer_name: "Custom Name"
      }
      expect(response).to have_http_status(:created)
      expect(Review.last.customer_name).to eq("Custom Name")
    end

    it "falls back to appointment customer name when customer_name is not provided" do
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: appointment.id,
        rating: 4
      }
      expect(response).to have_http_status(:created)
      expect(Review.last.customer_name).to eq(customer.name)
    end

    it "returns 422 for duplicate review on same appointment" do
      create(:review, business: business, appointment: appointment, customer: customer, employee: nil)
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: appointment.id,
        rating: 5
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Ya calificaste")
    end

    it "returns 422 for invalid rating" do
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: appointment.id,
        rating: 0
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for missing rating" do
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: appointment.id
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for unknown slug" do
      post "/api/v1/public/nonexistent-slug/reviews", params: {
        appointment_id: appointment.id,
        rating: 5
      }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for appointment from another business" do
      other_appointment = create(:appointment)
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: other_appointment.id,
        rating: 5
      }
      expect(response).to have_http_status(:not_found)
    end

    it "does not create employee review when employee_rating is absent" do
      expect {
        post "/api/v1/public/#{business.slug}/reviews", params: {
          appointment_id: appointment.id,
          rating: 5
        }
      }.to change(Review, :count).by(1)
    end

    it "returns 422 for rating above 5" do
      post "/api/v1/public/#{business.slug}/reviews", params: {
        appointment_id: appointment.id,
        rating: 6
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
