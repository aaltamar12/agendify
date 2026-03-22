# frozen_string_literal: true

module Employees
  # Calculates an employee's performance score based on customer ratings and punctuality.
  # Only factors the employee can control — excludes completion rate (client cancellations
  # would unfairly penalize the employee).
  class ScoreService < BaseService
    def initialize(employee:)
      @employee = employee
    end

    def call
      success({
        overall: calculate_overall,
        rating_avg: average_rating,
        on_time_rate: on_time_rate,
        completed_appointments: completed_count,
        total_revenue: total_revenue
      })
    end

    private

    def average_rating
      Review.joins(:appointment)
            .where(appointments: { employee_id: @employee.id })
            .average(:rating)&.round(1).to_f || 0
    end

    def completed_count
      @employee.appointments.where(status: :completed).count
    end

    def on_time_rate
      checked_in = @employee.appointments.where(status: [:checked_in, :completed]).where.not(checked_in_at: nil)
      return 0 if checked_in.count.zero?
      on_time = checked_in.where("checked_in_at <= (appointment_date + start_time + interval '5 minutes')").count
      ((on_time.to_f / checked_in.count) * 100).round(1)
    end

    def total_revenue
      @employee.appointments.where(status: :completed).sum(:price).to_f
    end

    def calculate_overall
      # Rating (60%) + Punctuality (40%)
      # Only things the employee controls
      rating_score = average_rating > 0 ? (average_rating / 5.0) * 100 : 50
      punctuality = on_time_rate > 0 ? on_time_rate : 50
      (rating_score * 0.6 + punctuality * 0.4).round(0)
    end
  end
end
