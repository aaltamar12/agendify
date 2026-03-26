# frozen_string_literal: true

# Helper to sign in as admin for ActiveAdmin request specs.
# Admin auth uses session-based login via Admin::SessionsController.
module AdminLoginHelper
  def admin_login(admin_user)
    post "/admin/login", params: { email: admin_user.email, password: "password123" }
  end
end

RSpec.configure do |config|
  config.include AdminLoginHelper, type: :request
end
