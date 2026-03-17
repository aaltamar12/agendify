# frozen_string_literal: true

# Value object that wraps the outcome of a service call.
# Every service returns a ServiceResult so controllers can
# branch on success?/failure? without rescuing exceptions.
class ServiceResult
  attr_reader :data, :error, :details

  def initialize(success:, data: nil, error: nil, details: nil)
    @success = success
    @data    = data
    @error   = error
    @details = details
  end

  def success? = @success
  def failure? = !@success
end
