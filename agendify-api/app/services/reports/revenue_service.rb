# frozen_string_literal: true

module Reports
  # Groups completed-appointment revenue by date for a given period
  # (week, month, or year).  Returns an array of { date:, revenue: } hashes.
  class RevenueService < BaseService
    PERIODS = {
      "week"  => 7.days,
      "month" => 30.days,
      "year"  => 365.days
    }.freeze

    def initialize(business:, period: "month")
      @business = business
      @period   = period
    end

    def call
      duration = PERIODS[@period]
      return failure("Invalid period. Use: week, month, or year") unless duration

      start_date = duration.ago.to_date

      revenue_data = @business.appointments
        .completed
        .where("appointment_date >= ?", start_date)
        .group(:appointment_date)
        .sum(:price)
        .map { |date, amount| { date: date, revenue: amount.to_f } }
        .sort_by { |entry| entry[:date] }

      success(revenue_data)
    end
  end
end
