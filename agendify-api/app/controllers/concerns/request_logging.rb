# frozen_string_literal: true

# Concern to automatically log every API request with timing, params,
# error traces, and resource tracking for appointment lifecycle tracing.
#
# Include in BaseController to capture all API requests.
# Uses around_action to measure duration and capture errors.
module RequestLogging
  extend ActiveSupport::Concern

  included do
    around_action :log_request
  end

  private

  def log_request
    @_request_start_time = Time.current
    @_request_id = SecureRandom.uuid

    yield
  rescue => error
    @_request_error = error
    raise
  ensure
    save_request_log
  end

  def save_request_log
    duration = (((Time.current - @_request_start_time) * 1000).round(2) if @_request_start_time)

    log_entry = {
      business_id: resolve_business_id,
      method: request.method,
      path: request.path.truncate(255),
      controller_action: "#{controller_name}##{action_name}",
      status_code: @_request_error ? 500 : response.status,
      duration_ms: duration,
      ip_address: request.remote_ip,
      user_agent: request.user_agent&.truncate(255),
      request_params: filtered_request_params,
      request_id: @_request_id
    }

    if @_request_error
      log_entry[:error_message] = @_request_error.message.truncate(1000)
      log_entry[:error_backtrace] = @_request_error.backtrace&.first(15)&.join("\n")
    end

    # Capture resource info from instance variables set by controllers
    if (resource_info = detect_resource)
      log_entry[:resource_type] = resource_info[:type]
      log_entry[:resource_id] = resource_info[:id]
    end

    RequestLog.create!(log_entry)
  rescue => log_error
    Rails.logger.error("[RequestLog] Failed to save: #{log_error.message}")
  end

  # Resolve business from various sources (authenticated user, public endpoint, etc.)
  def resolve_business_id
    if defined?(@current_business) && @current_business
      @current_business.id
    elsif defined?(@current_user) && @current_user
      @current_user.business&.id
    end
  end

  # Detect the primary resource affected by this request
  def detect_resource
    if instance_variable_defined?(:@appointment) && @appointment&.id
      { type: "Appointment", id: @appointment.id }
    elsif instance_variable_defined?(:@payment) && @payment&.id
      { type: "Payment", id: @payment.id }
    elsif instance_variable_defined?(:@service) && @service&.id
      { type: "Service", id: @service.id }
    elsif instance_variable_defined?(:@employee) && @employee&.id
      { type: "Employee", id: @employee.id }
    elsif instance_variable_defined?(:@customer) && @customer&.id
      { type: "Customer", id: @customer.id }
    end
  end

  # Filter sensitive params before logging
  def filtered_request_params
    params.to_unsafe_h
          .except("controller", "action", "password", "password_confirmation",
                  "token", "refresh_token", "proof", "proof_image_url")
          .deep_transform_values { |v| v.is_a?(String) ? v.truncate(500) : v }
  rescue => e
    Rails.logger.error("[RequestLog] Failed to filter params: #{e.message}")
    {}
  end
end
