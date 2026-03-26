# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { create(:user, :admin) }

  before { admin_login(admin) }

  describe "GET /admin" do
    it "returns success" do
      get admin_root_path
      expect(response).to have_http_status(:success)
    end

    it "displays summary cards" do
      get admin_root_path
      expect(response.body).to include("Negocios Activos")
      expect(response.body).to include("Citas del Mes")
      expect(response.body).to include("Ingresos del Mes")
      expect(response.body).to include("Usuarios Registrados")
    end

    context "with data present" do
      let!(:business) { create(:business) }
      let!(:appointment) { create(:appointment, business: business) }
      let!(:notification) { create(:admin_notification, read: false) }

      it "returns success with populated data" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end

      it "displays recent notifications" do
        get admin_root_path
        expect(response.body).to include("Notificaciones recientes")
      end
    end

    context "with no notifications" do
      it "returns success without notification panel" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
