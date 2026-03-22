require "rails_helper"

RSpec.describe "Reports", type: :request do
  let(:owner) { create(:user) }
  let(:business) { create(:business, owner: owner, cancellation_policy_pct: 30) }
  let(:token) { Auth::TokenGenerator.encode(owner) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  let(:employee) { create(:employee, business: business, pending_balance: 12_000) }
  let(:customer) { create(:customer, business: business) }
  let(:service) { create(:service, business: business, price: 40_000) }

  describe "GET /api/v1/reports/profit" do
    before do
      # Completed appointments (revenue)
      create(:appointment,
        business: business,
        employee: employee,
        customer: customer,
        service: service,
        appointment_date: 5.days.ago.to_date,
        status: :completed,
        price: 40_000)

      create(:appointment,
        business: business,
        employee: employee,
        customer: customer,
        service: service,
        appointment_date: 3.days.ago.to_date,
        status: :completed,
        price: 60_000)

      # Cancelled appointment by customer (generates penalty_income)
      create(:appointment,
        business: business,
        employee: employee,
        customer: customer,
        service: service,
        appointment_date: 2.days.ago.to_date,
        status: :cancelled,
        cancelled_by: "customer",
        price: 50_000)

      # Cancelled by business (should NOT count for penalty_income)
      create(:appointment,
        business: business,
        employee: employee,
        customer: customer,
        service: service,
        appointment_date: 2.days.ago.to_date,
        status: :cancelled,
        cancelled_by: "business",
        price: 30_000)

      # Employee payment via cash register close
      close = create(:cash_register_close,
        business: business,
        closed_by_user: owner,
        date: 5.days.ago.to_date,
        status: :closed)

      create(:employee_payment,
        cash_register_close: close,
        employee: employee,
        amount_paid: 25_000,
        total_owed: 25_000)

      # Credit transactions
      credit_account = create(:credit_account,
        business: business,
        customer: customer,
        balance: 7_000)

      create(:credit_transaction,
        credit_account: credit_account,
        amount: 10_000,
        transaction_type: :cashback)

      create(:credit_transaction,
        credit_account: credit_account,
        amount: -3_000,
        transaction_type: :redemption)
    end

    it "returns all expected profit fields" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]

      expect(data).to have_key("revenue")
      expect(data).to have_key("penalty_income")
      expect(data).to have_key("total_income")
      expect(data).to have_key("employee_payments")
      expect(data).to have_key("net_profit")
      expect(data).to have_key("credits_issued")
      expect(data).to have_key("credits_redeemed")
      expect(data).to have_key("pending_employee_debt")
      expect(data).to have_key("total_credits_in_circulation")
    end

    it "calculates revenue from completed appointments" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      # 40,000 + 60,000 = 100,000
      expect(data["revenue"]).to eq(100_000.0)
    end

    it "calculates penalty_income from cancelled appointments with cancellation_policy_pct" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      # Only customer-cancelled: 50,000 * 30% = 15,000
      # Business-cancelled is excluded
      expect(data["penalty_income"]).to eq(15_000.0)
    end

    it "calculates total_income as revenue + penalty_income" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      expect(data["total_income"]).to eq(data["revenue"] + data["penalty_income"])
    end

    it "returns employee_payments total" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      expect(data["employee_payments"]).to eq(25_000.0)
    end

    it "calculates net_profit as total_income minus employee_payments" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      expected_net = data["total_income"] - data["employee_payments"]
      expect(data["net_profit"]).to eq(expected_net)
    end

    it "returns credits_issued and credits_redeemed" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      expect(data["credits_issued"]).to eq(10_000.0)
      expect(data["credits_redeemed"]).to eq(3_000.0)
    end

    it "returns pending_employee_debt from employee balances" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      expect(data["pending_employee_debt"]).to eq(12_000.0)
    end

    it "returns total_credits_in_circulation from credit accounts" do
      get "/api/v1/reports/profit", params: { period: "month" }, headers: auth_headers
      data = response.parsed_body["data"]

      expect(data["total_credits_in_circulation"]).to eq(7_000.0)
    end

    it "returns 401 without authentication" do
      get "/api/v1/reports/profit"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
