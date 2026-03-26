# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  # ApplicationController is the base for ActiveAdmin (non-API).
  # We test its private methods used by ActiveAdmin session auth.

  controller do
    skip_forgery_protection

    def index
      authenticate_admin!
      head :ok unless performed?
    end
  end

  describe "#authenticate_admin!" do
    it "redirects non-admin users" do
      regular_user = create(:user, role: :owner)
      session[:admin_user_id] = regular_user.id

      get :index

      expect(response).to redirect_to(admin_login_path)
    end

    it "redirects when no user in session" do
      get :index

      expect(response).to redirect_to(admin_login_path)
    end

    it "allows admin users" do
      admin = create(:user, :admin)
      session[:admin_user_id] = admin.id

      get :index

      expect(response).to have_http_status(:ok)
    end
  end

  describe "#current_admin_user" do
    it "returns admin user from session" do
      admin = create(:user, :admin)
      session[:admin_user_id] = admin.id

      get :index # triggers request to set up controller

      expect(controller.send(:current_admin_user)).to eq(admin)
    end

    it "returns nil when session is empty" do
      get :index

      expect(controller.send(:current_admin_user)).to be_nil
    end

    it "returns nil when user is not admin" do
      regular_user = create(:user, role: :owner)
      session[:admin_user_id] = regular_user.id

      get :index

      expect(controller.send(:current_admin_user)).to be_nil
    end

    it "returns nil when user does not exist" do
      session[:admin_user_id] = 999_999

      get :index

      expect(controller.send(:current_admin_user)).to be_nil
    end
  end
end
