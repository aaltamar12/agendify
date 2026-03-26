# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Documentation", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/documentation" do
    it "returns success" do
      get "/admin/documentation"
      expect(response).to have_http_status(:success)
    end
  end
end
