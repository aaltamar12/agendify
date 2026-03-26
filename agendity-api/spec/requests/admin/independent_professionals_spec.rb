# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::IndependentProfessionals", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin/independent_professionals" do
    it "returns success" do
      get admin_independent_professionals_path
      expect(response).to have_http_status(:success)
    end

    it "displays the creation form" do
      get admin_independent_professionals_path
      expect(response.body).to include("Crear Profesional Independiente")
    end

    context "with existing independent professionals" do
      let!(:owner) { create(:user) }
      let!(:business) { create(:business, owner: owner, independent: true) }

      it "displays the list of independent professionals" do
        get admin_independent_professionals_path
        expect(response.body).to include(business.name)
      end
    end
  end

  describe "POST /admin/independent_professionals/create" do
    let!(:plan) { create(:plan, name: "Basico") }

    it "creates a new independent professional" do
      expect {
        post admin_independent_professionals_create_path, params: {
          independent_professional: {
            name: "Carlos Barber",
            email: "carlos@example.com",
            phone: "3001234567",
            business_type: "barbershop"
          }
        }
      }.to change(User, :count).by(1)
        .and change(Business, :count).by(1)
        .and change(Employee, :count).by(1)
        .and change(Subscription, :count).by(1)
    end

    it "redirects with success notice" do
      create(:plan) unless Plan.exists? # ensure at least one plan
      post admin_independent_professionals_create_path, params: {
        independent_professional: {
          name: "Carlos Barber",
          email: "carlos2@example.com",
          phone: "3001234567",
          business_type: "barbershop"
        }
      }
      expect(response).to redirect_to(admin_independent_professionals_path)
      expect(flash[:notice]).to include("creado exitosamente")
    end

    it "sets the business as independent" do
      post admin_independent_professionals_create_path, params: {
        independent_professional: {
          name: "Carlos Barber",
          email: "carlos3@example.com",
          phone: "3001234567",
          business_type: "barbershop"
        }
      }
      business = Business.last
      expect(business.independent).to be true
    end

    context "with invalid data" do
      it "redirects with error for duplicate email" do
        create(:user, email: "existing@example.com")
        post admin_independent_professionals_create_path, params: {
          independent_professional: {
            name: "Duplicate User",
            email: "existing@example.com",
            phone: "3001234567"
          }
        }
        expect(response).to redirect_to(admin_independent_professionals_path)
        expect(flash[:alert]).to include("Error")
      end
    end
  end
end
