# frozen_string_literal: true

module Intelligence
  # Calculates progress toward business financial goals.
  # Returns progress percentage, remaining amount, and actionable suggestions.
  # Currently uses rules-based logic — designed to be upgraded to Claude API later.
  class GoalProgressService < BaseService
    def initialize(business:)
      @business = business
    end

    def call
      goals = @business.business_goals.active
      return success([]) if goals.empty?

      results = goals.map { |goal| evaluate_goal(goal) }
      success(results)
    end

    private

    def evaluate_goal(goal)
      case goal.goal_type
      when "break_even"
        evaluate_break_even(goal)
      when "monthly_sales"
        evaluate_monthly_sales(goal)
      when "daily_average"
        evaluate_daily_average(goal)
      else
        evaluate_custom(goal)
      end
    end

    def evaluate_break_even(goal)
      fixed_costs = goal.fixed_costs || 0
      current_revenue = monthly_revenue
      remaining = [fixed_costs - current_revenue, 0].max
      progress = fixed_costs.positive? ? [(current_revenue / fixed_costs * 100), 100].min.round(1) : 0

      suggestion = if progress >= 100
        "Has superado tu punto de equilibrio. Ganancia neta hasta ahora: $#{(current_revenue - fixed_costs).round(0).to_fs(:delimited)}"
      elsif progress >= 70
        "Vas al #{progress}% de tu punto de equilibrio. Necesitas $#{remaining.round(0).to_fs(:delimited)} mas."
      else
        days_left = days_remaining_in_month
        daily_needed = days_left.positive? ? (remaining / days_left).round(0) : remaining
        "Llevas #{progress}% del punto de equilibrio. Necesitas $#{daily_needed.to_fs(:delimited)} diarios los proximos #{days_left} dias."
      end

      build_result(goal, current_revenue, progress, remaining, suggestion)
    end

    def evaluate_monthly_sales(goal)
      current = monthly_revenue
      target = goal.target_value
      progress = target.positive? ? [(current / target * 100), 100].min.round(1) : 0
      remaining = [target - current, 0].max

      suggestion = if progress >= 100
        "Meta cumplida! Superaste tu objetivo por $#{(current - target).round(0).to_fs(:delimited)}."
      elsif progress >= 80
        "Excelente! Vas al #{progress}%. Solo faltan $#{remaining.round(0).to_fs(:delimited)}."
      elsif progress >= 50
        citas_needed = avg_appointment_value.positive? ? (remaining / avg_appointment_value).ceil : 0
        "Vas al #{progress}%. Necesitas aproximadamente #{citas_needed} citas mas para cumplir."
      else
        days_left = days_remaining_in_month
        daily_needed = days_left.positive? ? (remaining / days_left).round(0) : remaining
        "Llevas #{progress}%. Tu promedio diario deberia ser $#{daily_needed.to_fs(:delimited)} para alcanzar la meta."
      end

      build_result(goal, current, progress, remaining, suggestion)
    end

    def evaluate_daily_average(goal)
      days_elapsed = Date.current.day
      current_total = monthly_revenue
      daily_avg = days_elapsed.positive? ? (current_total / days_elapsed).round(0) : 0
      target = goal.target_value
      progress = target.positive? ? [(daily_avg.to_f / target * 100), 150].min.round(1) : 0

      suggestion = if daily_avg >= target
        "Tu promedio diario ($#{daily_avg.to_fs(:delimited)}) supera tu objetivo de $#{target.round(0).to_fs(:delimited)}."
      else
        diff = target - daily_avg
        "Tu promedio diario es $#{daily_avg.to_fs(:delimited)}. Necesitas $#{diff.round(0).to_fs(:delimited)} mas por dia."
      end

      build_result(goal, daily_avg, progress, [target - daily_avg, 0].max, suggestion)
    end

    def evaluate_custom(goal)
      current = monthly_revenue
      target = goal.target_value
      progress = target.positive? ? [(current / target * 100), 100].min.round(1) : 0
      remaining = [target - current, 0].max

      build_result(goal, current, progress, remaining, "Progreso: #{progress}% de tu meta.")
    end

    def build_result(goal, current_value, progress, remaining, suggestion)
      status = if progress >= 100
        "achieved"
      elsif progress >= 70
        "on_track"
      elsif progress >= 40
        "behind"
      else
        "at_risk"
      end

      {
        id: goal.id,
        goal_type: goal.goal_type,
        name: goal.name || goal.goal_type.humanize,
        target_value: goal.target_value.to_f,
        current_value: current_value.to_f,
        progress: progress,
        remaining: remaining.to_f,
        status: status,
        suggestion: suggestion
      }
    end

    def monthly_revenue
      @monthly_revenue ||= @business.appointments
        .where(status: [:checked_in, :completed])
        .where("appointment_date >= ?", Date.current.beginning_of_month)
        .sum(:price).to_f
    end

    def avg_appointment_value
      @avg_appointment_value ||= begin
        completed = @business.appointments.where(status: [:checked_in, :completed])
          .where("appointment_date >= ?", 3.months.ago)
        completed.any? ? completed.average(:price).to_f : 0
      end
    end

    def days_remaining_in_month
      (Date.current.end_of_month - Date.current).to_i
    end
  end
end
