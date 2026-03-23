# frozen_string_literal: true

# Abstract base class for all service objects.
# Provides the .call class method and success/failure helpers
# so that every service follows a uniform interface.
class BaseService
  def self.call(...)
    new(...).call
  end

  private

  def success(data = nil)
    ServiceResult.new(success: true, data: data)
  end

  def failure(error, code: nil, details: nil)
    ServiceResult.new(success: false, error: error, error_code: code, details: details)
  end
end
