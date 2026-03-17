# frozen_string_literal: true

module Businesses
  # Updates a business with onboarding data and marks the
  # onboarding as completed.
  class CompleteOnboardingService < BaseService
    PERMITTED_ATTRS = %i[
      name business_type address city country phone
      description logo_url cover_url
    ].freeze

    def initialize(business:, params:)
      @business = business
      @params   = params.slice(*PERMITTED_ATTRS)
    end

    def call
      @params[:onboarding_completed] = true

      if @business.update(@params)
        success(@business)
      else
        failure("Could not complete onboarding", details: @business.errors.full_messages)
      end
    end
  end
end
