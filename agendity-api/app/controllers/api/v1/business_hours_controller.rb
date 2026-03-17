# frozen_string_literal: true

module Api
  module V1
    # Manages business hours (singular resource) for the current business.
    # SRP: Only handles HTTP concerns for business hours configuration.
    class BusinessHoursController < BaseController
      # GET /api/v1/business_hours
      def show
        hours = current_business.business_hours.order(:day_of_week)
        render_success(BusinessHourSerializer.render_as_hash(hours))
      end

      # PATCH /api/v1/business_hours
      def update
        result = Businesses::UpdateBusinessHoursService.call(business: current_business, params: hours_params)

        if result.success?
          render_success(BusinessHourSerializer.render_as_hash(result.data))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      private

      def hours_params
        params.permit(business_hours: %i[day_of_week open_time close_time closed])
      end
    end
  end
end
