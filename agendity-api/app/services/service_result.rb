# frozen_string_literal: true

# Value object that wraps the outcome of a service call.
# Every service returns a ServiceResult so controllers can
# branch on success?/failure? without rescuing exceptions.
class ServiceResult
  attr_reader :data, :error, :error_code, :details

  def initialize(success:, data: nil, error: nil, error_code: nil, details: nil)
    @success    = success
    @data       = data
    @error      = error
    @error_code = error_code
    @details    = details
  end

  def success? = @success
  def failure? = !@success
end
