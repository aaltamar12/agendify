# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sessions", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "GET /admin/login" do
    it "returns success" do
      get "/admin/login"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/login" do
    it "signs in an admin user" do
      post "/admin/login", params: { email: admin.email, password: "password123" }
      expect(response).to redirect_to(admin_root_path)
    end

    it "rejects non-admin users" do
      owner = create(:user, role: :owner)
      post "/admin/login", params: { email: owner.email, password: "password123" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects invalid credentials" do
      post "/admin/login", params: { email: admin.email, password: "wrongpassword" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/logout" do
    it "signs out the admin user" do
      admin_login(admin)
      get "/admin/logout"
      expect(response).to redirect_to(admin_login_path)
    end
  end
end
