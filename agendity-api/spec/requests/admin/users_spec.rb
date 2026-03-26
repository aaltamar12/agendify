# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/users" do
    it "returns success" do
      get "/admin/users"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/users/:id" do
    it "returns success" do
      user = create(:user)
      get "/admin/users/#{user.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/users/new" do
    it "returns success" do
      get "/admin/users/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/users" do
    it "creates a user" do
      expect {
        post "/admin/users", params: {
          user: { name: "New User", email: "newuser@test.com", password: "password123", password_confirmation: "password123", role: "owner" }
        }
      }.to change(User, :count).by(1)
    end
  end
end
