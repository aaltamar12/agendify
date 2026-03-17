# frozen_string_literal: true

module Businesses
  # Bulk-updates or creates business hours for each day of the week.
  class UpdateBusinessHoursService < BaseService
    def initialize(business:, params:)
      @business = business
      @params   = params
    end

    def call
      hours_data = @params[:business_hours]
      return failure("No business hours provided") if hours_data.blank?

      ActiveRecord::Base.transaction do
        hours_data.each do |day_params|
          hour = @business.business_hours.find_or_initialize_by(day_of_week: day_params[:day_of_week])
          unless hour.update(day_params.permit(:open_time, :close_time, :closed))
            return failure("Could not update hours for day #{day_params[:day_of_week]}", details: hour.errors.full_messages)
          end
        end
      end

      success(@business.business_hours.order(:day_of_week))
    end
  end
end
