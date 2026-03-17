# frozen_string_literal: true

# Base controller for all API endpoints.
# Uses ActionController::API for a lightweight stack without sessions,
# cookies, flash, or CSRF protection — ideal for JSON API responses.
class ApiController < ActionController::API
end
