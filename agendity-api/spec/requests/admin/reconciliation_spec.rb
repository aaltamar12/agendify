# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe "Admin::Reconciliacion", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:business) { create(:business) }

  before { admin_login(admin) }

  describe "GET /admin/reconciliacion" do
    it "returns success and shows business list" do
      get admin_reconciliacion_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Seleccionar negocio para reconciliar")
    end

    it "displays active businesses" do
      get admin_reconciliacion_path
      expect(response.body).to include(business.name)
    end

    context "with business_id param" do
      before do
        allow(CashRegister::ReconciliationService).to receive(:call).and_return(
          OpenStruct.new(data: [])
        )
        allow(Credits::ReconciliationService).to receive(:call).and_return(
          OpenStruct.new(data: [])
        )
      end

      it "returns success and shows reconciliation for that business" do
        get admin_reconciliacion_path(business_id: business.slug)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(business.name)
      end

      it "shows OK message when no discrepancies found" do
        get admin_reconciliacion_path(business_id: business.slug)
        expect(response.body).to include("Todos los saldos de empleados son consistentes")
        expect(response.body).to include("Todos los saldos de creditos son consistentes")
      end
    end
  end
end
