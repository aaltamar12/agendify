# frozen_string_literal: true

# CORS configuration for Agendity API.
# Allows the frontend app to make cross-origin requests.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:3000", ENV.fetch("AGENDITY_WEB_URL", "")

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization],
      max_age: 600
  end
end
