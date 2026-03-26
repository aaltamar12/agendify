# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::ReferralSignup", type: :request do
  describe "POST /api/v1/public/referral_codes" do
    let(:valid_params) do
      {
        referrer_name: "Juan Pérez",
        referrer_email: "juan@example.com",
        referrer_phone: "+573001234567",
        bank_name: "Bancolombia",
        bank_account: "1234567890",
        breb_key: "juanperez@breb"
      }
    end

    it "creates a referral code with valid params" do
      expect {
        post "/api/v1/public/referral_codes", params: valid_params
      }.to change(ReferralCode, :count).by(1)

      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["code"]).to be_present
      expect(data["message"]).to eq("Tu código de referido ha sido creado")

      referral_code = ReferralCode.last
      expect(referral_code.referrer_name).to eq("Juan Pérez")
      expect(referral_code.referrer_email).to eq("juan@example.com")
      expect(referral_code.bank_name).to eq("Bancolombia")
      expect(referral_code.bank_account).to eq("1234567890")
      expect(referral_code.breb_key).to eq("juanperez@breb")
      expect(referral_code.commission_percentage).to eq(10)
      expect(referral_code).to be_active
    end

    it "returns existing code if email already has one" do
      existing = create(:referral_code, referrer_email: "juan@example.com", code: "EXISTING")

      expect {
        post "/api/v1/public/referral_codes", params: valid_params
      }.not_to change(ReferralCode, :count)

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["code"]).to eq(existing.code)
      expect(data["message"]).to eq("Ya tienes un código de referido")
    end

    it "fails without required fields" do
      post "/api/v1/public/referral_codes", params: { referrer_name: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Nombre y email son requeridos")
    end

    it "fails when only email is provided" do
      post "/api/v1/public/referral_codes", params: { referrer_email: "juan@example.com" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Nombre y email son requeridos")
    end

    it "creates a referral code without optional payment fields" do
      post "/api/v1/public/referral_codes", params: {
        referrer_name: "María López",
        referrer_email: "maria@example.com"
      }

      expect(response).to have_http_status(:created)
      referral_code = ReferralCode.last
      expect(referral_code.bank_name).to be_nil
      expect(referral_code.bank_account).to be_nil
      expect(referral_code.breb_key).to be_nil
    end
  end
end
