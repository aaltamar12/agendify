# frozen_string_literal: true

module Employees
  # Calculates an employee's performance score based on ratings, completion rate, and punctuality.
  class ScoreService < BaseService
    def initialize(employee:)
      @employee = employee
    end

    def call
      success({
        overall: calculate_overall,
        rating_avg: average_rating,
        completed_appointments: completed_count,
        completion_rate: completion_rate,
        on_time_rate: on_time_rate,
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

    def completion_rate
      total = @employee.appointments.where.not(status: :cancelled).count
      return 0 if total.zero?
      ((completed_count.to_f / total) * 100).round(1)
    end

    def on_time_rate
      checked_in = @employee.appointments.where(status: [:checked_in, :completed]).where.not(checked_in_at: nil)
      return 0 if checked_in.count.zero?
      on_time = checked_in.where("checked_in_at <= start_time + interval '5 minutes'").count
      ((on_time.to_f / checked_in.count) * 100).round(1)
    end

    def total_revenue
      @employee.appointments.where(status: :completed).sum(:price).to_f
    end

    def calculate_overall
      weights = { rating: 0.4, completion: 0.3, on_time: 0.3 }
      rating_score = average_rating > 0 ? (average_rating / 5.0) * 100 : 50
      (rating_score * weights[:rating] +
       completion_rate * weights[:completion] +
       on_time_rate * weights[:on_time]).round(0)
    end
  end
end
