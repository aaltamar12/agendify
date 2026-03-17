# frozen_string_literal: true

module Businesses
  # Updates a business profile with the given parameters.
  class UpdateService < BaseService
    def initialize(business:, params:)
      @business = business
      @params   = params
    end

    def call
      if @business.update(@params)
        success(@business)
      else
        failure("Could not update business", details: @business.errors.full_messages)
      end
    end
  end
end
