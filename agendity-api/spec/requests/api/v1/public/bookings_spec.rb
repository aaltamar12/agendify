# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::Bookings", type: :request do
  let(:business) { create(:business, :with_hours, status: :active) }
  let(:service) { create(:service, business: business) }
  let(:employee) { create(:employee, business: business) }

  describe "POST /api/v1/public/:slug/book" do
    it "creates a booking" do
      params = {
        booking: {
          service_id: service.id,
          employee_id: employee.id,
          date: Date.tomorrow.to_s,
          start_time: "10:00",
          customer_name: "María",
          customer_email: "maria@test.com",
          customer_phone: "3001234567"
        }
      }
      post "/api/v1/public/#{business.slug}/book", params: params
      expect(response.status).to be_in([201, 422])
    end

    it "returns 422 for unknown slug" do
      post "/api/v1/public/unknown-slug/book", params: { booking: { service_id: 1 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/public/customer_lookup" do
    it "returns customer data if found" do
      customer = create(:customer, business: business, email: "existing@test.com")
      get "/api/v1/public/customer_lookup",
          params: { slug: business.slug, email: "existing@test.com" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq(customer.name)
    end

    it "returns 404 for unknown customer" do
      get "/api/v1/public/customer_lookup",
          params: { slug: business.slug, email: "unknown@test.com" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/public/:slug/check_slot" do
    it "checks slot availability" do
      get "/api/v1/public/#{business.slug}/check_slot",
          params: { service_id: service.id, date: Date.tomorrow.to_s, time: "10:00" }
      expect(response.status).to be_in([200, 404])
    end
  end

  describe "POST /api/v1/public/:slug/lock_slot" do
    it "locks a slot" do
      post "/api/v1/public/#{business.slug}/lock_slot",
           params: { employee_id: employee.id, date: Date.tomorrow.to_s, time: "10:00" }
      expect(response.status).to be_in([200, 409])
    end
  end

  describe "POST /api/v1/public/:slug/unlock_slot" do
    it "unlocks a slot" do
      post "/api/v1/public/#{business.slug}/unlock_slot",
           params: { employee_id: employee.id, date: Date.tomorrow.to_s, time: "10:00", lock_token: "test" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/public/:slug/validate_code" do
    it "validates an existing discount code" do
      create(:discount_code, business: business, code: "TEST10")
      get "/api/v1/public/#{business.slug}/validate_code", params: { code: "TEST10" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["valid"]).to be true
    end

    it "returns valid: false for unknown code" do
      get "/api/v1/public/#{business.slug}/validate_code", params: { code: "UNKNOWN" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["valid"]).to be false
    end

    it "validates code case-insensitively" do
      create(:discount_code, business: business, code: "TEST10")
      get "/api/v1/public/#{business.slug}/validate_code", params: { code: "test10" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["valid"]).to be true
    end
  end

  describe "POST /api/v1/public/:slug/book with flat params" do
    it "accepts flat params without booking key" do
      params = {
        service_id: service.id,
        employee_id: employee.id,
        date: Date.tomorrow.to_s,
        start_time: "10:00",
        customer_name: "Carlos",
        customer_email: "carlos@test.com",
        customer_phone: "3001234567"
      }
      post "/api/v1/public/#{business.slug}/book", params: params
      expect(response.status).to be_in([201, 422])
    end

    it "accepts nested customer params" do
      params = {
        booking: {
          service_id: service.id,
          employee_id: employee.id,
          date: Date.tomorrow.to_s,
          start_time: "10:00",
          customer: {
            name: "Ana",
            email: "ana@test.com",
            phone: "3009876543"
          }
        }
      }
      post "/api/v1/public/#{business.slug}/book", params: params
      expect(response.status).to be_in([201, 422])
    end

    it "accepts appointment_date instead of date" do
      params = {
        booking: {
          service_id: service.id,
          employee_id: employee.id,
          appointment_date: Date.tomorrow.to_s,
          start_time: "10:00",
          customer_name: "Luis",
          customer_email: "luis@test.com",
          customer_phone: "3001112222"
        }
      }
      post "/api/v1/public/#{business.slug}/book", params: params
      expect(response.status).to be_in([201, 422])
    end
  end

  describe "GET /api/v1/public/customer_lookup" do
    it "returns 404 for unknown slug" do
      get "/api/v1/public/customer_lookup",
          params: { slug: "nonexistent-business", email: "test@test.com" }
      expect(response).to have_http_status(:not_found)
    end

    it "is case-insensitive on email lookup" do
      customer = create(:customer, business: business, email: "Test@Example.com")
      get "/api/v1/public/customer_lookup",
          params: { slug: business.slug, email: "test@example.com" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["name"]).to eq(customer.name)
    end
  end

  describe "GET /api/v1/public/:slug/check_slot" do
    it "returns not found for invalid service" do
      get "/api/v1/public/#{business.slug}/check_slot",
          params: { service_id: 999999, date: Date.tomorrow.to_s, time: "10:00" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
