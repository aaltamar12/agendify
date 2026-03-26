# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::JobConfigs", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:job_config) { create(:job_config) }

  before { admin_login(admin) }

  describe "GET /admin/job_configs" do
    it "returns success" do
      get admin_job_configs_path
      expect(response).to have_http_status(:success)
    end

    it "displays the job config" do
      get admin_job_configs_path
      expect(response.body).to include(job_config.name)
    end
  end

  describe "GET /admin/job_configs/:id" do
    it "returns success" do
      get admin_job_config_path(job_config)
      expect(response).to have_http_status(:success)
    end

    it "displays job config details" do
      get admin_job_config_path(job_config)
      expect(response.body).to include(job_config.name)
      expect(response.body).to include(job_config.job_class)
    end
  end

  describe "GET /admin/job_configs/:id/edit" do
    it "returns success" do
      get edit_admin_job_config_path(job_config)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/job_configs/:id" do
    it "updates the job config" do
      patch admin_job_config_path(job_config), params: {
        job_config: { enabled: false }
      }
      expect(job_config.reload.enabled).to be false
    end
  end

  describe "POST /admin/job_configs/:id/run" do
    context "with a valid job class" do
      before do
        stub_const("TestJob1", Class.new(ApplicationJob) {
          def perform; end
        })
        job_config.update!(job_class: "TestJob1")
      end

      it "enqueues the job and redirects" do
        post run_admin_job_config_path(job_config)
        expect(response).to redirect_to(admin_job_config_path(job_config))
        expect(flash[:notice]).to include("ejecutado")
      end
    end

    context "with an invalid job class" do
      before { job_config.update!(job_class: "NonExistentJob") }

      it "redirects with an error" do
        post run_admin_job_config_path(job_config)
        expect(response).to redirect_to(admin_job_config_path(job_config))
        expect(flash[:alert]).to include("Error")
      end
    end
  end
end
