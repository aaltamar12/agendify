# frozen_string_literal: true

module Reports
  # Returns high-level KPIs for a business dashboard:
  # total revenue, appointment count, customer count, and average rating.
  class SummaryService < BaseService
    def initialize(business:)
      @business = business
    end

    def call
      completed = @business.appointments.completed

      summary = {
        total_revenue:      completed.sum(:price).to_f,
        total_appointments: @business.appointments.count,
        total_customers:    @business.customers.count,
        avg_rating:         @business.rating_average.to_f
      }

      success(summary)
    end
  end
end
