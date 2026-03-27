# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Public::ReferralDashboard", type: :request do
  let(:referral_code) do
    create(:referral_code,
      code: "TESTCODE",
      referrer_name: "Juan Pérez",
      referrer_email: "juan@example.com",
      referrer_phone: "+573001234567",
      bank_name: "Bancolombia",
      bank_account: "1234567890",
      breb_key: "juanperez@breb",
      commission_percentage: 10)
  end

  let(:plan) { create(:plan, name: "Profesional", price_monthly: 82_000) }

  describe "GET /api/v1/public/referral_codes/:code/dashboard" do
    it "returns dashboard data for a valid code" do
      business = create(:business, trial_ends_at: 5.days.from_now)
      referral = create(:referral, referral_code: referral_code, business: business, status: :pending)

      get "/api/v1/public/referral_codes/TESTCODE/dashboard"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]

      # Referrer info
      expect(data["referrer"]["name"]).to eq("Juan Pérez")
      expect(data["referrer"]["code"]).to eq("TESTCODE")
      expect(data["referrer"]["commission_percentage"]).to eq(10)

      # Stats
      expect(data["stats"]["total_referrals"]).to eq(1)
      expect(data["stats"]["active_subscriptions"]).to eq(0)

      # Referrals
      expect(data["referrals"].length).to eq(1)
      expect(data["referrals"][0]["business_name"]).to eq(business.name)
      expect(data["referrals"][0]["trial_expired"]).to be false
      expect(data["referrals"][0]["has_subscription"]).to be false

      # Links
      expect(data["referral_link"]).to include("ref=TESTCODE")
      expect(data["conditions"]).to be_present
    end

    it "calculates stats correctly with activated referrals" do
      business = create(:business, trial_ends_at: 3.days.ago)
      subscription = create(:subscription, business: business, plan: plan, status: :active)
      create(:referral,
        referral_code: referral_code,
        business: business,
        subscription: subscription,
        status: :activated,
        commission_amount: 8200,
        activated_at: Date.current)

      get "/api/v1/public/referral_codes/TESTCODE/dashboard"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]

      expect(data["stats"]["active_subscriptions"]).to eq(1)
      expect(data["stats"]["total_earned"]).to eq(8200)
      expect(data["stats"]["pending_commission"]).to eq(8200)
      expect(data["stats"]["paid_commission"]).to eq(0)

      expect(data["referrals"][0]["has_subscription"]).to be true
      expect(data["referrals"][0]["plan_name"]).to eq("Profesional")
      expect(data["referrals"][0]["trial_expired"]).to be true
    end

    it "includes paid commissions in stats" do
      business = create(:business, trial_ends_at: 10.days.ago)
      subscription = create(:subscription, business: business, plan: plan, status: :active)
      create(:referral,
        referral_code: referral_code,
        business: business,
        subscription: subscription,
        status: :paid,
        commission_amount: 8200,
        activated_at: 5.days.ago,
        paid_at: Date.current)

      get "/api/v1/public/referral_codes/TESTCODE/dashboard"

      data = response.parsed_body["data"]
      expect(data["stats"]["total_earned"]).to eq(8200)
      expect(data["stats"]["pending_commission"]).to eq(0)
      expect(data["stats"]["paid_commission"]).to eq(8200)
    end

    it "returns 404 for an invalid code" do
      get "/api/v1/public/referral_codes/INVALID123/dashboard"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to eq("Código de referido no encontrado")
    end

    it "is case-insensitive for the code" do
      referral_code # ensure created

      get "/api/v1/public/referral_codes/testcode/dashboard"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /api/v1/public/referral_codes/:code" do
    it "updates referrer contact and payment info" do
      referral_code # ensure created

      patch "/api/v1/public/referral_codes/TESTCODE", params: {
        referrer_name: "Juan Carlos Pérez",
        referrer_phone: "+573009876543",
        bank_name: "Nequi",
        bank_account: "9876543210",
        breb_key: "juancarlos@breb"
      }

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]

      expect(data["message"]).to eq("Información actualizada correctamente")
      expect(data["referrer"]["name"]).to eq("Juan Carlos Pérez")
      expect(data["referrer"]["phone"]).to eq("+573009876543")
      expect(data["referrer"]["bank_name"]).to eq("Nequi")
      expect(data["referrer"]["bank_account"]).to eq("9876543210")
      expect(data["referrer"]["breb_key"]).to eq("juancarlos@breb")

      referral_code.reload
      expect(referral_code.referrer_name).to eq("Juan Carlos Pérez")
      expect(referral_code.bank_name).to eq("Nequi")
    end

    it "returns 404 for an invalid code" do
      patch "/api/v1/public/referral_codes/INVALID123", params: { referrer_name: "Test" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/public/referral_codes/:code/request_disbursement" do
    it "requests disbursement for activated referrals without prior request" do
      business = create(:business, trial_ends_at: 10.days.ago)
      subscription = create(:subscription, business: business, plan: plan, status: :active)
      create(:referral,
        referral_code: referral_code,
        business: business,
        subscription: subscription,
        status: :activated,
        commission_amount: 8200,
        activated_at: 5.days.ago)

      expect {
        post "/api/v1/public/referral_codes/TESTCODE/request_disbursement"
      }.to change(AdminNotification, :count).by(1)

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data["requested"]).to eq(1)
      expect(data["message"]).to include("Solicitud enviada")

      # Verify admin notification
      notification = AdminNotification.last
      expect(notification.title).to eq("Solicitud de desembolso")
      expect(notification.notification_type).to eq("referral_disbursement")
      expect(notification.body).to include("Juan Pérez")
    end

    it "returns error when no pending commissions to request" do
      referral_code # ensure created

      post "/api/v1/public/referral_codes/TESTCODE/request_disbursement"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("No hay comisiones pendientes")
    end

    it "does not re-request already requested referrals" do
      business = create(:business, trial_ends_at: 10.days.ago)
      subscription = create(:subscription, business: business, plan: plan, status: :active)
      create(:referral,
        referral_code: referral_code,
        business: business,
        subscription: subscription,
        status: :activated,
        commission_amount: 8200,
        activated_at: 5.days.ago,
        disbursement_requested_at: 1.day.ago)

      post "/api/v1/public/referral_codes/TESTCODE/request_disbursement"

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for an invalid code" do
      post "/api/v1/public/referral_codes/INVALID123/request_disbursement"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to eq("Código de referido no encontrado")
    end

    it "is case-insensitive for the code" do
      business = create(:business, trial_ends_at: 10.days.ago)
      subscription = create(:subscription, business: business, plan: plan, status: :active)
      create(:referral,
        referral_code: referral_code,
        business: business,
        subscription: subscription,
        status: :activated,
        commission_amount: 8200,
        activated_at: 5.days.ago)

      post "/api/v1/public/referral_codes/testcode/request_disbursement"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/public/referral_codes/:code/dashboard (disbursement fields)" do
    it "includes disbursement data in referral entries" do
      business = create(:business, trial_ends_at: 10.days.ago)
      subscription = create(:subscription, business: business, plan: plan, status: :active)
      create(:referral,
        referral_code: referral_code,
        business: business,
        subscription: subscription,
        status: :activated,
        commission_amount: 8200,
        activated_at: 5.days.ago,
        disbursement_requested_at: 2.days.ago)

      get "/api/v1/public/referral_codes/TESTCODE/dashboard"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]

      referral_entry = data["referrals"][0]
      expect(referral_entry).to have_key("disbursement_requested_at")
      expect(referral_entry["disbursement_requested_at"]).to be_present
      expect(referral_entry).to have_key("disbursement_paid_at")
      expect(referral_entry).to have_key("disbursement_proof_url")
      expect(referral_entry).to have_key("disbursement_notes")
    end

    it "includes disbursements summary section" do
      business = create(:business, trial_ends_at: 10.days.ago)
      subscription = create(:subscription, business: business, plan: plan, status: :active)
      create(:referral,
        referral_code: referral_code,
        business: business,
        subscription: subscription,
        status: :paid,
        commission_amount: 8200,
        activated_at: 5.days.ago,
        paid_at: 1.day.ago,
        disbursement_requested_at: 3.days.ago,
        disbursement_paid_at: 1.day.ago,
        disbursement_notes: "Transferencia Bancolombia #123")

      get "/api/v1/public/referral_codes/TESTCODE/dashboard"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]

      expect(data["disbursements"]).to be_present
      disbursement = data["disbursements"][0]
      expect(disbursement["business_name"]).to eq(business.name)
      expect(disbursement["amount"]).to eq(8200)
      expect(disbursement["status"]).to eq("paid")
      expect(disbursement["notes"]).to eq("Transferencia Bancolombia #123")
    end
  end

  describe "Welcome email on referral signup" do
    it "sends welcome email when a new referral code is created" do
      expect {
        post "/api/v1/public/referral_codes", params: {
          referrer_name: "María López",
          referrer_email: "maria@example.com",
          referrer_phone: "+573001111111"
        }
      }.to have_enqueued_mail(ReferralMailer, :welcome)

      expect(response).to have_http_status(:created)
    end

    it "does not send welcome email when returning existing code" do
      create(:referral_code, referrer_email: "existing@example.com")

      expect {
        post "/api/v1/public/referral_codes", params: {
          referrer_name: "Existing User",
          referrer_email: "existing@example.com"
        }
      }.not_to have_enqueued_mail(ReferralMailer, :welcome)
    end
  end
end
