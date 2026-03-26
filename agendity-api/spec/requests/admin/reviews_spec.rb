# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Reviews", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/reviews" do
    it "returns success" do
      create(:review)
      get "/admin/reviews"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/reviews/:id" do
    it "returns success" do
      review = create(:review)
      get "/admin/reviews/#{review.id}"
      expect(response).to have_http_status(:success)
    end
  end
end
