# frozen_string_literal: true

# Rate limiting configuration for Agendity API.
# Protects against brute force and abuse.

class Rack::Attack
  # Throttle login attempts: 5 requests per 20 seconds per IP
  throttle("auth/login", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  # Throttle public booking: 10 requests per minute per IP
  throttle("public/booking", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.match?(%r{/api/v1/public/businesses/.+/book}) && req.post?
  end

  # Throttle general API: 300 requests per 5 minutes per IP
  throttle("api/general", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Return rate limit headers and JSON response
  self.throttled_responder = lambda do |matched, period, limit, count|
    now = Time.now.utc
    retry_after = (period - (now.to_i % period)).to_s

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after
    }

    body = {
      error: "Rate limit exceeded. Try again in #{retry_after} seconds."
    }.to_json

    [429, headers, [body]]
  end
end
