# frozen_string_literal: true

module AdminHelpers
  def admin_login(admin)
    post admin_create_session_path, params: { email: admin.email, password: "password123" }
  end
end

RSpec.configure do |config|
  config.include AdminHelpers, type: :request
end
