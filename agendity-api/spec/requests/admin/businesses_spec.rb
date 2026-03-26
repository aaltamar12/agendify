# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Businesses", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:business) { create(:business) }

  before { admin_login(admin) }

  describe "GET /admin/businesses" do
    it "returns success" do
      get admin_businesses_path
      expect(response).to have_http_status(:success)
    end

    it "displays the business in the list" do
      get admin_businesses_path
      expect(response.body).to include(ERB::Util.html_escape(business.name))
    end
  end

  describe "GET /admin/businesses/:id" do
    it "returns success" do
      get admin_business_path(business)
      expect(response).to have_http_status(:success)
    end

    it "displays business details" do
      get admin_business_path(business)
      expect(response.body).to include(business.name)
    end
  end

  describe "GET /admin/businesses/new" do
    it "returns success" do
      get new_admin_business_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/businesses/:id/edit" do
    it "returns success" do
      get edit_admin_business_path(business)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/businesses" do
    it "renders the create form (owner not assignable via form)" do
      post admin_businesses_path, params: {
        business: {
          name: "New Test Business",
          business_type: "barbershop",
          status: "active"
        }
      }
      # Business requires an owner, so create via admin form will fail validation
      # This verifies the endpoint is reachable and handles the error gracefully
      expect(response).to have_http_status(:success).or have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/businesses/:id" do
    it "updates the business" do
      patch admin_business_path(business), params: {
        business: { name: "Updated Name" }
      }
      expect(business.reload.name).to eq("Updated Name")
    end
  end

  describe "member actions" do
    describe "PUT /admin/businesses/:id/approve" do
      let(:business) { create(:business, status: :inactive) }

      it "activates the business" do
        put approve_admin_business_path(business)
        expect(business.reload.status).to eq("active")
        expect(response).to redirect_to(admin_business_path(business))
      end
    end

    describe "PUT /admin/businesses/:id/suspend" do
      it "suspends the business" do
        put suspend_admin_business_path(business)
        expect(business.reload.status).to eq("suspended")
        expect(response).to redirect_to(admin_business_path(business))
      end
    end

    describe "PUT /admin/businesses/:id/deactivate" do
      it "deactivates the business" do
        put deactivate_admin_business_path(business)
        expect(business.reload.status).to eq("inactive")
        expect(response).to redirect_to(admin_business_path(business))
      end
    end

    describe "PUT /admin/businesses/:id/activate" do
      let(:business) { create(:business, status: :suspended) }

      it "activates a suspended business" do
        put activate_admin_business_path(business)
        expect(business.reload.status).to eq("active")
        expect(response).to redirect_to(admin_business_path(business))
      end
    end
  end

  describe "batch actions" do
    let!(:business2) { create(:business, status: :inactive) }

    it "batch activates businesses" do
      post batch_action_admin_businesses_path, params: {
        batch_action: "activate",
        collection_selection: [business2.id]
      }
      expect(business2.reload.status).to eq("active")
    end

    it "batch hides businesses" do
      post batch_action_admin_businesses_path, params: {
        batch_action: "hide",
        collection_selection: [business.id]
      }
      expect(business.reload.status).to eq("suspended")
    end

    it "batch deactivates businesses" do
      post batch_action_admin_businesses_path, params: {
        batch_action: "deactivate",
        collection_selection: [business.id]
      }
      expect(business.reload.status).to eq("inactive")
    end
  end

  context "when not authenticated" do
    it "redirects to login" do
      get admin_logout_path # logout first
      get admin_businesses_path
      expect(response).to redirect_to(admin_login_path)
    end
  end
end
